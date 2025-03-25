variable "HCP_CLIENT_ID" {
  type = string
  ephemeral = true
}

variable "HCP_CLIENT_SECRET" {
  type = string
  ephemeral = true
}

variable "vault_secrets_app" {
  type = string
}

variable "aws_region" {
  type        = string
}

variable "instance_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
}

variable "debian_ami" {
  description = "Debian 12 (20240717-1811)"
  type        = string
}

variable "debian_ami_default_user" {
  type        = string
}

variable "volume_device_name" {
  type = string
}

variable "instance_type" {
  description = "Instance type"
  type        = string
}

variable "instance_az" {
  description = "Instance Availability Zone"
  type        = string
}

variable "pgbackup_bucket_prefix" {
  description = "pgbackrest s3 Bucket"
  type        = string
}

variable "pgbackup_repo" {
  description = "pgbackrest stanza repo"
  type        = string
}

variable "app_domain_name" {
  type = string
}

variable "cf_zone_id" {
    type = string
}

variable "cf_account_id" {
    type = string
}

variable "ebs_vol_name" {
  type = string
}

variable "ssh_key_name" {
  type = string
}

variable "security_group_name" {
  type = string
}

variable "iam_bucket_user" {
  type = string
}

variable "HCP_ORG" {
  type = string
}

variable "HCP_WS" {
  type = string
}