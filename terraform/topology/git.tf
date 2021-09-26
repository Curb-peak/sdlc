data aws_secretsmanager_secret github_token_stoked_consulting {
  name = "github-token-stoked-consulting"
}

data aws_secretsmanager_secret_version github_token_stoked_consulting {
  secret_id = data.aws_secretsmanager_secret.github_token_stoked_consulting.id
}

provider "github" {
  token = data.aws_secretsmanager_secret_version.github_token_stoked_consulting.secret_string
  owner = var.github["organization"]
}

resource aws_codebuild_source_credential github_connection {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = data.aws_secretsmanager_secret_version.github_token_stoked_consulting.secret_string
}