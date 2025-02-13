variable "postgres_user" {
  type        = string
  description = "postgres user"
}

variable "postgres_password" {
  type        = string
  description = "postgres_password"
}

variable "s3_flyway_bucket" {
  type        = string
  description = "S3 flyway bucket"
}

variable "s3_key" {
  type        = string
  description = "S3 key"
}

variable "aws_access_key_id" {
  description = "aws access key id"
}

variable "aws_secret_access_key" {
  description = "aws secret access key"
}

variable "aws_default_region" {
  description = "aws default region"
}