data aws_caller_identity current {}

data aws_ami latest {

  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}
/*
data "aws_ami" "latest" {
  most_recent      = true
  owners      = [data.aws_caller_identity.current.account_id]

  filter {
    name = "tag:Environment"
    values = [var.config.env, "dev"]
  }

  filter {
    name = "tag:Service"
    values = [var.config.name]
  }
}
*/
# Security Groups and IAM
module "ec2_service_alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.0.0"

  name        = "${var.config.env}-${var.config.name}-alb-sg"
  description = "Security group for ${var.config.name} with ALB"
  vpc_id      = var.config.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp", "all-icmp"]
  egress_rules        = ["all-all"]
  tags = {
    Key                  = "Service"
    propagate_at_launch  = "true"
    Value                = var.config.name
  }
}

module "ec2_service_asg_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.0.0"

  name        = "${var.config.env}-${var.config.name}-asg-sg"
  description = "Security group for ${var.config.name} with ALB"
  vpc_id      = var.config.vpc.vpc_id

  egress_rules        = ["all-all"]

  ingress_with_source_security_group_id = [
    {
      from_port                = var.config.port
      to_port                  = var.config.port
      protocol                 = "tcp"
      description              = "Node"
      source_security_group_id = module.ec2_service_alb_sg.security_group_id
    }
  ]
  tags = {
    Service = var.config.name
  }
}


resource aws_launch_template service_launch_template {
  name = "${var.config.env}-${var.config.name}-lt"

  block_device_mappings {
    device_name = "/dev/sda1"
    no_device   = 0
    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = 8
      volume_type           = "gp2"
    }
  }

  ebs_optimized = true

  image_id = data.aws_ami.latest.id
  instance_type= var.config.type

  key_name = "${var.config.env}-emilie-curb-v2"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 32
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination = true
    description           = "eth0"
    device_index          = 0
    security_groups       = [module.ec2_service_asg_sg.security_group_id, var.config.whitelist_sg]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.config.env}-${var.config.name}-ubuntu"
      Service = var.config.name
    }
  }

  tags = {
    Name = "${var.config.env}-${var.config.name}-lt"
    Service = var.config.name
  }
}


#######################################
# Autoscaling group and load balancer

module "ec2_service_asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "4.4.0"

  # Autoscaling group
  name = "${var.config.env}-${var.config.name}-asg"
  propagate_name = false

  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"

  use_lt    = true
  create_lt = false

  vpc_zone_identifier       = var.config.vpc.public_subnets
  associate_public_ip_address = true
  key_name = "${var.config.env}-emilie-curb-v2"
  default_cooldown = 30
  health_check_grace_period = 30

  initial_lifecycle_hooks = [
    {
      name                  = "ExampleStartupLifeCycleHook"
      default_result        = "CONTINUE"
      heartbeat_timeout     = 30
      lifecycle_transition  = "autoscaling:EC2_INSTANCE_LAUNCHING"
      notification_metadata = jsonencode({ "hello" = "world" })
    },
    {
      name                  = "ExampleTerminationLifeCycleHook"
      default_result        = "CONTINUE"
      heartbeat_timeout     = 30
      lifecycle_transition  = "autoscaling:EC2_INSTANCE_TERMINATING"
      notification_metadata = jsonencode({ "goodbye" = "world" })
    }
  ]

  launch_template = aws_launch_template.service_launch_template.name
  # Launch template
  lt_version             = "$Latest"

  enable_monitoring = true
  target_group_arns = module.ec2_service_alb_ec2.target_group_arns

  tag_specifications = [
    {
      resource_type = "instance"
      tags = {
        Name = "${var.config.env}-${var.config.name}-ubuntu"
        Service = var.config.name
      }
    },
    {
      resource_type = "volume"
      tags = {
        Name = "${var.config.env}-${var.config.name}-ebs"
        Service = var.config.name
      }
    }
  ]

  tags = [{
    key                  = "Service"
    propagate_at_launch  = true
    value                = var.config.name
  },{
    key                  = "Environment"
    propagate_at_launch  = true
    value                = var.config.env
  }]
}

module "ec2_service_alb_ec2" {
  source  = "terraform-aws-modules/alb/aws"
  version = "6.0.0"

  name = "${var.config.env}-${var.config.name}-alb"

  load_balancer_type = "application"

  vpc_id             = var.config.vpc.vpc_id
  subnets            = var.config.vpc.public_subnets
  security_groups    = [module.ec2_service_alb_sg.security_group_id]

#  access_logs = {
#    bucket = "${s3_bucket.alb_logs}-${var.config.name}"
#  }

  target_groups = [
    {
      name_prefix      = "S-cr"
      backend_protocol = "HTTP"
      backend_port     = var.config.port
      target_type      = "instance"
    }
  ]

  https_listeners = [
    {
      port                 = 443
      protocol             = "HTTPS"
      certificate_arn      = var.config.acm
      target_group_index   = 0
    }
  ]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]

  tags = {
    Service = var.config.name
    Environment = var.config.env
  }
}

resource "aws_route53_record" "service" {
  zone_id = var.config.zone.id
  name = var.config.name
  type = "CNAME"
  ttl = "300"
  records = [module.ec2_service_alb_ec2.lb_dns_name]
}
