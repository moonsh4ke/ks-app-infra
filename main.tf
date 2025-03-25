terraform {

  # Comment this block if your saving terraform's state locally
  backend "remote" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }

    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 5"
    }

    hcp = {
      source = "hashicorp/hcp"
      version = "0.91.0"
    }

  }

  required_version = ">= 1.2.0"
}

// Comment this block if you're not using hcp vault secrets
provider "hcp" {
  client_id = var.HCP_CLIENT_ID
  client_secret = var.HCP_CLIENT_SECRET
}


provider "aws" {
  region = var.aws_region
}

provider "cloudflare" {
}

// Comment this block if you're not using hcp vault secrets
data "hcp_vault_secrets_app" "web_application" {
  app_name = var.vault_secrets_app
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = var.volume_device_name
  volume_id   = aws_ebs_volume.pgebs.id
  instance_id = aws_instance.app_server.id
}

resource "aws_instance" "app_server" {
  ami           = var.debian_ami
  instance_type = var.instance_type
  key_name = aws_key_pair.ks-app-key.key_name
  vpc_security_group_ids = [ aws_security_group.ksapp_sg.id ]

  availability_zone = var.instance_az
  tags = {
    Name = var.instance_name
  }
}

resource "aws_eip" "elastic_ip" {
  instance = aws_instance.app_server.id
}

resource "aws_ebs_volume" "pgebs" {
  availability_zone = aws_instance.app_server.availability_zone
  size              = 2

  tags = {
    Name = var.ebs_vol_name
  }
}

resource "aws_key_pair" "ks-app-key" {
  key_name   = var.ssh_key_name
  # Not using hcp vault secrets: you can use a file or a hardcoded string for testing purposes.
  public_key = data.hcp_vault_secrets_app.web_application.secrets["SSH_PUBLIC"]
}

# -Security group configuration-

resource "aws_security_group" "ksapp_sg" {
  name        = var.security_group_name

/*   tags = {
    Name = var.security_group_name
  } */
}

resource "aws_vpc_security_group_ingress_rule" "allow_api" {
  security_group_id = aws_security_group.ksapp_sg.id
  cidr_ipv4   = "0.0.0.0/0"
  from_port         = 3000
  ip_protocol       = "tcp"
  to_port           = 3000
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.ksapp_sg.id
  cidr_ipv4   = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls" {
  security_group_id = aws_security_group.ksapp_sg.id
  cidr_ipv4   = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.ksapp_sg.id
  cidr_ipv4   = "0.0.0.0/0"
  #cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.ksapp_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# -S3-

resource "aws_s3_bucket" "ksapp_bucket" {
  # bucket = "${var.pgbackup_bucket_prefix}-${random_id.bucket.id}"
  bucket_prefix = var.pgbackup_bucket_prefix
/*   tags = {
    Name        = "${var.pgbackup_bucket_prefix}-${random_id.bucket}"
  } */
}

resource "aws_s3_bucket_policy" "allow_access_backup" {
  bucket = aws_s3_bucket.ksapp_bucket.id
  policy = data.aws_iam_policy_document.pgbackup_policy_data.json
}

data "aws_iam_policy_document" "pgbackup_policy_data" {
  statement {
    effect    = "Allow"
    resources = ["arn:aws:s3:::${aws_s3_bucket.ksapp_bucket.bucket}"]
    actions   = ["s3:ListBucket"]
    
    principals {
      type = "AWS"
      identifiers = [aws_iam_user.bucket_user.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:prefix"

      values = [
        "",
        "${var.pgbackup_repo}",
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:delimiter"
      values   = ["/"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["arn:aws:s3:::${aws_s3_bucket.ksapp_bucket.bucket}"]
    actions   = ["s3:ListBucket"]

    principals {
      type = "AWS"
      identifiers = [aws_iam_user.bucket_user.arn]
    }

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${var.pgbackup_repo}/*"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["arn:aws:s3:::${aws_s3_bucket.ksapp_bucket.bucket}/${var.pgbackup_repo}/*"]

    principals {
      type = "AWS"
      identifiers = [aws_iam_user.bucket_user.arn]
    }

    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:DeleteObject",
    ]
  }
}

resource "aws_iam_user" "bucket_user" {
  name = var.iam_bucket_user
}

resource "aws_iam_access_key" "pgbackup_access_key" {
  user = aws_iam_user.bucket_user.name
  # Not using hcp vault secrets: you can use a file or a hardcoded string for testing purposes.
  # Note: this should be a pgp public key (non-armored) in base64
  pgp_key = data.hcp_vault_secrets_app.web_application.secrets["PGP_PUBLIC_B64"]
}

# Clouflare dns record

resource "cloudflare_dns_record" "test_dns" {
  zone_id = var.cf_zone_id
  name    = var.app_domain_name
  content   = aws_eip.elastic_ip.public_dns
  type    = "CNAME"
  proxied = true
  ttl = 1
}

