provider "aws" {
  version = "~> 1"
  region  = "${var.aws_region}"
}

provider "null" {
  version = "~> 1"
}

provider "template" {
  version = "~> 1"
}

data "aws_caller_identity" "current" {}

resource "aws_key_pair" "nubis" {
  count = "${var.enabled}"

  lifecycle {
    create_before_destroy = true
  }

  key_name   = "${var.ssh_key_name}"
  public_key = "${var.nubis_ssh_key}"
}

resource "aws_iam_policy" "credstash" {
  count = "${var.enabled * length(var.arenas)}"

  name        = "credstash-${element(var.arenas, count.index)}-${var.aws_region}"
  description = "Policy for reading the Credstash DynamoDB"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "kms:Decrypt"
      ],
      "Effect": "Allow",
      "Resource": "${module.meta.CredstashKeyID}",
      "Condition": {
                "StringEquals": {
                  "kms:EncryptionContext:arena": "${element(var.arenas, count.index)}",
                  "kms:EncryptionContext:region": "${var.aws_region}",
                  "kms:EncryptionContext:service": "nubis"
                }
            }
    },
                {
              "Effect": "Allow",
              "Action": [
                "dynamodb:BatchGetItem",
                "dynamodb:DescribeTable",
                "dynamodb:GetItem",
                "dynamodb:ListTables",
                "dynamodb:Query",
                "dynamodb:Scan",
                "dynamodb:DescribeReservedCapacity",
                "dynamodb:DescribeReservedCapacityOfferings"
              ],
              "Resource": "${module.meta.CredstashDynamoDB}"
            }
  ]
}
POLICY
}

module "meta" {
  source = "../meta"

  enabled = "${var.enabled}"

  aws_region = "${var.aws_region}"

  nubis_version     = "${var.nubis_version}"
  nubis_domain      = "${var.nubis_domain}"
  technical_contact = "${var.technical_contact}"

  service_name = "${var.account_name}"

  route53_delegation_set = "${var.route53_delegation_set}"
  route53_master_zone_id = "${var.route53_master_zone_id}"
}

resource "aws_vpc" "nubis" {
  count = "${var.enabled * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  # index(split(",",var.aws_regions), var.aws_region)
  # is the index of the current region, starting at 0
  # So the correct grouping of subnets is count.index + ( 3 * region-index )
  cidr_block = "${element(var.arenas_networks, count.index + (3 * index(split(",",var.aws_regions), var.aws_region)) )}"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name             = "${var.aws_region}-${element(var.arenas, count.index)}-vpc"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    Arena            = "${element(var.arenas, count.index)}"
  }
}

data "aws_iam_policy_document" "flow_logs_assume_role" {
  count = "${var.enabled * var.flow_logs}"

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "flow_logs" {
  count = "${var.enabled * var.flow_logs}"
  name  = "flow_logs-${var.aws_region}"

  assume_role_policy = "${data.aws_iam_policy_document.flow_logs_assume_role.json}"
}

data "aws_iam_policy_document" "flow_logs_role" {
  count = "${var.enabled * var.flow_logs}"

  statement {
    sid = "FlowLogs"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "flow_logs" {
  count = "${var.enabled * var.flow_logs}"
  name  = "flow_logs-${var.aws_region}"
  role  = "${aws_iam_role.flow_logs.id}"

  policy = "${data.aws_iam_policy_document.flow_logs_role.json}"
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  count             = "${var.enabled * var.flow_logs * length(var.arenas)}"
  name              = "flow_logs-${var.aws_region}-${element(var.arenas, count.index)}"
  retention_in_days = "30"

  tags {
    Name             = "${var.aws_region}-${element(var.arenas, count.index)}-vpc"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    Arena            = "${element(var.arenas, count.index)}"
  }
}

resource "aws_flow_log" "flow_log" {
  count          = "${var.enabled * var.flow_logs * length(var.arenas)}"
  log_group_name = "${element(aws_cloudwatch_log_group.flow_logs.*.name, count.index)}"
  iam_role_arn   = "${aws_iam_role.flow_logs.arn}"
  vpc_id         = "${element(aws_vpc.nubis.*.id, count.index)}"
  traffic_type   = "ALL"
}

resource "aws_default_security_group" "default" {
  count = "${var.enabled * length(var.arenas)}"

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index)}"

  # Clear default ingress rules
  #ingress {
  #  protocol  = -1
  #  self      = true
  #  from_port = 0
  #  to_port   = 0
  #}

  # Clear default egress rules
  #egress {
  #  from_port   = 0
  #  to_port     = 0
  #  protocol    = "-1"
  #  cidr_blocks = ["0.0.0.0/0"]
  #}
}

resource "aws_main_route_table_association" "public" {
  count = "${var.enabled * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id         = "${element(aws_vpc.nubis.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.public.*.id, count.index)}"
}

resource "aws_security_group" "monitoring" {
  count = "${var.enabled * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index)}"

  name_prefix = "MonitoringSecurityGroup-${element(var.arenas, count.index)}-"
  description = "Securiry group for monitoring hosts"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name             = "MonitoringSecurityGroup"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    Arena            = "${element(var.arenas, count.index)}"
  }
}

resource "aws_security_group" "ssh" {
  count = "${var.enabled * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index)}"

  name_prefix = "SshSecurityGroup-${element(var.arenas, count.index)}-"
  description = "SSH Security Group"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name             = "SshSecurityGroup"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    Arena            = "${element(var.arenas, count.index)}"
  }
}

resource "aws_security_group" "sso" {
  count = "${var.enabled * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index)}"

  name_prefix = "SSOSecurityGroup-${element(var.arenas, count.index)}-"
  description = "SSO Security Group"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name             = "SSOSecurityGroup"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    Arena            = "${element(var.arenas, count.index)}"
  }
}

resource "aws_security_group" "internet_access" {
  count = "${var.enabled * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index)}"

  name_prefix = "InternetAccessSecurityGroup-${element(var.arenas, count.index)}-"
  description = "Internet Access security group"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name             = "InternetAccessSecurityGroup"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    Arena            = "${element(var.arenas, count.index)}"
  }
}

resource "aws_security_group" "nat" {
  count = "${var.enabled * var.enable_nat * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index)}"

  name_prefix = "NATSecurityGroup-${element(var.arenas, count.index)}"
  description = "NAT security group"

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"

    security_groups = [
      "${element(aws_security_group.internet_access.*.id, count.index)}",
    ]
  }

  # Allow the internal proxy ELB to reach us
  ingress {
    from_port = 3128
    to_port   = 3128
    protocol  = "tcp"

    security_groups = [
      "${element(aws_security_group.proxy.*.id, count.index)}",
    ]
  }

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "udp"

    security_groups = [
      "${element(aws_security_group.internet_access.*.id, count.index)}",
    ]
  }

  ingress {
    from_port = 8
    to_port   = -1
    protocol  = "icmp"

    security_groups = [
      "${element(aws_security_group.internet_access.*.id, count.index)}",
    ]
  }

  # conntrackd
  ingress {
    from_port = 3780
    to_port   = 3780
    protocol  = "udp"

    self = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name             = "NATSecurityGroup-${element(var.arenas, count.index)}"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    Arena            = "${element(var.arenas, count.index)}"
  }
}

resource "aws_security_group" "shared_services" {
  count = "${var.enabled * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index)}"

  name        = "SharedServicesSecurityGroup-${element(var.arenas, count.index)}"
  description = "The security group for all instances."

  ingress {
    from_port   = 8
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Consul TCP
  ingress {
    self      = true
    from_port = 8300
    to_port   = 8302
    protocol  = "tcp"
  }

  # Consul UDP
  ingress {
    self      = true
    from_port = 8300
    to_port   = 8302
    protocol  = "udp"
  }

  # Poll Monitoring
  ingress {
    security_groups = [
      "${element(aws_security_group.monitoring.*.id, count.index)}",
    ]

    from_port = 9100
    to_port   = 9200
    protocol  = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name             = "SharedServicesSecurityGroup"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    Arena            = "${element(var.arenas, count.index)}"
  }
}

data "aws_availability_zones" "available" {}

locals {
  kubernetes_cluster_tag = "kubernetes.io/cluster/k8s.deploy.${var.aws_region}.${var.account_name}.${var.nubis_domain}"

  # Ugly but Terraform forces me to
  # Can't use map(list()) [bug], must use zipmap(list(),list())
  kubernetes_public_tags_keys = "${join(",", list(
    "SubnetType",
    "kubernetes.io/role/elb",
    "${local.kubernetes_cluster_tag}",
    "${local.service_name_tag_key}",
  ))}"

  kubernetes_public_tags_values = "${join(",", list(
    "Utility",
    "1",
    "shared",
    "${local.service_name_tag_value}",
  ))}"

  kubernetes_private_tags_keys = "${join(",", list(
    "SubnetType",
    "kubernetes.io/role/internal-elb",
    "${local.kubernetes_cluster_tag}",
    "${local.service_name_tag_key}",
  ))}"

  kubernetes_private_tags_values = "${join(",", list(
    "Private",
    "1",
    "shared",
    "${local.service_name_tag_value}",
  ))}"

  service_name_tag_key   = "ServiceName"
  service_name_tag_value = "${var.account_name}"
}

# ATM, we just create public subnets for each arena in the first 3 AZs
resource "aws_subnet" "public" {
  count = "${3 * var.enabled * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index / 3)}"

  availability_zone = "${data.aws_availability_zones.available.names[count.index % 3]}"

  cidr_block = "${cidrsubnet(element(aws_vpc.nubis.*.cidr_block, count.index / 3), 3, count.index % 3 )}"

  tags = "${merge(map(
    "Name", "PublicSubnet-${element(var.arenas, count.index / 3)}-AZ${(count.index % 3 ) + 1}",
    "TechnicalContact", "${var.technical_contact}",
    "Arena", "${element(var.arenas, count.index / 3)}"),
    zipmap(split(",", (var.enabled * var.enable_kubernetes) == 1 ?  local.kubernetes_public_tags_keys : local.service_name_tag_key), split(",",  (var.enabled * var.enable_kubernetes) == 1 ? local.kubernetes_public_tags_values : local.service_name_tag_value)),
  )}"
}

# ATM, we just create private subnets for each arena in the first 3 AZs
resource "aws_subnet" "private" {
  count = "${3 * var.enabled * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index / 3)}"

  availability_zone = "${data.aws_availability_zones.available.names[count.index % 3]}"

  cidr_block = "${cidrsubnet(element(aws_vpc.nubis.*.cidr_block, count.index / 3), 3, (count.index % 3) + 3 )}"

  tags = "${merge(map(
    "Name", "PrivateSubnet-${element(var.arenas, count.index / 3)}-AZ${(count.index % 3 ) + 1}",
    "TechnicalContact", "${var.technical_contact}",
    "Arena", "${element(var.arenas, count.index / 3)}"),
     zipmap(split(",", (var.enabled * var.enable_kubernetes) == 1 ?  local.kubernetes_private_tags_keys : local.service_name_tag_key), split(",",  (var.enabled * var.enable_kubernetes) == 1 ? local.kubernetes_private_tags_values : local.service_name_tag_value)),
  )}"
}

resource "aws_route_table_association" "public" {
  count = "${3 * var.enabled * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.public.*.id, count.index / 3)}"
}

resource "aws_internet_gateway" "nubis" {
  count = "${var.enabled * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index)}"

  tags {
    Name             = "InternetGateway-${element(var.arenas, count.index)}"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    Arena            = "${element(var.arenas, count.index)}"
  }
}

resource "aws_route_table" "public" {
  count = "${var.enabled * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index)}"

  tags {
    Name             = "PublicRoute-${element(var.arenas, count.index)}"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    Arena            = "${element(var.arenas, count.index)}"
  }
}

resource "aws_route" "public" {
  count = "${var.enabled * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  route_table_id = "${element(aws_route_table.public.*.id, count.index)}"

  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${element(aws_internet_gateway.nubis.*.id, count.index)}"
}

resource "aws_route_table" "private" {
  count = "${3 * var.enabled * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index / 3)}"

  tags {
    Name             = "PrivateRoute-${element(var.arenas, count.index/3)}-AZ${(count.index % 3 ) + 1}"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    Arena            = "${element(var.arenas, count.index)}"
    RouteType        = "private"
  }
}

resource "aws_route_table_association" "private" {
  count = "${3 * var.enabled * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

resource "aws_network_interface" "private-nat" {
  count = "${3 * var.enabled * var.enable_nat * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  subnet_id = "${element(aws_subnet.private.*.id, count.index)}"

  source_dest_check = false

  tags {
    Name = "NatENI-${element(var.arenas, count.index/3)}-AZ${(count.index % 3 ) + 1}"

    # Found by the nat instance doing --filter Name=tag-value,Values=nubis-nat-eni-stage Name=availability-zone,Values=$MY_AZ
    Autodiscover     = "nubis-nat-eni-${element(var.arenas, count.index/3)}"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    Arena            = "${element(var.arenas, count.index)}"
  }

  security_groups = [
    "${element(aws_security_group.shared_services.*.id, count.index / 3 )}",
    "${element(aws_security_group.nat.*.id, count.index / 3 )}",
  ]
}

module "nat-image" {
  source        = "github.com/nubisproject/nubis-terraform//images?ref=v2.4.0"
  region        = "${var.aws_region}"
  image_version = "${coalesce(var.nat_version, var.nubis_version)}"
  project       = "nubis-nat"
}

variable nat_side {
  default = {
    "0" = "left"
    "1" = "right"
  }
}

resource "aws_autoscaling_group" "nat" {
  count = "${var.enabled * 2 * var.enable_nat * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  name = "nat-${element(var.arenas, count.index/2)}-${lookup(var.nat_side, count.index % 2)} (${element(aws_launch_configuration.nat.*.name, count.index)})"

  # Subnets
  vpc_zone_identifier = [
    "${element(aws_subnet.public.*.id, 3*(count.index/2) + ( count.index % 2 ))}",
  ]

  load_balancers = [
    "${element(aws_elb.proxy.*.name, count.index/2)}",
  ]

  max_size         = 2
  min_size         = 1
  desired_capacity = 1

  # ELB
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_configuration = "${element(aws_launch_configuration.nat.*.name, count.index)}"

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  tag {
    key                 = "Name"
    value               = "NAT (${coalesce(var.nat_version, var.nubis_version)}) for ${var.account_name} in ${element(var.arenas, count.index/2)}/${lookup(var.nat_side,count.index%2)}"
    propagate_at_launch = true
  }

  tag {
    key                 = "ServiceName"
    value               = "${var.account_name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "TechnicalContact"
    value               = "${var.technical_contact}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Arena"
    value               = "${element(var.arenas, count.index/2)}"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "nat" {
  count = "${var.enabled * 2 * var.enable_nat * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  name_prefix = "nat-${element(var.arenas, count.index/2 )}-${lookup(var.nat_side, count.index % 2)}-"

  image_id = "${module.nat-image.image_id}"

  instance_type               = "t2.small"
  associate_public_ip_address = true
  key_name                    = "${var.ssh_key_name}"

  iam_instance_profile = "${element(aws_iam_instance_profile.nat.*.id, count.index/2)}"

  security_groups = [
    "${element(aws_security_group.internet_access.*.id, count.index/2)}",
    "${element(aws_security_group.nat.*.id, count.index/2)}",
    "${element(aws_security_group.ssh.*.id, count.index/2)}",
    "${element(aws_security_group.shared_services.*.id, count.index/2)}",
  ]

  user_data = <<USER_DATA
NUBIS_PROJECT='nat'
NUBIS_ARENA='${element(var.arenas, count.index/2)}'
NUBIS_DOMAIN='${var.nubis_domain}'
NUBIS_ACCOUNT='${var.account_name}'
NUBIS_NAT_EIP='${element(aws_eip.nat.*.id, count.index)}'
NUBIS_NAT_SIDE='${lookup(var.nat_side,count.index%2)}'
NUBIS_NAT_PEER_SIDE='${lookup(var.nat_side,(1+count.index)%2)}'
NUBIS_SUDO_GROUPS="${var.nat_sudo_groups}"
NUBIS_USER_GROUPS="${var.nat_user_groups}"
USER_DATA
}

resource "aws_iam_role_policy_attachment" "nat" {
  count      = "${var.enabled * var.enable_nat * length(var.arenas)}"
  role       = "${element(concat(aws_iam_role.nat.*.id, list("")), count.index)}"
  policy_arn = "${element(aws_iam_policy.credstash.*.arn, count.index)}"
}

resource "aws_iam_role" "nat" {
  count = "${var.enabled * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  path = "/nubis/"
  name = "nubis-nat-role-${element(var.arenas, count.index)}-${var.aws_region}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "nat" {
  count = "${var.enabled * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  name   = "nubis-nat-policy-${element(var.arenas, count.index)}-${var.aws_region}"
  role   = "${element(aws_iam_role.nat.*.id, count.index)}"
  policy = "${file("${path.module}/nat-policy.json")}"
}

resource "aws_iam_instance_profile" "nat" {
  count = "${var.enabled * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  name = "nubis-nat-profile-${element(var.arenas, count.index)}-${var.aws_region}"
  role = "${element(aws_iam_role.nat.*.name, count.index)}"
}

module "jumphost" {
  source = "github.com/nubisproject/nubis-jumphost//nubis/terraform?ref=v2.4.2"

  enabled = "${var.enabled * var.enable_jumphost}"

  arenas     = "${var.arenas}"
  aws_region = "${var.aws_region}"

  key_name          = "${var.ssh_key_name}"
  nubis_version     = "${coalesce(var.jumphost_version, var.nubis_version)}"
  technical_contact = "${var.technical_contact}"

  zone_id = "${module.meta.HostedZoneId}"

  vpc_ids           = "${join(",", aws_vpc.nubis.*.id)}"
  public_subnet_ids = "${join(",", aws_subnet.public.*.id)}"

  internet_access_security_groups = "${join(",",aws_security_group.internet_access.*.id)}"
  shared_services_security_groups = "${join(",",aws_security_group.shared_services.*.id)}"
  ssh_security_groups             = "${join(",",aws_security_group.ssh.*.id)}"

  nubis_domain = "${var.nubis_domain}"

  service_name = "${var.account_name}"

  nubis_sudo_groups = "${var.jumphost_sudo_groups}"
  nubis_user_groups = "${var.jumphost_user_groups}"
}

resource "aws_iam_role_policy_attachment" "fluent" {
  count      = "${var.enabled * var.enable_fluent * length(var.arenas)}"
  role       = "${element(split(",",module.fluent-collector.iam_roles), count.index)}"
  policy_arn = "${element(aws_iam_policy.credstash.*.arn, count.index)}"
}

module "fluent-collector" {
  source = "github.com/nubisproject/nubis-fluent-collector//nubis/terraform?ref=v2.4.0"

  enabled            = "${var.enabled * var.enable_fluent}"
  monitoring_enabled = "${var.enabled * var.enable_fluent * var.enable_monitoring}"

  arenas     = "${var.arenas}"
  aws_region = "${var.aws_region}"

  key_name          = "${var.ssh_key_name}"
  nubis_version     = "${coalesce(var.fluentd_version, var.nubis_version)}"
  technical_contact = "${var.technical_contact}"

  zone_id = "${module.meta.HostedZoneId}"

  vpc_ids    = "${join(",", aws_vpc.nubis.*.id)}"
  subnet_ids = "${join(",", aws_subnet.private.*.id)}"

  internet_access_security_groups = "${join(",",aws_security_group.internet_access.*.id)}"
  shared_services_security_groups = "${join(",",aws_security_group.shared_services.*.id)}"
  ssh_security_groups             = "${join(",",aws_security_group.ssh.*.id)}"
  monitoring_security_groups      = "${join(",",aws_security_group.monitoring.*.id)}"
  sso_security_groups             = "${join(",",aws_security_group.sso.*.id)}"

  nubis_domain = "${var.nubis_domain}"

  service_name = "${var.account_name}"

  credstash_key = "${module.meta.CredstashKeyID}"

  sqs_queues      = "${lookup(var.fluentd, "sqs_queues")}"
  sqs_access_keys = "${lookup(var.fluentd, "sqs_access_keys")}"
  sqs_secret_keys = "${lookup(var.fluentd, "sqs_secret_keys")}"
  sqs_regions     = "${lookup(var.fluentd, "sqs_regions")}"

  nubis_sudo_groups = "${lookup(var.fluentd, "sudo_groups")}"
  nubis_user_groups = "${lookup(var.fluentd, "user_groups")}"

  instance_type = "${lookup(var.fluentd, "instance_type", "")}"
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  count      = "${var.enabled * var.enable_monitoring * length(var.arenas)}"
  role       = "${element(split(",",module.monitoring.iam_roles), count.index)}"
  policy_arn = "${element(aws_iam_policy.credstash.*.arn, count.index)}"
}

module "monitoring" {
  source = "github.com/nubisproject/nubis-prometheus//nubis/terraform?ref=v2.4.2"

  enabled = "${var.enabled * var.enable_monitoring}"

  arenas     = "${var.arenas}"
  aws_region = "${var.aws_region}"

  key_name      = "${var.ssh_key_name}"
  nubis_version = "${coalesce(var.monitoring_version, var.nubis_version)}"
  instance_type = "${var.monitoring_instance_type}"
  swap_size_meg = "${var.monitoring_swap_size_meg}"

  technical_contact = "${var.technical_contact}"

  vpc_ids           = "${join(",", aws_vpc.nubis.*.id)}"
  subnet_ids        = "${join(",", aws_subnet.private.*.id)}"
  public_subnet_ids = "${join(",", aws_subnet.public.*.id)}"

  internet_access_security_groups = "${join(",",aws_security_group.internet_access.*.id)}"
  shared_services_security_groups = "${join(",",aws_security_group.shared_services.*.id)}"
  ssh_security_groups             = "${join(",",aws_security_group.ssh.*.id)}"
  monitoring_security_groups      = "${join(",",aws_security_group.monitoring.*.id)}"
  sso_security_groups             = "${join(",",aws_security_group.sso.*.id)}"

  credstash_key            = "${module.meta.CredstashKeyID}"
  credstash_dynamodb_table = "${module.meta.CredstashDynamoDB}"

  nubis_domain = "${var.nubis_domain}"
  service_name = "${var.account_name}"
  zone_id      = "${module.meta.HostedZoneId}"

  slack_url          = "${var.monitoring_slack_url}"
  slack_channel      = "${var.monitoring_slack_channel}"
  notification_email = "${var.monitoring_notification_email}"

  pagerduty_critical_platform_service_key        = "${var.monitoring_pagerduty_critical_platform_service_key}"
  pagerduty_non_critical_platform_service_key    = "${var.monitoring_pagerduty_non_critical_platform_service_key}"
  pagerduty_critical_application_service_key     = "${var.monitoring_pagerduty_critical_application_service_key}"
  pagerduty_non_critical_application_service_key = "${var.monitoring_pagerduty_non_critical_application_service_key}"

  nubis_sudo_groups = "${var.monitoring_sudo_groups}"
  nubis_user_groups = "${var.monitoring_user_groups}"

  password = "${var.monitoring_password}"

  instance_type = "${var.monitoring_instance_type}"
}

resource "aws_iam_role_policy_attachment" "sso" {
  count      = "${var.enabled * var.enable_sso * length(var.arenas)}"
  role       = "${element(split(",",module.sso.iam_roles), count.index)}"
  policy_arn = "${element(aws_iam_policy.credstash.*.arn, count.index)}"
}

module "sso" {
  source = "github.com/nubisproject/nubis-sso//nubis/terraform?ref=v2.4.0"

  enabled = "${var.enabled * var.enable_sso}"

  arenas     = "${var.arenas}"
  aws_region = "${var.aws_region}"

  key_name          = "${var.ssh_key_name}"
  nubis_version     = "${coalesce(var.sso_version, var.nubis_version)}"
  technical_contact = "${var.technical_contact}"

  vpc_ids           = "${join(",", aws_vpc.nubis.*.id)}"
  subnet_ids        = "${join(",", aws_subnet.private.*.id)}"
  public_subnet_ids = "${join(",", aws_subnet.public.*.id)}"

  internet_access_security_groups = "${join(",",aws_security_group.internet_access.*.id)}"
  shared_services_security_groups = "${join(",",aws_security_group.shared_services.*.id)}"
  ssh_security_groups             = "${join(",",aws_security_group.ssh.*.id)}"
  monitoring_security_groups      = "${join(",",aws_security_group.monitoring.*.id)}"
  sso_security_groups             = "${join(",",aws_security_group.sso.*.id)}"

  openid_client_id     = "${var.sso_openid_client_id}"
  openid_client_secret = "${var.sso_openid_client_secret}"

  credstash_key            = "${module.meta.CredstashKeyID}"
  credstash_dynamodb_table = "${module.meta.CredstashDynamoDB}"

  nubis_domain = "${var.nubis_domain}"
  service_name = "${var.account_name}"
  zone_id      = "${module.meta.HostedZoneId}"

  nubis_sudo_groups = "${var.sso_sudo_groups}"
  nubis_user_groups = "${var.sso_user_groups}"
}

resource "aws_iam_role_policy_attachment" "consul" {
  count      = "${var.enabled * var.enable_consul * length(var.arenas)}"
  role       = "${element(split(",",module.consul.iam_roles), count.index)}"
  policy_arn = "${element(aws_iam_policy.credstash.*.arn, count.index)}"
}

module "consul" {
  source = "github.com/nubisproject/nubis-consul//nubis/terraform?ref=v2.4.0"

  enabled = "${var.enabled * var.enable_consul}"

  arenas = "${var.arenas}"

  aws_region = "${var.aws_region}"

  key_name      = "${var.ssh_key_name}"
  nubis_version = "${coalesce(var.consul_version, var.nubis_version)}"
  service_name  = "${var.account_name}"

  credstash_key            = "${module.meta.CredstashKeyID}"
  credstash_dynamodb_table = "${module.meta.CredstashDynamoDB}"

  secret = "${var.consul_secret}"

  shared_services_security_groups = "${join(",",aws_security_group.shared_services.*.id)}"
  internet_access_security_groups = "${join(",",aws_security_group.internet_access.*.id)}"
  sso_security_groups             = "${join(",",aws_security_group.sso.*.id)}"

  public_subnets  = "${join(",", aws_subnet.public.*.id)}"
  private_subnets = "${join(",", aws_subnet.private.*.id)}"
  vpc_ids         = "${join(",", aws_vpc.nubis.*.id)}"

  nubis_sudo_groups = "${var.consul_sudo_groups}"
  nubis_user_groups = "${var.consul_user_groups}"

  mig = "${var.mig}"

  # Instance MFA (DUO)
  instance_mfa = "${var.instance_mfa}"
}

# XXX: This assumes it's going in the first region

resource "aws_iam_role_policy_attachment" "ci" {
  count      = "${var.enabled * var.enable_ci * ((1 + signum(index(concat(split(",", var.aws_regions), list(var.aws_region)),var.aws_region))) % 2 )}"
  role       = "${module.ci.iam_role}"
  policy_arn = "${element(aws_iam_policy.credstash.*.arn, 0)}"
}

# XXX: This assumes it's going in the first arena of the first region
module "ci" {
  source = "github.com/nubisproject/nubis-ci//nubis/terraform?ref=v2.4.2"

  enabled = "${var.enabled * var.enable_ci * ((1 + signum(index(concat(split(",", var.aws_regions), list(var.aws_region)),var.aws_region))) % 2 )}"

  arena  = "${element(var.arenas, 0)}"
  region = "${var.aws_region}"

  credstash_key = "${module.meta.CredstashKeyID}"

  key_name          = "${var.ssh_key_name}"
  nubis_version     = "${coalesce(lookup(var.ci, "version"), var.nubis_version)}"
  technical_contact = "${var.technical_contact}"

  nubis_domain = "${var.nubis_domain}"
  zone_id      = "${module.meta.HostedZoneId}"

  vpc_id = "${element(concat(aws_vpc.nubis.*.id, list("")), 0)}"

  # XXX: Only first 3
  private_subnets = "${element(concat(aws_subnet.private.*.id,list("")), 0)},${element(concat(aws_subnet.private.*.id, list("")), 1)},${element(concat(aws_subnet.private.*.id,list("")), 2)}"
  public_subnets  = "${element(concat(aws_subnet.public.*.id,list("")), 0)},${element(concat(aws_subnet.public.*.id, list("")), 1)},${element(concat(aws_subnet.public.*.id,list("")), 2)}"

  internet_security_group_id        = "${element(concat(aws_security_group.internet_access.*.id, list("")), 0)}"
  shared_services_security_group_id = "${element(concat(aws_security_group.shared_services.*.id, list("")), 0)}"
  ssh_security_group_id             = "${element(concat(aws_security_group.ssh.*.id, list("")), 0)}"
  monitoring_security_group_id      = "${element(concat(aws_security_group.monitoring.*.id, list("")), 0)}"
  sso_security_group_id             = "${element(concat(aws_security_group.sso.*.id, list("")), 0)}"

  domain = "${var.nubis_domain}"

  account_name = "${var.account_name}"

  project          = "${lookup(var.ci, "project")}"
  git_repo         = "${lookup(var.ci, "git_repo")}"
  slack_domain     = "${lookup(var.ci, "slack_domain")}"
  slack_channel    = "${lookup(var.ci, "slack_channel")}"
  slack_token      = "${lookup(var.ci, "slack_token")}"
  newrelic_api_key = "${lookup(var.ci, "newrelic_api_key")}"

  admins = "${lookup(var.ci, "admins")}"

  email = "${var.technical_contact}"

  nubis_sudo_groups = "${lookup(var.ci, "sudo_groups")}"
  nubis_user_groups = "${lookup(var.ci, "user_groups")}"

  instance_type     = "${lookup(var.ci, "instance_type")}"
  root_storage_size = "${lookup(var.ci, "root_storage_size")}"

  consul_acl_token = "${module.consul.master_acl_token}"
}

module "user_management" {
  source = "user_management"

  # set enabled to '1' only if enabled and if we are in the first configured region, yeah, I know.
  enabled = "${var.enabled * var.enable_user_management_iam * ( 1 + signum(index(concat(split(",", var.aws_regions), list(var.aws_region)),var.aws_region)) % 2 )}"

  region        = "${var.aws_region}"
  nubis_version = "${var.nubis_version}"
  account_name  = "${var.account_name}"

  credstash_key = "${module.meta.CredstashKeyID}"
  credstash_db  = "${module.meta.CredstashDynamoDB}"

  # user management
  user_management_smtp_from_address  = "${var.user_management_smtp_from_address}"
  user_management_smtp_username      = "${var.user_management_smtp_username}"
  user_management_smtp_password      = "${var.user_management_smtp_password}"
  user_management_smtp_host          = "${var.user_management_smtp_host}"
  user_management_smtp_port          = "${var.user_management_smtp_port}"
  user_management_ldap_server        = "${var.user_management_ldap_server}"
  user_management_ldap_port          = "${var.user_management_ldap_port}"
  user_management_ldap_base_dn       = "${var.user_management_ldap_base_dn}"
  user_management_ldap_bind_user     = "${var.user_management_ldap_bind_user}"
  user_management_ldap_bind_password = "${var.user_management_ldap_bind_password}"
  user_management_tls_cert           = "${var.user_management_tls_cert}"
  user_management_tls_key            = "${var.user_management_tls_key}"
  user_management_sudo_groups        = "${var.user_management_sudo_groups}"
  user_management_user_groups        = "${var.user_management_user_groups}"
}

#XXX: outputs:

#tunnel1_address

#tunnel1_preshared_key

#tunnel2_address

#tunnel2_preshared_key

module "vpn" {
  source = "github.com/nubisproject/nubis-terraform-vpn?ref=v2.4.0"

  enabled           = "${var.enabled * var.enable_vpn}"
  region            = "${var.aws_region}"
  arenas            = "${var.arenas}"
  account_name      = "${var.account_name}"
  technical_contact = "${var.technical_contact}"

  vpc_id                 = "${join(",", aws_vpc.nubis.*.id)}"
  vpn_bgp_asn            = "${var.vpn_bgp_asn}"
  ipsec_target           = "${var.ipsec_target}"
  destination_cidr_block = "${var.vpn_destination_cidr_block}"
  private_route_table_id = "${join(",", aws_route_table.private.*.id)}"
  public_route_table_id  = "${join(",", aws_route_table.public.*.id)}"
  output_config          = "${var.vpn_output_config}"
}

module "kube-image" {
  source        = "github.com/nubisproject/nubis-terraform//images?ref=v2.4.0"
  region        = "${var.aws_region}"
  image_version = "${coalesce(var.kubernetes_image_version, var.nubis_version)}"
  project       = "nubis-kubernetes"
}

# FIXME: will only work once vpc and public state is created
module "kubnernetes" {
  source = "github.com/nubisproject/nubis-kubernetes//nubis/terraform?ref=v2.4.0"

  enabled      = "${var.enabled * var.enable_kubernetes}"
  region       = "${var.aws_region}"
  arena        = "${var.arenas[0]}"
  environment  = "deploy"
  service_name = "kubernetes"
  account      = "${var.account_name}"
  ami          = "${module.kube-image.image_id}"

  kubernetes_master_type  = "${var.kubernetes_master_type}"
  kubernetes_node_type    = "${var.kubernetes_node_type}"
  kubernetes_node_minimum = "${var.kubernetes_node_minimum}"
}

# Create a proxy discovery VPC DNS zone
resource "aws_route53_zone" "proxy" {
  count = "${var.enabled * length(var.arenas)}"
  name  = "proxy.${element(var.arenas, count.index)}.${var.aws_region}.${var.account_name}.${var.nubis_domain}"

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index)}"

  tags {
    Arena            = "${element(var.arenas, count.index)}"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
  }
}

# Create a proxy discovery VPC DNS record for bootstrap proxy access
resource "aws_route53_record" "proxy" {
  count   = "${var.enabled * var.enable_nat * length(var.arenas)}"
  zone_id = "${element(aws_route53_zone.proxy.*.zone_id, count.index)}"
  name    = "proxy.${element(var.arenas, count.index)}.${var.aws_region}.${var.account_name}.${var.nubis_domain}"

  type = "A"

  alias {
    name                   = "${element(aws_elb.proxy.*.dns_name, count.index)}"
    zone_id                = "${element(aws_elb.proxy.*.zone_id, count.index)}"
    evaluate_target_health = false
  }
}

## Create a new load balancer
resource "aws_elb" "proxy" {
  count = "${var.enabled * var.enable_nat * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  name = "proxy-elb-${element(var.arenas, count.index)}"

  #XXX: Fugly, assumes 3 subnets per arenas, bad assumption, but valid ATM
  subnets = [
    "${element(aws_subnet.public.*.id, 3*count.index)}",
    "${element(aws_subnet.public.*.id, 3*count.index+1)}",
    "${element(aws_subnet.public.*.id, 3*count.index+2)}",
  ]

  # This is an internal ELB, only accessible form inside the VPC
  internal = true

  listener {
    instance_port     = 3128
    instance_protocol = "tcp"
    lb_port           = 3128
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:3128"
    interval            = 60
  }

  cross_zone_load_balancing = true

  security_groups = [
    "${element(aws_security_group.proxy.*.id, count.index)}",
  ]

  tags = {
    Name   = "elb-proxy-${element(var.arenas, count.index)}"
    Region = "${var.aws_region}"
    Arena  = "${element(var.arenas, count.index)}"
  }
}

resource "aws_security_group" "proxy" {
  count = "${var.enabled * var.enable_nat * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  name        = "elb-proxy-${element(var.arenas, count.index)}"
  description = "Allow inbound traffic for Squid in ${element(var.arenas, count.index)}"

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index)}"

  ingress {
    from_port = 3128
    to_port   = 3128
    protocol  = "tcp"

    security_groups = [
      "${element(aws_security_group.internet_access.*.id, count.index)}",
    ]
  }

  # Put back Amazon Default egress all rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name   = "elb-proxy-${element(var.arenas, count.index)}"
    Region = "${var.aws_region}"
    Arena  = "${element(var.arenas, count.index)}"
  }
}

resource "aws_eip" "nat" {
  # We enable this if consul AND/OR nat is enabled
  count = "${var.enabled * signum(var.enable_consul + var.enable_nat) * 2 * length(var.arenas)}"

  vpc = true

  lifecycle {
    create_before_destroy = true
  }
}

provider "aws" {
  version = "~> 1"
  region  = "${var.aws_state_region}"
  alias   = "public-state"
}

resource "aws_s3_bucket_object" "public_state" {
  provider     = "aws.public-state"
  count        = "${length(var.arenas)}"
  bucket       = "${var.public_state_bucket}"
  content_type = "text/json"
  key          = "aws/${var.aws_region}/${element(var.arenas, count.index)}.tfstate"

  content = <<EOF
{
    "version": 1,
    "serial": 0,
    "modules": [
        {
            "path": [
                "root"
            ],
            "outputs": {
              "nubis_version": ${jsonencode(var.nubis_version)},
              "nubis_domain": ${jsonencode(var.nubis_domain)},
              "region": ${jsonencode(var.aws_region)},
              "regions": ${jsonencode(var.aws_regions)},
              "arena": "${element(var.arenas, count.index)}",
              "network_cidr" : "${element(var.arenas_networks, count.index + (3 * index(concat(split(",",var.aws_regions), list(var.aws_region)), var.aws_region)) )}",
              "public_network_cidr" : "${cidrsubnet(element(var.arenas_networks, count.index + (3 * index(concat(split(",",var.aws_regions), list(var.aws_region)), var.aws_region)) ),1 , 0)}",
              "private_network_cidr" : "${cidrsubnet(element(var.arenas_networks, count.index + (3 * index(concat(split(",",var.aws_regions), list(var.aws_region)), var.aws_region)) ), 1, 1 )}",
              "availability_zones": "${join(",",data.aws_availability_zones.available.names)}",
              "delegation_set_id": ${jsonencode(var.route53_delegation_set)},
              "master_zone_id": ${jsonencode(var.route53_master_zone_id)},
              "hosted_zone_name": ${jsonencode(module.meta.HostedZoneName)},
              "hosted_zone_id": ${jsonencode(module.meta.HostedZoneId)},
              "vpc_id": ${jsonencode(element(concat(aws_vpc.nubis.*.id, list("")),count.index))},
              "account_id": ${jsonencode(data.aws_caller_identity.current.account_id)},
              "rds_mysql_parameter_group": ${jsonencode(module.meta.NubisMySQL56ParameterGroup)},
              "monitoring_security_group" : ${jsonencode(element(concat(aws_security_group.monitoring.*.id, list("")),count.index))},
              "shared_services_security_group": ${jsonencode(element(concat(aws_security_group.shared_services.*.id, list("")),count.index))},
              "internet_access_security_group": ${jsonencode(element(concat(aws_security_group.internet_access.*.id, list("")),count.index))},
              "ssh_security_group": ${jsonencode(element(concat(aws_security_group.ssh.*.id, list("")),count.index))},
              "sso_security_group": ${jsonencode(element(concat(aws_security_group.sso.*.id, list("")),count.index))},
              "instance_security_groups": "${element(concat(aws_security_group.shared_services.*.id, list("")),count.index)},${element(concat( aws_security_group.internet_access.*.id, list("")),count.index)},${element(concat(aws_security_group.ssh.*.id, list("")),count.index)}",
              "private_subnets": "${element(concat(aws_subnet.private.*.id, list("")), (3*count.index) + 0)},${element(concat(aws_subnet.private.*.id, list("")), (3*count.index) + 1)},${element(concat(aws_subnet.private.*.id, list("")), (3*count.index) + 2)}",
              "public_subnets": "${element(concat(aws_subnet.public.*.id, list("")), (3*count.index) + 0)},${element(concat(aws_subnet.public.*.id, list("")), (3*count.index) + 1)},${element(concat(aws_subnet.public.*.id, list("")), (3*count.index) + 2)}",
              "access_logging_bucket": ${jsonencode(element(concat(split(",", module.fluent-collector.logging_buckets), list("")),count.index))},
              "default_ssl_certificate": "${module.meta.DefaultServerCertificate}",
              "apps_state_bucket": "${var.apps_state_bucket}",
              "dummy": "dummy"
            },
            "resources": {}
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "user_managment" {
  count      = "${var.enabled * var.enable_user_management_consul * length(var.arenas)}"
  role       = "${element(concat(aws_iam_role.user_management.*.id, list("")), count.index)}"
  policy_arn = "${element(aws_iam_policy.credstash.*.arn, count.index)}"
}

resource "aws_iam_role" "user_management" {
  count = "${var.enabled * var.enable_user_management_consul * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  name = "user_management-${var.aws_region}-${element(var.arenas, count.index)}"

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

resource "aws_iam_role_policy" "user_management" {
  count = "${var.enabled * var.enable_user_management_consul * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  name = "user_management-${var.aws_region}-${element(var.arenas, count.index)}"
  role = "${element(aws_iam_role.user_management.*.id, count.index)}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:*"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Sid": "LambdaVPCAccess",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "ec2:CreateNetworkInterface",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DeleteNetworkInterface"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_lambda_function" "user_management" {
  count = "${var.enabled * var.enable_user_management_consul * length(var.arenas)}"

  depends_on = [
    "aws_iam_role_policy.user_management",
  ]

  function_name = "user_management-${element(var.arenas, count.index)}"
  s3_bucket     = "nubis-stacks-${var.aws_region}"
  s3_key        = "${var.nubis_version}/lambda/nubis-lambda-user-management.zip"
  role          = "${element(aws_iam_role.user_management.*.arn, count.index)}"
  handler       = "index.handler"
  description   = "Queries LDAP and inserts user into consul and create and delete IAM users"
  memory_size   = 128
  runtime       = "nodejs8.10"
  timeout       = "30"

  vpc_config = {
    subnet_ids = [
      "${element(aws_subnet.private.*.id, 3*count.index)}",
      "${element(aws_subnet.private.*.id, 3*count.index+1)}",
      "${element(aws_subnet.private.*.id, 3*count.index+2)}",
    ]

    security_group_ids = [
      "${element(aws_security_group.shared_services.*.id, count.index)}",
      "${element(aws_security_group.internet_access.*.id, count.index)}",
      "${element(aws_security_group.ldap.*.id, count.index)}",
    ]
  }
}

resource "aws_security_group" "ldap" {
  count = "${var.enabled * length(var.arenas)}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id      = "${element(aws_vpc.nubis.*.id, count.index)}"
  name_prefix = "MocoLdapOutbound-${element(var.arenas, count.index)}-"
  description = "Allow outbound ldap connection to moco ldap"

  egress {
    from_port = "636"
    to_port   = "636"
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags {
    Name             = "MocoLdapOutboundSecurityGroup"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    Arena            = "${element(var.arenas, count.index)}"
  }
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  count = "${var.enabled * var.enable_user_management_consul * length(var.arenas)}"

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${element(aws_lambda_function.user_management.*.function_name, count.index)}"
  principal     = "events.amazonaws.com"
  source_arn    = "${element(aws_cloudwatch_event_rule.user_management_event_consul.*.arn, count.index)}"
}

resource "aws_cloudwatch_event_rule" "user_management_event_consul" {
  count = "${var.enabled * var.enable_user_management_consul * length(var.arenas)}"
  name  = "user_management-consul-${element(var.arenas, count.index)}"

  description         = "Sends payload over a periodic time"
  schedule_expression = "${var.user_management_rate}"
}

resource "aws_cloudwatch_event_target" "user_management_consul" {
  count = "${var.enabled * var.enable_user_management_consul * length(var.arenas)}"

  rule = "${element(aws_cloudwatch_event_rule.user_management_event_consul.*.name, count.index)}"
  arn  = "${element(aws_lambda_function.user_management.*.arn, count.index)}"

  input = <<EOF
{
    "command": "./nubis-user-management",
    "args": [
        "-execType=consul",
        "-useDynamo=true",
        "-region=${var.aws_region}",
        "-arena=${element(var.arenas, count.index)}",
        "-service=nubis",
        "-accountName=${var.account_name}",
        "-consulDomain=${var.nubis_domain}",
        "-consulPort=80",
        "-key=nubis/${element(var.arenas, count.index)}/user-sync/config",
        "-lambda=true"
    ]
}
EOF
}

data template_file "user_management_config" {
  count    = "${var.enabled * var.enable_user_management_consul * length(var.arenas)}"
  template = "${file("${path.module}/user_management.yml.tmpl")}"

  vars {
    region               = "${var.aws_region}"
    arena                = "${element(var.arenas, count.index)}"
    smtp_from_address    = "${var.user_management_smtp_from_address}"
    smtp_username        = "${var.user_management_smtp_username}"
    smtp_password        = "${var.user_management_smtp_password}"
    smtp_host            = "${var.user_management_smtp_host}"
    smtp_port            = "${var.user_management_smtp_port}"
    ldap_server          = "${var.user_management_ldap_server}"
    ldap_port            = "${var.user_management_ldap_port}"
    ldap_base_dn         = "${var.user_management_ldap_base_dn}"
    ldap_bind_user       = "${var.user_management_ldap_bind_user}"
    ldap_bind_password   = "${var.user_management_ldap_bind_password}"
    tls_cert             = "${replace(file("${path.cwd}/${var.user_management_tls_cert}"), "/(.*)\\n/", "    $1\n")}"
    tls_key              = "${replace(file("${path.cwd}/${var.user_management_tls_key}"), "/(.*)\\n/", "    $1\n")}"
    sudo_user_ldap_group = "${replace(var.user_management_sudo_groups, ",", "|")}"
    users_ldap_group     = "${replace(var.user_management_user_groups, ",", "|")}"
  }
}

resource "null_resource" "user_management_unicreds" {
  count = "${var.enabled * var.enable_user_management_consul * length(var.arenas)}"

  triggers {
    region            = "${var.aws_region}"
    arena             = "${element(var.arenas, count.index)}"
    context           = "-E region:${var.aws_region} -E arena:${element(var.arenas, count.index)} -E service:nubis"
    rendered_template = "${element(data.template_file.user_management_config.*.rendered, count.index)}"
    unicreds          = "unicreds -k ${module.meta.CredstashKeyID} -r ${var.aws_region} put-file nubis/${element(var.arenas, count.index)}"
    unicreds_rm       = "unicreds -k ${module.meta.CredstashKeyID} -r ${var.aws_region} delete nubis/${element(var.arenas, count.index)}"
  }

  provisioner "local-exec" {
    command = "echo '${element(data.template_file.user_management_config.*.rendered, count.index)}' | ${self.triggers.unicreds}/user-sync/config /dev/stdin ${self.triggers.context}"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "${self.triggers.unicreds_rm}/user-sync/config"
  }
}
