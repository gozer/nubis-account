provider "aws" {
  profile = "${var.aws_profile}"
  region  = "${var.aws_region}"
}

resource "aws_cloudtrail" "opsec-cloudtrail" {
  name                          = "opsec-cloudtrail"
  s3_bucket_name                = "${var.cloudtrail_bucket}"
  sns_topic_name                = "${var.cloudtrail_sns_topic}"
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_logging                = true
}
