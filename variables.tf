variable "aws_region" {
  description = "AWS region"
  default     = "eu-central-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.large"
}

variable "ami_id" {
  description = "Ubuntu 22.04 AMI ID"
  default     = "ami-0fc5d935ebf8bc3bc"
}

variable "key_name" {
  description = "SSH key name in AWS"
  type        = string
}

variable "controller_count" {
  default = 3
}

variable "compute_count" {
  default = 3
}

variable "storage_count" {
  default = 3
}

variable "tf_state_bucket" {
  description = "Name of the S3 bucket for Terraform state"
  default     = "my-terraform-openstack-state"
}
