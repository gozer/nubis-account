provider "aws" {
  profile = "${var.aws_profile}"
  region  = "${var.aws_region}"
}

module "cloudhealth" {
  source = "github.com/nubisproject/nubis-terraform-cloudhealth"

  aws_profile = "${var.aws_profile}"
  aws_region  = "${var.aws_region}"
}

resource "aws_iam_user" "datadog" {
  path = "/nubis/datadog/"
  name = "datadog"
}

resource "aws_iam_access_key" "datadog" {
  user = "${aws_iam_user.datadog.name}"
}

resource "aws_iam_user_policy" "datadog" {
  name = "datadog-readonly"
  user = "${aws_iam_user.datadog.name}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
"Action": [
                    "autoscaling:Describe*",
                    "cloudtrail:DescribeTrails",
                    "cloudtrail:GetTrailStatus",
                    "cloudwatch:Describe*",
                    "cloudwatch:Get*",
                    "cloudwatch:List*",
                    "dynamodb:list*",
                    "dynamodb:describe*",
                    "ec2:Describe*",
                    "ec2:Get*",
                    "ecs:Describe*",
                    "ecs:List*",
                    "elasticache:Describe*",
                    "elasticache:List*",
                    "elasticloadbalancing:Describe*",
                    "elasticmapreduce:List*",
                    "elasticmapreduce:Describe*",
                    "kinesis:List*",
                    "kinesis:Describe*",
                    "logs:Get*",
                    "logs:Describe*",
                    "logs:FilterLogEvents",
                    "logs:TestMetricFilter",
                    "rds:Describe*",
                    "rds:List*",
                    "route53:List*",
                    "ses:Get*",
                    "sns:List*",
                    "sns:Publish",
                    "sqs:GetQueueAttributes",
                    "sqs:ListQueues",
                    "sqs:ReceiveMessage",
                    "support:*"
                  ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_route53_zone" "master_zone" {
  name = "${var.account_name}.${var.nubis_domain}"

  tags {
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
  }
}

resource "aws_route53_record" "nubis-version" {
  zone_id = "${aws_route53_zone.master_zone.id}"
  name    = "version.nubis"

  type = "TXT"
  ttl = "300"
  records = ["${var.nubis_version}"]
}

resource "aws_route53_record" "nubis-state" {
  zone_id = "${aws_route53_zone.master_zone.id}"
  name    = "state.nubis"

  type = "A"

  alias {
    name = "${aws_cloudfront_distribution.public-state.domain_name}"
    zone_id = "${aws_cloudfront_distribution.public-state.hosted_zone_id}"
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

# XXX: Duplicated here to avoid chicken-and-egg with VPCs
resource "aws_lambda_function" "GlobalUUID" {
  #lifecycle {
  #  create_before_destroy = true
  #}

  function_name = "GlobalUUID"
  s3_bucket     = "nubis-stacks"
  #s3_bucket     = "nubis-stacks-${var.aws_region}"
  s3_key        = "${var.nubis_version}/lambda/UUID.zip"
  handler       = "index.handler"
  description   = "Generate UUIDs for use in Nubis Meta"
  memory_size   = 128
  runtime       = "nodejs"
  timeout       = "10"
  role          = "${aws_iam_role.global_lambda.arn}"
}

module "public-state-uuid" {
  source  = "../../uuid"
  enabled = "1"

  aws_profile = "${var.aws_profile}"
  aws_region  = "${var.aws_region}"

  name = "public-state"

  environments = "global"

  lambda_uuid_arn = "${aws_lambda_function.GlobalUUID.arn}"
}

resource "aws_s3_bucket" "public-state" {
  bucket = "public-state-${module.public-state-uuid.uuids}"
  acl    = "private"

  policy = <<EOF
{
	"Version": "2008-10-17",
	"Id": "PolicyForCloudFrontPrivateContent",
	"Statement": [
		{
			"Sid": "1",
			"Effect": "Allow",
			"Principal": {
				"AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.public-state.id}"
			},
			"Action": "s3:GetObject",
			"Resource": "arn:aws:s3:::public-state-${module.public-state-uuid.uuids}/*"
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

  aliases = [ "state.nubis.${var.account_name}.${var.nubis_domain}" ]

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
  }
}


resource "aws_route53_delegation_set" "meta" {
  lifecycle {
    create_before_destroy = true
  }

  reference_name = "Meta"
}
