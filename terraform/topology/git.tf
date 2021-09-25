resource aws_secretsmanager_secret github_token_stoked_consulting {
  name = "github-token-stoked-consulting"
}

resource aws_secretsmanager_secret_version github_token {
  secret_id     = aws_secretsmanager_secret.github_token_stoked_consulting.id
  secret_string = var.SECRET_GITHUB_TOKEN
}