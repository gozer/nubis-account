variable account_name {}

variable aws_profile {
  default = "default"
}

variable nubis_version {
  default = "v1.0.1-sec1"
}

variable environments {
  default = "admin,stage,prod"
}

variable environments_networks {}

variable admin_users {
  default = "gozer,limed,riweiss,jcrowe"
}

variable guest_users {
  default = "guest"
}

variable aws_regions {
  default = "us-east-1,us-west-2"
}

variable consul {
  default = {
    master_acl_token = "00000000-0000-0000-0000-000000000000"
    secret           = "AAAAAAAAAAAAAAAAAAAAAA=="
  }
}

variable nubis_domain {
  default = "nubis.allizom.org"
}

variable technical_contact {
  default = "infra-aws@mozilla.com"
}

variable features {
  default = {
    consul       = 0
    jumphost     = 0
    fluent       = 0
    stack_compat = 0
    mig          = 0
    ci           = 0
    vpn          = 0
  }
}

variable state_uuid {
  default = ""
}

# Turn into features ?
variable datadog {
  default = {
    api_key = "unset"
  }
}

variable mig {
  default = {
    agent_cert     = "mig/agent.crt"
    agent_key      = "mig/agent.key"
    ca             = "mig/ca.crt"
    relay_password = "<unset>"
    relay_user     = "agent-it-nubis"
  }
}

variable cloudtrail {
  default = {
    bucket    = "mozilla-cloudtrail-logs"
    sns_topic = "arn:aws:sns:us-west-2:088944123687:MozillaCloudTrailLogs"
  }
}

variable my_ip {
  default = "127.0.0.1/32"
}

variable ci {
  default = {
    project                    = "skel"
    git_repo                   = "https://github.com/nubisproject/nubis-skel.git"
    github_oauth_client_secret = "AAA"
    github_oauth_client_id     = "BBB"
    admins                     = "gozer"
  }
}

variable vpn {
  default = {
    ipsec_targets = ""
    ipsec_network = "10.0.0.0/8"
    bgp_asn       = "65022"
  }
}
