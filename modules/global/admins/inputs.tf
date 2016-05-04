variable aws_profile {}

variable account_name {}

variable admin_users {}

variable guest_users {
}

variable aws_region {
  default = "us-east-1"
}

variable technical_contact {
  default = "infra-aws@mozilla.com"
}

variable nubis_version {
  default = "master"
}

variable ssh_key_name {
  default = "nubis"
}
