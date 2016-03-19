provider "aws" {
    profile = "${var.aws_profile}"
    region = "${var.aws_region}"
}

#XXX: We create this on purpose for all the regions we support
resource "aws_route53_zone" "hosted_zone" {
   name = "${var.aws_region}.${var.service_name}.${var.nubis_domain}"

    tags {
      ServiceName = "${var.service_name}"
      TechnicalOwner = "${var.technical_owner}"
    }
}

resource "aws_kms_key" "credstash" {
    count = "${var.enabled}"
    description = "Key for Credstash in ${var.aws_region}"
    policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-admin",
  "Statement": [
    {
      "Action": "kms:*",
      "Effect": "Allow",
      "Principal": "*",
      "Resource": "*",
      "Sid": "Enable KMS Usage"
    }
  ]
}  
POLICY
}

resource "aws_dynamodb_table" "credstash" {
    count = "${var.enabled}"
    name = "credential-store"
    read_capacity = 1
    write_capacity = 1
    hash_key = "name"
    range_key = "version"
    attribute {
      name = "name"
      type = "S"
    }
    attribute {
      name = "version"
      type = "S"
    }

}

resource "aws_kms_alias" "credstash" {
    count = "${var.enabled}"
    name = "alias/credstash"
    target_key_id = "${aws_kms_key.credstash.key_id}"
}

resource "tls_private_key" "default" {
  count = "${var.enabled}"

  algorithm = "RSA"
}

resource "tls_self_signed_cert" "default" {
    count = "${var.enabled}"
    key_algorithm = "${tls_private_key.default.algorithm}"
    private_key_pem = "${tls_private_key.default.private_key_pem}"

    # Certificate expires after 10 years
    validity_period_hours = 43800

    # Generate a new certificate if Terraform is run within 2 weeks
        # of the certificate's expiration time.
    early_renewal_hours = 168

    # Reasonable set of uses for a server SSL certificate.
    allowed_uses = [
        "key_encipherment",
        "digital_signature",
        "server_auth",
    ]

    subject {
        common_name = "*.${var.aws_region}.${var.service_name}.${var.nubis_domain}"
        organization = "Mozilla Nubis"
    }
}

resource "aws_iam_server_certificate" "default" {
    count = "${var.enabled}"
    name = "${var.aws_region}.${var.service_name}.${var.nubis_domain}"
    certificate_body = "${tls_self_signed_cert.default.cert_pem}"
    private_key = "${tls_private_key.default.private_key_pem}"

    provisioner "local-exec" {
      command = "sleep 30"
    }
    
}

resource "aws_db_parameter_group" "mysql56" {
    count = "${var.enabled}"
    name = "mysql56"
    family = "mysql5.6"
    description = "Nubis DB Parameter group for MySql 5.6"

    parameter {
      name = "max_allowed_packet"
      value = "25165824"
    }
    
    tags {
      ServiceName = "${var.service_name}"
      TechnicalOwner = "${var.technical_owner}"
    }
}

output "NubisMySQL56ParameterGroup" {
  value = "${aws_db_parameter_group.mysql56.arn}"
}

output "DefaultServerCertificate" {
  value = "${aws_iam_server_certificate.default.arn}"
}

output "CredstashKeyID" {
  value = "${aws_kms_key.credstash.arn}"
}

output "HostedZoneId" {
  value = "${aws_route53_zone.hosted_zone.zone_id}"
}

output "HostedZoneName" {
  value = "${aws_route53_zone.hosted_zone.name}"
}

output "CredstashDynamoDB" {
  value = "${aws_dynamodb_table.credstash.arn}"
}

output "HostedZoneNS" {
  value = "${aws_route53_zone.hosted_zone.name_servers.0},${aws_route53_zone.hosted_zone.name_servers.1},${aws_route53_zone.hosted_zone.name_servers.2},${aws_route53_zone.hosted_zone.name_servers.3}"
}
