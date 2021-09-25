variable "config" {
  type = object({
    name = string
    type = string
  })
}

variable service_artifacts_bucket {}