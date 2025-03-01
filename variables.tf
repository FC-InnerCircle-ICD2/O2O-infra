variable "postgres_user" {
  type        = string
  description = "postgres user"
}

variable "postgres_password" {
  type        = string
  description = "postgres_password"
}

variable "s3_backend_bucket" {
  type        = string
  description = "S3 backend bucket"
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

variable "s3_frontend_bucket" {
  type        = string
  description = "S3 frontend bucket"
}

variable "gf_security_admin_user" {
  type        = string
  description = "gf security admin user"
}

variable "gf_security_admin_password" {
  type        = string
  description = "gf security admin password"
}

variable "grafana_root_url" {
  type        = string
  description = "grafana root url"
}