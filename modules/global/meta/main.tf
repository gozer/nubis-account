provider "aws" {
  version = "~> 1"
  region  = "${var.aws_region}"
}

module "cloudhealth" {
  source = "github.com/nubisproject/nubis-terraform-cloudhealth?ref=v2.4.3"

  aws_profile = "default"
  aws_region  = "${var.aws_region}"
}

resource "aws_route53_zone" "master_zone" {
  name = "${var.account_name}.${var.nubis_domain}"

  tags {
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    NubisVersion     = "${var.nubis_version}"
  }
}

resource "aws_route53_record" "nubis-version" {
  zone_id = "${aws_route53_zone.master_zone.id}"
  name    = "version.nubis"

  type    = "TXT"
  ttl     = "300"
  records = ["${var.nubis_version}"]
}

resource "aws_route53_record" "nubis-state" {
  zone_id = "${aws_route53_zone.master_zone.id}"
  name    = "state.nubis"

  type = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.public-state.domain_name}"
    zone_id                = "${aws_cloudfront_distribution.public-state.hosted_zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_iam_role" "global_lambda" {
  lifecycle {
    create_before_destroy = true
  }

  name = "lambda-global-${var.aws_region}"

  provisioner "local-exec" {
    command = "sleep 30"
  }

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Allow",
              "Principal": {
                "Service": [
                  "lambda.amazonaws.com"
                ]
              },
              "Action": [
                "sts:AssumeRole"
              ]
            }
          ]
}
EOF
}

resource "aws_s3_bucket" "public-state" {
  bucket_prefix = "public-state-"
  acl           = "private"

  force_destroy = true

  versioning {
    enabled = true
  }

  tags {
    TechnicalContact = "${var.technical_contact}"
  }
}

resource "aws_s3_bucket_policy" "public-state" {
  bucket = "${aws_s3_bucket.public-state.id}"

  policy = <<EOF
{
	"Version": "2008-10-17",
	"Id": "PolicyForCloudFrontPrivateContent",
	"Statement": [
		{
			"Sid": "1",
			"Effect": "Allow",
			"Principal": {
				"AWS": "${aws_cloudfront_origin_access_identity.public-state.iam_arn}"
			},
			"Action": "s3:GetObject",
			"Resource": "${aws_s3_bucket.public-state.arn}/*"
		}
	]
}
EOF
}

resource "aws_cloudfront_origin_access_identity" "public-state" {
  comment = "For Public State"
}

resource "aws_cloudfront_distribution" "public-state" {
  origin {
    domain_name = "${aws_s3_bucket.public-state.bucket}.s3.amazonaws.com"
    origin_id   = "nubis-public-state"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.public-state.cloudfront_access_identity_path}"
    }
  }

  aliases = ["state.nubis.${var.account_name}.${var.nubis_domain}"]

  enabled             = true
  comment             = "Nubis Public State"
  default_root_object = "index.txt"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "nubis-public-state"

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 30
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1"
  }
}

resource "aws_route53_delegation_set" "meta" {
  lifecycle {
    create_before_destroy = true
  }

  reference_name = "Meta"
}

resource "aws_s3_bucket" "apps-state" {
  bucket_prefix = "nubis-apps-state-"
  acl           = "private"
  region        = "${var.aws_region}"

  force_destroy = true

  versioning {
    enabled = true
  }

  tags {
    TechnicalContact = "${var.technical_contact}"
  }
}

module "autospotting" {
  source = "github.com/cristim/autospotting//terraform?ref=5e1e46a01972ece3793dea04d7b9d7354346e394"

  #  autospotting_min_on_demand_number = "0"
  #  autospotting_min_on_demand_percentage = "50.0"
  #  autospotting_regions_enabled = "eu*,us*"
  lambda_zipname = "${path.module}/lambda_build_7a127d2.zip"
}

#spot-enabled

