/*
export PKR_VAR_VERSION=0.0.18
export PKR_VAR_SERVICE=conwell
export PKR_VAR_Environment=staging
export PKR_VAR_COMMIT=42dd974877f8ed19cc98f51d56461a5f97a3921b
export PKR_VAR_BRANCH=main
*/
variable "VERSION" {
  type =  string
}

variable "Service" {
  type =  string
}

variable "Environment" {
  type =  string
  default = "dev"
}

variable "BRANCH" {
  type =  string
}

variable "COMMIT" {
  type =  string
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "${var.Environment}-${var.Service}-${var.BRANCH}-${var.VERSION}"
  instance_type = "t4g.micro"
  region        = "us-east-1"
  skip_region_validation = true

  source_ami_filter {
    filters = {
      "name" = "service-base"
    }
    most_recent = true
    owners      = [var.ACCOUNT_ID]
  }

  tags = {
    VERSION = "${var.VERSION}"
    Service = "${var.Service}"
    Environment = "${var.Environment}"
    BRANCH = "${var.BRANCH}"
    Name = "${var.Environment}-${var.Service}-v${var.VERSION}"
    Commit = "${var.COMMIT}"
  }

  shutdown_behavior = "terminate"
  force_deregister =  "true"
  force_delete_snapshot = "true"
  ssh_username = "ubuntu"
}

build {
  name    = "peak-ami-builder"

  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "shell" {
    inline = [
      "mkdir ~/${var.Service}"
    ]
  }

  provisioner "file" {
    source = "../"
    destination = "~/${var.Service}/"
  }

  provisioner "shell" {
    inline = [
      "echo 'cd service dir'",
      "cd ${var.Service}",
      "echo 'run npm'",
      "npm i --loglevel=error",
      "echo 'ls current directory'",
      "echo $(pwd)",
      "ls -la",
      "echo 'tsconfig build'",
      "[ -f \"./tsconfig.json\" ] && npm run build",
      "echo 'create symbolic link'",
      "sudo ln -s ~/${var.Service} /usr/sbin/${var.Service}",
      "echo 'copy service'",
      "sudo cp ~/${var.Service}/${var.SERVICE}.service /lib/systemd/system/${var.SERVICE}.service",
      "echo 'daemon-reload'",
      "sudo systemctl daemon-reload",
      "echo 'systemctl enable'",
      "sudo systemctl enable ${var.SERVICE}.service",
      "echo 'service start'",
      "sudo service ${var.SERVICE} start",
      "echo 'great success'",
    ]
  }
}
