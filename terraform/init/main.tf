provider aws {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = var.app_name
      Service = "infrastructure"
    }
  }
}

locals {
  env_lock = "${var.app_name}-terraform-lock"
}

resource aws_s3_bucket terraform_state {
  bucket = local.env_lock

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource aws_dynamodb_table terraform_lock {
  name           = local.env_lock
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource aws_secretsmanager_secret github_token_stoked_consulting {
  name = "github-token-stoked-consulting"
}

resource aws_secretsmanager_secret_version github_token {
  secret_id     = aws_secretsmanager_secret.github_token_stoked_consulting.id
  secret_string = var.SECRET_GITHUB_TOKEN
}

data aws_route53_zone root_zone {
  name         = "${var.route53_root_host_zone}."
}

resource aws_route53_zone route53_sub_zone {
  name = "${var.app_name}.${var.route53_root_host_zone}"
}

resource "aws_key_pair" "app_admin" {
  key_name = "sdlc_app_admin"
  public_key = file("~/.ssh/sdlc.pub")
}