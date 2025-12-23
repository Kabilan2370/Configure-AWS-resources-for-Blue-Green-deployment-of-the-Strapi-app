variable "aws_region" {
  default = "eu-north-1"
}

variable "image_uri" {
  description = "ECR image URI with tag"
  type        = string
  default     = ""
}

