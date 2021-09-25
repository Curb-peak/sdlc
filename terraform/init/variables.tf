

variable SECRET_GITHUB_TOKEN {
  validation {
    condition     = var.SECRET_GITHUB_TOKEN != ""
    error_message = "The Environment variable TF_VAR_SECRET_GITHUB_TOKEN needs to be set to a valid github personal access token."
  }
}

variable route53_root_host_zone {
  default = "stokedconsulting.com"
}

variable app_name {
  default = "sdlc"
}