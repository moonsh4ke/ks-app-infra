output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}

output "elastic_ip" {
  description = "Elastic public ip"
  value = aws_eip.elastic_ip.public_ip
}

output "public_dns" {
  description = "Elastic public dns"
  value = aws_eip.elastic_ip.public_dns
}

/* output "rendered_policy" {
  value = data.aws_iam_policy_document.pgbackup_policy_data.json
} */

output "bucket_name" {
  value = aws_s3_bucket.ksapp_bucket.bucket
}

output "bucket_endpoint" {
  value = aws_s3_bucket.ksapp_bucket.bucket_regional_domain_name
}

output "bucket_repo_name" {
  value = var.pgbackup_repo
}

output "bucket_region" {
  value = aws_s3_bucket.ksapp_bucket.region
}

output "backup_access_key" {
  value = aws_iam_access_key.pgbackup_access_key.id
}

output "backup_access_key_secret" {
  value = aws_iam_access_key.pgbackup_access_key.encrypted_secret
}

output "app_domain" {
  value = var.app_domain_name
}

output "volume_device_name" {
  value = aws_volume_attachment.ebs_att.device_name
}

output "default_user" {
  value = var.debian_ami_default_user
}

output "fingerprint" {
  value = aws_key_pair.ks-app-key.fingerprint 
}

output "aws_region" {
  value = var.aws_region
}