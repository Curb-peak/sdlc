module "ec2_service" {
  source  = "./modules/ec2_service"
  for_each = var.ec2_services

  config = merge({
    name = each.key
    port = each.value.port
    env = var.env
    vpc = module.vpc
    acm = aws_acm_certificate.service.arn
    whitelist_sg = module.whitelist_sg.security_group_id
    zone = terraform.workspace == "prod" ? data.aws_route53_zone.route53_prod_zone[0] : aws_route53_zone.route53_env_zone[0]
    type = each.value.instance_type != null ? each.value.instance_type : var.ec2_default_instance_type
  })
}
