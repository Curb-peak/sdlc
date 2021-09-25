resource aws_route53_zone route53_env_zone {
  name = "${terraform.workspace}.${var.app_name}.${var.route53_root_host_zone}"
  count = terraform.workspace != "prod" ? 1 : 0
}

data aws_route53_zone route53_prod_zone {
  name = "${var.app_name}.${var.route53_root_host_zone}"
  count = terraform.workspace == "prod" ? 1 : 0
}

locals{
    environment_route = terraform.workspace != "prod" ? aws_route53_zone.route53_env_zone[0].name : aws_route53_zone.route53_env_zone[0].name
}

resource aws_acm_certificate service {
  domain_name = local.environment_route
  subject_alternative_names = ["*.${local.environment_route}"]
  validation_method = "DNS"
  tags = {
    Name = local.environment_route
    terraform = "true"
  }
}
