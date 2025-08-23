variable "k8s_version" {
  default = "1.31"
}

variable "enable_private" {
  default = false
}

variable "public_az" {
  type        = string
  description = "Change this to a letter a-f only if you encounter an error during setup"
  default     = "a"
}

variable "private_az" {
  type        = string
  description = "Change this to a letter a-f only if you encounter an error during setup"
  default     = "b"
}

variable "aws_profile" {
  type        = string
  description = "AWS profile to use for authentication"
  default     = "manager"
}

variable "ec2_public_key" {
  description = "Public key for EC2 instances"
  type        = string
  sensitive   = true
}