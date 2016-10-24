output "datadog_access_key" {
  value = "${aws_iam_access_key.datadog.id}"
}

output "datadog_secret_key" {
  value = "${aws_iam_access_key.datadog.secret}"
}

output "route53_delegation_set" {
  value = "${aws_route53_delegation_set.meta.id}"
}

output "nameservers" {
  value = "${join(",",aws_route53_zone.master_zone.name_servers)}"
}

output "route53_master_zone_id" {
  value = "${aws_route53_zone.master_zone.id}"
}

output "route53_master_zone_name" {
  value = "${aws_route53_zone.master_zone.name}"
}

output "cloudhealth_assume_role_arn" {
  value = "${module.cloudhealth.assume_role_arn}"
}

output "cloudhealth_assume_role_external_id" {
  value = "${module.cloudhealth.assume_role_external_id}"
}

output "public_state_bucket" {
  value = "${aws_s3_bucket.public-state.bucket}"
}
