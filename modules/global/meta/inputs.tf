variable aws_profile {}

variable account_name {}

variable aws_region {
  default = ""
}

variable aws_region_state {
  default = "eu-west-1"
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

variable state_uuid {
  default = ""
}
