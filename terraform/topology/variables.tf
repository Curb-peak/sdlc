variable "domain" {}
variable "env" {}
variable "vpc" {}

variable "region" {
  default = "us-east-1"
}

variable "disk_size" {
  default = 8
}

variable "github" {
  type = map
  default = {
      branch = "main"
      organization = "stoked-consulting"
  }
}

variable ec2_default_instance_type {
  default = "t4g.micro"
}

variable ec2_services {

  type = map(object({
    port = any
    instance_type = any
    type = string
  }))

  default = {
    iknowadamrodgers = {
      port = 15110
      instance_type = "t4g.micro"
      type = "ec2"
    }
  }
}


variable artifact_services {

  type = map(object({
    type = string
  }))

  default = {
    sdlc = {
      type = "artifact"
    }
  }
}

variable Environments {
  type = map(object({
    build_triggers: object({
      commit: list(string)
      auto: list(string)
    })
  }))
  default = {
    dev = {
      build_triggers = {
        commit = ["*"]
        auto   = ["main"]
      }
    }
    staging = {
      build_triggers = {
        commit = ["*"]
        auto = [""]
      }
    }
    prod = {
      build_triggers = {
        commit = [""]
        auto = [""]
      }
    }
  }
}

variable route53_root_host_zone {
  default = "stokedconsulting.com"
}

variable app_name {
  default = "sdlc"
}

variable SECRET_GITHUB_TOKEN {
  validation {
    condition     = var.SECRET_GITHUB_TOKEN != ""
    error_message = "The Environment variable TF_VAR_SECRET_GITHUB_TOKEN needs to be set to a valid github personal access token."
  }
}
