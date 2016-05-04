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
  value = "${join(",",aws_route53_delegation_set.meta.name_servers)}"
}

output "cloudhealth_assume_role_arn" {
  value = "${module.cloudhealth.assume_role_arn}"
}

output "cloudhealth_assume_role_external_id" {
  value = "${module.cloudhealth.assume_role_external_id}"
}
