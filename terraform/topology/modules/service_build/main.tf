data aws_caller_identity current {}
data aws_region current {}

resource aws_iam_role codebuild_role {
  name = "${var.config.name}-cb_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource aws_iam_role_policy codebuild_role_policy {
  role = aws_iam_role.codebuild_role.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:*.${var.config.name}.*"
    },
    {
      "Effect": "Allow",
      "Action": [
          "secretsmanager:ListSecrets"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
          "s3:Get*",
          "s3:List*",
          "s3:PutObject*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": "ec2:CreateNetworkInterfacePermission",
      "Resource": "*"
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObjectVersion",
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::codepipeline-us-east-1-*"
    }
  ]
}
POLICY
}


resource aws_codebuild_project service_build {
  name        = "${var.config.name}-cb"
  description = "Codebuild for deploying ${var.config.name}"
  service_role  = aws_iam_role.codebuild_role.arn

  badge_enabled = true

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = "${var.service_artifacts_bucket}/services/${var.config.name}/cache"
  }

  concurrent_build_limit = 1

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0-21.04.23"
    type            = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "Service"
      value = var.config.name
    }

    environment_variable {
      name  = "ENVIRONMENT"
      value = "dev"
    }

    environment_variable {
      name  = "DEFAULT_BRANCH"
      value = "main"
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "${var.config.name}-cb"
      stream_name = "cloudbuild"
    }
    s3_logs {
      status   = "ENABLED"
      location = "${var.service_artifacts_bucket}/services/${var.config.name}/logs"
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/stokedconsulting/${var.config.name}.git"
    git_clone_depth = 1
    buildspec = "arn:aws:s3:::stokedconsulting.com-sdlc-artifacts/sdlc/buildspec-service-${var.config.type == "ec2" ? "instance" : "artifacts"}.yml"

    git_submodules_config {
      fetch_submodules = false
    }

    report_build_status = true
  }

  source_version = "main"
}

resource aws_codebuild_webhook service_build {
  project_name = aws_codebuild_project.service_build.name

  // add a filter group to trigger on commit pushes from branches listed in the auto: list(string)
  filter_group {
    filter {
      type = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type = "HEAD_REF"
      pattern = "^refs/heads/main$"
    }
  }

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "COMMIT_MESSAGE"
      pattern = "\\[(DEV)\\]"
    }
  }
}

