provider "aws" {
  profile = "${var.aws_profile}"
  region  = "${var.aws_region}"
}

resource "aws_key_pair" "nubis" {
  count = "${var.enabled}"

  lifecycle {
    create_before_destroy = true
  }

  key_name   = "${var.ssh_key_name}"
  public_key = "${var.nubis_ssh_key}"

}

resource "aws_iam_policy" "credstash" {
  count = "${var.enabled * length(split(",", var.environments))}"

  name        = "credstash-${element(split(",",var.environments), count.index)}-${var.aws_region}"
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
                  "kms:EncryptionContext:environment": "${element(split(",",var.environments), count.index)}",
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

resource "aws_iam_role_policy" "lambda" {
  count = "${var.enabled}"

  lifecycle {
    create_before_destroy = true
  }

  name = "lambda_policy-${var.aws_region}"
  role = "${aws_iam_role.lambda.id}"

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
                  "Effect": "Allow",
                  "Action": [
                    "cloudformation:DescribeStacks",
                    "cloudformation:DescribeStackResources"
                  ],
                  "Resource": "*"
                }
  ]
}
EOF
}

resource "aws_iam_role" "lambda" {
  #  count = "${var.enabled}"
  lifecycle {
    create_before_destroy = true
  }

  name = "lambda-${var.aws_region}"

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

resource "aws_cloudformation_stack" "dummy-vpc" {
  count = "${var.enabled * var.enable_stack_compat}"

  lifecycle {
    create_before_destroy = true
  }

  name = "${var.aws_region}-vpc"

  template_url = "http://nubis-stacks-${var.aws_region}.s3.amazonaws.com/${var.nubis_version}/vpc/dummy.template"

  parameters = {
    StacksVersion = "${var.nubis_version}"
    ServiceName   = "${var.account_name}"

    HostedZoneId               = "${module.meta.HostedZoneId}"
    HostedZoneName             = "${module.meta.HostedZoneName}"
    DefaultServerCertificate   = "${module.meta.DefaultServerCertificate}"
    NubisMySQL56ParameterGroup = "${module.meta.NubisMySQL56ParameterGroup}"

    VpcIdEnv1 = "${element(aws_vpc.nubis.*.id,0)}"
    VpcIdEnv2 = "${element(aws_vpc.nubis.*.id,1)}"
    VpcIdEnv3 = "${element(aws_vpc.nubis.*.id,2)}"

    SharedServicesSecurityGroupIdEnv1 = "${element(aws_security_group.shared_services.*.id,0)}"
    SharedServicesSecurityGroupIdEnv2 = "${element(aws_security_group.shared_services.*.id,1)}"
    SharedServicesSecurityGroupIdEnv3 = "${element(aws_security_group.shared_services.*.id,2)}"
    InternetAccessSecurityGroupIdEnv1 = "${element(aws_security_group.internet_access.*.id,0)}"
    InternetAccessSecurityGroupIdEnv2 = "${element(aws_security_group.internet_access.*.id,1)}"
    InternetAccessSecurityGroupIdEnv3 = "${element(aws_security_group.internet_access.*.id,2)}"
    SshSecurityGroupIdEnv1            = "${element(aws_security_group.ssh.*.id,0)}"
    SshSecurityGroupIdEnv2            = "${element(aws_security_group.ssh.*.id,1)}"
    SshSecurityGroupIdEnv3            = "${element(aws_security_group.ssh.*.id,2)}"

    AccessLoggingBucketEnv1 = "${element(split(",", module.fluent-collector.logging_buckets), 0)}"
    AccessLoggingBucketEnv2 = "${element(split(",", module.fluent-collector.logging_buckets), 1)}"
    AccessLoggingBucketEnv3 = "${element(split(",", module.fluent-collector.logging_buckets), 2)}"

    PublicSubnetAZ1Env1 = "${element(aws_subnet.public.*.id, 0)}"
    PublicSubnetAZ2Env1 = "${element(aws_subnet.public.*.id, 1)}"
    PublicSubnetAZ3Env1 = "${element(aws_subnet.public.*.id, 2)}"

    PublicSubnetAZ1Env2 = "${element(aws_subnet.public.*.id, 3)}"
    PublicSubnetAZ2Env2 = "${element(aws_subnet.public.*.id, 4)}"
    PublicSubnetAZ3Env2 = "${element(aws_subnet.public.*.id, 5)}"

    PublicSubnetAZ1Env3 = "${element(aws_subnet.public.*.id, 6)}"
    PublicSubnetAZ2Env3 = "${element(aws_subnet.public.*.id, 7)}"
    PublicSubnetAZ3Env3 = "${element(aws_subnet.public.*.id, 8)}"

    PrivateSubnetAZ1Env1 = "${element(aws_subnet.private.*.id, 0)}"
    PrivateSubnetAZ2Env1 = "${element(aws_subnet.private.*.id, 1)}"
    PrivateSubnetAZ3Env1 = "${element(aws_subnet.private.*.id, 2)}"

    PrivateSubnetAZ1Env2 = "${element(aws_subnet.private.*.id, 3)}"
    PrivateSubnetAZ2Env2 = "${element(aws_subnet.private.*.id, 4)}"
    PrivateSubnetAZ3Env2 = "${element(aws_subnet.private.*.id, 5)}"

    PrivateSubnetAZ1Env3 = "${element(aws_subnet.private.*.id, 6)}"
    PrivateSubnetAZ2Env3 = "${element(aws_subnet.private.*.id, 7)}"
    PrivateSubnetAZ3Env3 = "${element(aws_subnet.private.*.id, 8)}"

    # AZs
    PrivateAvailabilityZone1 = "${element(split(",",aws_cloudformation_stack.availability_zones.outputs["AvailabilityZones"]), 0)}"
    PrivateAvailabilityZone2 = "${element(split(",",aws_cloudformation_stack.availability_zones.outputs["AvailabilityZones"]), 1)}"
    PrivateAvailabilityZone3 = "${element(split(",",aws_cloudformation_stack.availability_zones.outputs["AvailabilityZones"]), 2)}"
  }
}

#XXX: This is because it's fed to a module input, so it can't be undefined
#XXX: even in regions where enabled=0, unfortunately
resource "aws_lambda_function" "UUID" {
  #count = "${var.enabled}"

  lifecycle {
    create_before_destroy = true
  }

  function_name = "UUID"
  s3_bucket     = "nubis-stacks-${var.aws_region}"
  s3_key        = "${var.nubis_version}/lambda/UUID.zip"
  handler       = "index.handler"
  description   = "Generate UUIDs for use in Cloudformation stacks"
  memory_size   = 128
  runtime       = "nodejs4.3"
  timeout       = "10"
  role          = "${aws_iam_role.lambda.arn}"
}

resource "aws_lambda_function" "LookupStackOutputs" {
  count         = "${var.enabled * var.enable_stack_compat}"
  function_name = "LookupStackOutputs"
  s3_bucket     = "nubis-stacks-${var.aws_region}"
  s3_key        = "${var.nubis_version}/lambda/LookupStackOutputs.zip"
  handler       = "index.handler"
  description   = "Gather outputs from Cloudformation stacks to be used in other Cloudformation stacks"
  memory_size   = 128
  runtime       = "nodejs4.3"
  timeout       = "10"
  role          = "${aws_iam_role.lambda.arn}"
}

resource "aws_lambda_function" "LookupNestedStackOutputs" {

  count         = "${var.enabled * var.enable_stack_compat}"
  function_name = "LookupNestedStackOutputs"
  s3_bucket     = "nubis-stacks-${var.aws_region}"
  s3_key        = "${var.nubis_version}/lambda/LookupNestedStackOutputs.zip"
  handler       = "index.handler"
  description   = "Gather outputs from Cloudformation enviroment specific nested stacks to be used in other Cloudformation stacks"
  memory_size   = 128
  runtime       = "nodejs4.3"
  timeout       = "10"
  role          = "${aws_iam_role.lambda.arn}"
}

module "meta" {
  source = "../meta"

  enabled = "${var.enabled}"

  aws_profile = "${var.aws_profile}"
  aws_region  = "${var.aws_region}"

  nubis_version     = "${var.nubis_version}"
  nubis_domain      = "${var.nubis_domain}"
  technical_contact = "${var.technical_contact}"

  service_name = "${var.account_name}"

  route53_delegation_set = "${var.route53_delegation_set}"
  route53_master_zone_id = "${var.route53_master_zone_id}"
}

resource "aws_vpc" "nubis" {
  count = "${var.enabled * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  # index(split(",",var.aws_regions), var.aws_region)
  # is the index of the current region, starting at 0
  # So the correct grouping of subnets is count.index + ( 3 * region-index )
  cidr_block = "${element(split(",",var.environments_networks), count.index + (3 * index(split(",",var.aws_regions), var.aws_region)) )}"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name             = "${var.aws_region}-${element(split(",",var.environments), count.index)}-vpc"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    Environment      = "${element(split(",",var.environments), count.index)}"
  }
}

resource "aws_main_route_table_association" "public" {
  count = "${var.enabled * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id         = "${element(aws_vpc.nubis.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.public.*.id, count.index)}"
}

resource "aws_security_group" "monitoring" {
  count = "${var.enabled * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index)}"

  name_prefix = "MonitoringSecurityGroup-${element(split(",",var.environments), count.index)}-"
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
    Environment      = "${element(split(",",var.environments), count.index)}"
  }
}

resource "aws_security_group" "ssh" {
  count = "${var.enabled * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index)}"

  name_prefix = "SshSecurityGroup-${element(split(",",var.environments), count.index)}-"
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
    Environment      = "${element(split(",",var.environments), count.index)}"
  }
}

resource "aws_security_group" "internet_access" {
  count = "${var.enabled * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index)}"

  name_prefix = "InternetAccessSecurityGroup-${element(split(",",var.environments), count.index)}-"
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
    Environment      = "${element(split(",",var.environments), count.index)}"
  }
}

resource "aws_security_group" "nat" {
  count = "${var.enabled * var.enable_nat * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index)}"

  name_prefix = "NATSecurityGroup-${element(split(",",var.environments), count.index)}"
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

  #XXX
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "${var.my_ip}",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name             = "NATSecurityGroup-${element(split(",",var.environments), count.index)}"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    Environment      = "${element(split(",",var.environments), count.index)}"
  }
}

resource "aws_security_group" "shared_services" {
  count = "${var.enabled * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index)}"

  name        = "SharedServicesSecurityGroup-${element(split(",",var.environments), count.index)}"
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
    to_port   = 9110
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
    Environment      = "${element(split(",",var.environments), count.index)}"
  }
}

resource "aws_cloudformation_stack" "availability_zones" {
  count = "${var.enabled}"
  name  = "availability-zones"

  lifecycle {
    create_before_destroy = true
  }

  template_body = "${file("${path.module}/availability-zones.json")}"
}

# ATM, we just create public subnets for each environment in the first 3 AZs
resource "aws_subnet" "public" {
  count = "${3 * var.enabled * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index / 3)}"

  availability_zone = "${element(split(",",aws_cloudformation_stack.availability_zones.outputs["AvailabilityZones"]), count.index % 3 )}"

  cidr_block = "${cidrsubnet(element(aws_vpc.nubis.*.cidr_block, count.index / 3), 3, count.index % 3 )}"

  tags {
    Name             = "PublicSubnet-${element(split(",",var.environments), count.index / 3)}-AZ${(count.index % 3 ) + 1}"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    Environment      = "${element(split(",",var.environments), count.index / 3)}"
  }
}

# ATM, we just create private subnets for each environment in the first 3 AZs
resource "aws_subnet" "private" {
  count = "${3 * var.enabled * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index / 3)}"

  availability_zone = "${element(split(",",aws_cloudformation_stack.availability_zones.outputs["AvailabilityZones"]), count.index % 3 )}"

  cidr_block = "${cidrsubnet(element(aws_vpc.nubis.*.cidr_block, count.index / 3), 3, (count.index % 3) + 3 )}"

  tags {
    Name             = "PrivateSubnet-${element(split(",",var.environments), count.index / 3)}-AZ${(count.index % 3 ) + 1}"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    Environment      = "${element(split(",",var.environments), count.index / 3)}"
  }
}

resource "aws_route_table_association" "public" {
  count = "${3 * var.enabled * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.public.*.id, count.index / 3)}"
}

resource "aws_internet_gateway" "nubis" {
  count = "${var.enabled * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index)}"

  tags {
    Name             = "InternetGateway-${element(split(",",var.environments), count.index)}"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    Environment      = "${element(split(",",var.environments), count.index)}"
  }
}

resource "aws_route_table" "public" {
  count = "${var.enabled * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index)}"

  tags {
    Name             = "PublicRoute-${element(split(",",var.environments), count.index)}"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    Environment      = "${element(split(",",var.environments), count.index)}"
  }
}

resource "aws_route" "public" {
  count = "${var.enabled * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  route_table_id = "${element(aws_route_table.public.*.id, count.index)}"

  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${element(aws_internet_gateway.nubis.*.id, count.index)}"

}

#resource "aws_route" "private" {

#  count = "${3 * var.enabled * length(split(",", var.environments))}"

#

#  lifecycle {

#    create_before_destroy = true

#  }

#

#  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"

#

#  destination_cidr_block = "0.0.0.0/0"

##  network_interface_id   = "${element(aws_network_interface.private-nat.*.id, count.index)}"

#}

resource "aws_route_table" "private" {
  count = "${3 * var.enabled * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index / 3)}"

  tags {
    Name             = "PrivateRoute-${element(split(",",var.environments), count.index/3)}-AZ${(count.index % 3 ) + 1}"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    Environment      = "${element(split(",",var.environments), count.index)}"
    RouteType        = "private"
  }
}

resource "aws_route_table_association" "private" {
  count = "${3 * var.enabled * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

resource "aws_network_interface" "private-nat" {
  count = "${3 * var.enabled * var.enable_nat * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
    #ignore_changes        = ["attachment"]
  }

  subnet_id = "${element(aws_subnet.private.*.id, count.index)}"

  source_dest_check = false

  tags {
    Name = "NatENI-${element(split(",",var.environments), count.index/3)}-AZ${(count.index % 3 ) + 1}"

    # Found by the nat instance doing --filter Name=tag-value,Values=nubis-nat-eni-stage Name=availability-zone,Values=$MY_AZ
    Autodiscover     = "nubis-nat-eni-${element(split(",",var.environments), count.index/3)}"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    Environment      = "${element(split(",",var.environments), count.index)}"
  }

  security_groups = [
    "${element(aws_security_group.shared_services.*.id, count.index / 3 )}",
    "${element(aws_security_group.nat.*.id, count.index / 3 )}",
  ]
}

module "nat-image" {
  source = "../images"

  region = "${var.aws_region}"
  version = "${var.nubis_version}"
  project = "nubis-nat"
}

variable nat_side {
  default = {
    "0" = "left"
    "1" = "right"
  }
}

resource "aws_autoscaling_group" "nat" {
  count = "${var.enabled * 2 * var.enable_nat * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  name = "nubis-nat-${element(split(",",var.environments), count.index/2)}-${lookup(var.nat_side, count.index % 2)} (${element(aws_launch_configuration.nat.*.name, count.index)})"

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
  health_check_type = "ELB"
  health_check_grace_period = 300

  launch_configuration = "${element(aws_launch_configuration.nat.*.name, count.index)}"

  tag {
    key                 = "Name"
    value               = "NAT (${var.nubis_version}) for ${var.account_name} in ${element(split(",",var.environments), count.index/2)}/${lookup(var.nat_side,count.index%2)}"
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
    key                 = "Environment"
    value               = "${element(split(",",var.environments), count.index/2)}"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "nat" {
  count = "${var.enabled * 2 * var.enable_nat * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  name_prefix = "nubis-nat-${element(split(",",var.environments), count.index/2 )}-${lookup(var.nat_side, count.index % 2)}-"

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
NUBIS_ENVIRONMENT='${element(split(",",var.environments), count.index/2)}'
NUBIS_DOMAIN='${var.nubis_domain}'
NUBIS_MIGRATE='1'
NUBIS_ACCOUNT='${var.account_name}'
NUBIS_PURPOSE='Nat Instance'
NUBIS_NAT_EIP='${element(aws_eip.nat.*.id, count.index)}'
NUBIS_SUDO_GROUPS="${var.nat_sudo_groups}"
NUBIS_USER_GROUPS="${var.nat_user_groups}"
USER_DATA
}

resource "aws_iam_role_policy_attachment" "nat" {
    count = "${var.enabled * var.enable_nat * length(split(",", var.environments))}"
    role = "${element(concat(aws_iam_role.nat.*.id, list("")), count.index)}"
    policy_arn = "${element(aws_iam_policy.credstash.*.arn, count.index)}"
}

resource "aws_iam_role" "nat" {
  count = "${var.enabled * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  path = "/nubis/"
  name = "nubis-nat-role-${element(split(",",var.environments), count.index)}-${var.aws_region}"

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
  count = "${var.enabled * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  name   = "nubis-nat-policy-${element(split(",",var.environments), count.index)}-${var.aws_region}"
  role   = "${element(aws_iam_role.nat.*.id, count.index)}"
  policy = "${file("${path.module}/nat-policy.json")}"
}

resource "aws_iam_instance_profile" "nat" {
  count = "${var.enabled * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  name  = "nubis-nat-profile-${element(split(",",var.environments), count.index)}-${var.aws_region}"
  roles = ["${element(aws_iam_role.nat.*.name, count.index)}"]
}

module "jumphost" {
  source = "github.com/nubisproject/nubis-jumphost//nubis/terraform?ref=master"

  enabled = "${var.enabled * var.enable_jumphost}"

  environments = "${var.environments}"
  aws_profile  = "${var.aws_profile}"
  aws_region   = "${var.aws_region}"

  key_name          = "${var.ssh_key_name}"
  nubis_version     = "${var.nubis_version}"
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
    count = "${var.enabled * var.enable_fluent * length(split(",", var.environments))}"
    role = "${element(split(",",module.fluent-collector.iam_roles), count.index)}"
    policy_arn = "${element(aws_iam_policy.credstash.*.arn, count.index)}"
}

module "fluent-collector" {
  source = "github.com/nubisproject/nubis-fluent-collector//nubis/terraform/multi?ref=master"

  enabled            = "${var.enabled * var.enable_fluent}"
  monitoring_enabled = "${var.enabled * var.enable_fluent * var.enable_monitoring}"

  environments   = "${var.environments}"
  aws_profile    = "${var.aws_profile}"
  aws_region     = "${var.aws_region}"
  aws_account_id = "${var.aws_account_id}"

  lambda_uuid_arn = "${aws_lambda_function.UUID.arn}"

  key_name          = "${var.ssh_key_name}"
  nubis_version     = "${var.nubis_version}"
  technical_contact = "${var.technical_contact}"

  zone_id = "${module.meta.HostedZoneId}"

  vpc_ids    = "${join(",", aws_vpc.nubis.*.id)}"
  subnet_ids = "${join(",", aws_subnet.private.*.id)}"

  internet_access_security_groups = "${join(",",aws_security_group.internet_access.*.id)}"
  shared_services_security_groups = "${join(",",aws_security_group.shared_services.*.id)}"
  ssh_security_groups             = "${join(",",aws_security_group.ssh.*.id)}"
  monitoring_security_groups      = "${join(",",aws_security_group.monitoring.*.id)}"

  nubis_domain = "${var.nubis_domain}"

  service_name = "${var.account_name}"

  credstash_key = "${module.meta.CredstashKeyID}"

  sqs_queues      = "${var.fluentd_sqs_queues}"
  sqs_access_keys = "${var.fluentd_sqs_access_keys}"
  sqs_secret_keys = "${var.fluentd_sqs_secret_keys}"
  sqs_regions     = "${var.fluentd_sqs_regions}"

  nubis_sudo_groups = "${var.fluentd_sudo_groups}"
  nubis_user_groups = "${var.fluentd_user_groups}"
}

resource "aws_iam_role_policy_attachment" "monitoring" {
    count = "${var.enabled * var.enable_monitoring * length(split(",", var.environments))}"
    role = "${element(split(",",module.monitoring.iam_roles), count.index)}"
    policy_arn = "${element(aws_iam_policy.credstash.*.arn, count.index)}"
}

module "monitoring" {
  source = "github.com/nubisproject/nubis-prometheus//nubis/terraform?ref=master"

  enabled = "${var.enabled * var.enable_monitoring}"

  environments = "${var.environments}"
  aws_profile  = "${var.aws_profile}"
  aws_region   = "${var.aws_region}"

  lambda_uuid_arn = "${aws_lambda_function.UUID.arn}"

  key_name          = "${var.ssh_key_name}"
  nubis_version     = "${var.nubis_version}"
  technical_contact = "${var.technical_contact}"

  vpc_ids    = "${join(",", aws_vpc.nubis.*.id)}"
  subnet_ids = "${join(",", aws_subnet.private.*.id)}"
  public_subnet_ids = "${join(",", aws_subnet.public.*.id)}"

  internet_access_security_groups = "${join(",",aws_security_group.internet_access.*.id)}"
  shared_services_security_groups = "${join(",",aws_security_group.shared_services.*.id)}"
  ssh_security_groups             = "${join(",",aws_security_group.ssh.*.id)}"
  monitoring_security_groups      = "${join(",",aws_security_group.monitoring.*.id)}"

  credstash_key            = "${module.meta.CredstashKeyID}"
  credstash_dynamodb_table = "${module.meta.CredstashDynamoDB}"

  nubis_domain = "${var.nubis_domain}"
  service_name = "${var.account_name}"
  zone_id      = "${module.meta.HostedZoneId}"

  slack_url             = "${var.monitoring_slack_url}"
  slack_channel         = "${var.monitoring_slack_channel}"
  notification_email    = "${var.monitoring_notification_email}"
  pagerduty_service_key = "${var.monitoring_pagerduty_service_key}"

  nubis_sudo_groups     = "${var.monitoring_sudo_groups}"
  nubis_user_groups     = "${var.monitoring_user_groups}"

  password              = "${var.monitoring_password}"
}

resource "aws_iam_role_policy_attachment" "consul" {
    count = "${var.enabled * var.enable_consul * length(split(",", var.environments))}"
    role = "${element(split(",",module.consul.iam_roles), count.index)}"
    policy_arn = "${element(aws_iam_policy.credstash.*.arn, count.index)}"
}

module "consul" {
  source = "../consul"

  enabled = "${var.enabled * var.enable_consul}"

  environments = "${var.environments}"

  aws_profile    = "${var.aws_profile}"
  aws_region     = "${var.aws_region}"
  aws_account_id = "${var.aws_account_id}"

  my_ip           = "${var.my_ip},${element(concat(aws_eip.nat.*.public_ip, list("")),0)}/32,${element(concat(aws_eip.nat.*.public_ip, list("")),1)}/32"
 
  lambda_uuid_arn = "${aws_lambda_function.UUID.arn}"

  key_name           = "${var.ssh_key_name}"
  nubis_version      = "${var.nubis_version}"
  vpc_ids            = "${join(",", aws_vpc.nubis.*.id)}"
  public_subnet_ids  = "${join(",", aws_subnet.public.*.id)}"
  private_subnet_ids = "${join(",", aws_subnet.private.*.id)}"

  internet_access_security_groups = "${join(",",aws_security_group.internet_access.*.id)}"
  shared_services_security_groups = "${join(",",aws_security_group.shared_services.*.id)}"
  ssh_security_groups             = "${join(",",aws_security_group.ssh.*.id)}"

  consul_secret            = "${var.consul_secret}"
  consul_master_acl_token  = "${var.consul_master_acl_token}"
  credstash_key            = "${module.meta.CredstashKeyID}"
  credstash_dynamodb_table = "${module.meta.CredstashDynamoDB}"
  zone_id                  = "${module.meta.HostedZoneId}"

  service_name = "${var.account_name}"

  datadog_api_key = "${var.datadog_api_key}"

  nubis_sudo_groups = "${var.consul_sudo_groups}"
  nubis_user_groups = "${var.consul_user_groups}"
}

module "ci-uuid" {
  source  = "../uuid"
  enabled = "${var.enabled}"

  aws_profile = "${var.aws_profile}"
  aws_region  = "${var.aws_region}"

  name = "ci"

  environments = "${element(split(",",var.environments), 0)}"

  lambda_uuid_arn = "${aws_lambda_function.UUID.arn}"
}

# XXX: This assumes it's going in the first environment, i.e. admin

resource "aws_iam_role_policy_attachment" "ci" {
    count = "${var.enabled * var.enable_ci * ((1 + signum(index(concat(split(",", var.aws_regions), list(var.aws_region)),var.aws_region))) % 2 )}"
    role = "${module.ci.iam_role}"
    policy_arn = "${element(aws_iam_policy.credstash.*.arn, 0)}"
}

module "ci" {
  source = "github.com/nubisproject/nubis-ci//nubis/terraform?ref=master"

  enabled = "${var.enabled * var.enable_ci * ((1 + signum(index(concat(split(",", var.aws_regions), list(var.aws_region)),var.aws_region))) % 2 )}"

  environment = "${element(split(",",var.environments), 0)}"
  aws_profile = "${var.aws_profile}"
  region      = "${var.aws_region}"

  credstash_key = "${module.meta.CredstashKeyID}"

  key_name          = "${var.ssh_key_name}"
  version           = "${coalesce(var.ci_version, var.nubis_version)}"
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

  domain = "${var.nubis_domain}"

  account_name = "${var.account_name}"

  project                    = "${var.ci_project}"
  git_repo                   = "${var.ci_git_repo}"
  github_oauth_client_secret = "${var.ci_github_oauth_client_secret}"
  github_oauth_client_id     = "${var.ci_github_oauth_client_id}"
  slack_domain               = "${var.ci_slack_domain}"
  slack_channel              = "${var.ci_slack_channel}"
  slack_token                = "${var.ci_slack_token}"

  admins                     = "${var.ci_admins}"

  s3_bucket_name = "ci-${var.ci_project}-${module.ci-uuid.uuids}"

  email = "${var.technical_contact}"

  nubis_sudo_groups = "${var.ci_sudo_groups}"
  nubis_user_groups = "${var.ci_user_groups}"
}

module "user_management" {
  source = "user_management"

  # set enabled to '1' only if enabled and if we are in the first configured region, yeah, I know.
  enabled = "${var.enabled * var.enable_user_management_iam * ( 1 + signum(index(concat(split(",", var.aws_regions), list(var.aws_region)),var.aws_region)) % 2 )}"

  region       = "${var.aws_region}"
  version      = "${var.nubis_version}"
  account_name = "${var.account_name}"

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

#XXX: Move to a module

#XXX: outputs:

#tunnel1_address

#tunnel1_preshared_key

#tunnel2_address

#tunnel2_preshared_key

resource "aws_vpn_gateway" "vpn_gateway" {
  count = "${var.enabled * var.enable_vpn * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index)}"

  tags {
    Name             = "${var.aws_region}-${element(split(",",var.environments), count.index)}-vpn-gateway"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    Environment      = "${element(split(",",var.environments), count.index)}"
  }
}

resource "aws_customer_gateway" "customer_gateway" {
  count = "${var.enabled * var.enable_vpn}"

  lifecycle {
    create_before_destroy = true
  }

  bgp_asn = "${var.vpn_bgp_asn}"

  ip_address = "${var.ipsec_target}"
  type       = "ipsec.1"

  tags {
    Name             = "${var.aws_region}-customer-gateway"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
  }
}

resource "aws_vpn_connection" "main" {
  count = "${var.enabled * var.enable_vpn * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  vpn_gateway_id      = "${element(aws_vpn_gateway.vpn_gateway.*.id, count.index)}"
  customer_gateway_id = "${aws_customer_gateway.customer_gateway.id}"
  type                = "${aws_customer_gateway.customer_gateway.type}"
  static_routes_only  = false

  tags {
    Name             = "${var.aws_region}-${element(split(",",var.environments), count.index)}-vpn"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    Environment      = "${element(split(",",var.environments), count.index)}"
  }
}

resource "aws_route" "vpn-public" {
  count = "${var.enabled * var.enable_vpn * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  route_table_id = "${element(aws_route_table.public.*.id, count.index)}"

  destination_cidr_block = "10.0.0.0/8"
  gateway_id             = "${element(aws_vpn_gateway.vpn_gateway.*.id, count.index)}"

}

resource "aws_route" "vpn-private" {
  count = "${3 * var.enabled * var.enable_vpn * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"

  destination_cidr_block = "10.0.0.0/8"
  gateway_id             = "${element(aws_vpn_gateway.vpn_gateway.*.id, count.index/3)}"

}

# Create a proxy discovery VPC DNS zone
resource "aws_route53_zone" "proxy" {
  count = "${var.enabled * length(split(",", var.environments))}"
  name  = "proxy.${element(split(",",var.environments), count.index)}.${var.aws_region}.${var.account_name}.${var.nubis_domain}"

  vpc_id = "${element(aws_vpc.nubis.*.id, count.index)}"

  tags {
    Environment      = "${element(split(",",var.environments), count.index)}"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
  }
}

# Create a proxy discovery VPC DNS record for bootstrap proxy access
resource "aws_route53_record" "proxy" {
  count   = "${var.enabled * var.enable_nat * length(split(",", var.environments))}"
  zone_id = "${element(aws_route53_zone.proxy.*.zone_id, count.index)}"
  name    = "proxy.${element(split(",",var.environments), count.index)}.${var.aws_region}.${var.account_name}.${var.nubis_domain}"

  type = "A"

  alias {
    name                   = "${element(aws_elb.proxy.*.dns_name, count.index)}"
    zone_id                = "${element(aws_elb.proxy.*.zone_id, count.index)}"
    evaluate_target_health = false
  }
}

## Create a new load balancer
resource "aws_elb" "proxy" {
  count = "${var.enabled * var.enable_nat * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  name = "proxy-elb-${element(split(",",var.environments), count.index)}"

  #XXX: Fugly, assumes 3 subnets per environments, bad assumption, but valid ATM
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
    Name        = "elb-proxy-${element(split(",",var.environments), count.index)}"
    Region      = "${var.aws_region}"
    Environment = "${element(split(",",var.environments), count.index)}"
  }
}

resource "aws_security_group" "proxy" {
  count = "${var.enabled * var.enable_nat * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  name        = "elb-proxy-${element(split(",",var.environments), count.index)}"
  description = "Allow inbound traffic for Squid in ${element(split(",",var.environments), count.index)}"

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
    Name        = "elb-proxy-${element(split(",",var.environments), count.index)}"
    Region      = "${var.aws_region}"
    Environment = "${element(split(",",var.environments), count.index)}"
  }
}

resource "aws_eip" "nat" {
  # We enable this if consul AND/OR nat is enabled
  count = "${var.enabled * signum(var.enable_consul + var.enable_nat) * 2 * length(split(",", var.environments))}"

  vpc   = true

  lifecycle {
    create_before_destroy = true
  }
}

# Only needed by cloudwatch
resource "aws_security_group" "nubis_version" {
  count = "${var.enabled}"

  lifecycle {
    create_before_destroy = true
  }

  name_prefix = "NubisVersion-"
  description = "Placeholder for current Nubis version (${var.nubis_version})"

  tags = {
    NubisVersion = "${var.nubis_version}"
  }
}

provider "aws" {
  profile = "${var.aws_profile}"
  region  = "${var.aws_state_region}"
  alias   = "public-state"
}

resource "aws_s3_bucket_object" "public_state" {
  provider     = "aws.public-state"
  count        = "${var.enabled * length(split(",", var.environments))}"
  bucket       = "${var.public_state_bucket}"
  content_type = "text/json"
  key          = "aws/${var.aws_region}/${element(split(",",var.environments), count.index)}.tfstate"

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
              "region": ${jsonencode(var.aws_region)},
              "regions": ${jsonencode(var.aws_regions)},
              "availability_zones": ${jsonencode(aws_cloudformation_stack.availability_zones.outputs["AvailabilityZones"])},
              "hosted_zone_name": ${jsonencode(module.meta.HostedZoneName)},
              "hosted_zone_id": ${jsonencode(module.meta.HostedZoneId)},
              "vpc_id": ${jsonencode(element(aws_vpc.nubis.*.id,count.index))},
              "account_id": ${jsonencode(var.aws_account_id)},
              "rds_mysql_parameter_group": ${jsonencode(module.meta.NubisMySQL56ParameterGroup)},
              "monitoring_security_group" : ${jsonencode(element(aws_security_group.monitoring.*.id,count.index))},
              "shared_services_security_group": ${jsonencode(element(aws_security_group.shared_services.*.id,count.index))},
              "internet_access_security_group": ${jsonencode(element(aws_security_group.internet_access.*.id,count.index))},
              "ssh_security_group": ${jsonencode(element(aws_security_group.ssh.*.id,count.index))},
              "instance_security_groups": "${element(aws_security_group.shared_services.*.id,count.index)},${element(aws_security_group.internet_access.*.id,count.index)},${element(aws_security_group.ssh.*.id,count.index)}",
              "private_subnets": "${element(aws_subnet.private.*.id, (3*count.index) + 0)},${element(aws_subnet.private.*.id, (3*count.index) + 1)},${element(aws_subnet.private.*.id, (3*count.index) + 2)}",
              "public_subnets": "${element(aws_subnet.public.*.id, (3*count.index) + 0)},${element(aws_subnet.public.*.id, (3*count.index) + 1)},${element(aws_subnet.public.*.id, (3*count.index) + 2)}",
              "access_logging_bucket": ${jsonencode(element(split(",", module.fluent-collector.logging_buckets),count.index))},
              "default_ssl_certificate": "${module.meta.DefaultServerCertificate}",
              "dummy": "dummy"
            },
            "resources": {}
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "user_managment" {
    count = "${var.enabled * var.enable_user_management_consul * length(split(",", var.environments))}"
    role = "${element(concat(aws_iam_role.user_management.*.id, list("")), count.index)}"
    policy_arn = "${element(aws_iam_policy.credstash.*.arn, count.index)}"
}

resource "aws_iam_role" "user_management" {
  count = "${var.enabled * var.enable_user_management_consul * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  name = "user_management-${var.aws_region}-${element(split(",", var.environments), count.index)}"

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
  count = "${var.enabled * var.enable_user_management_consul * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  name = "user_management-${var.aws_region}-${element(split(",", var.environments), count.index)}"
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
  count = "${var.enabled * var.enable_user_management_consul * length(split(",", var.environments))}"

  depends_on = [
    "aws_iam_role_policy.user_management",
  ]

  function_name = "user_management-${element(split(",",var.environments), count.index)}"
  s3_bucket     = "nubis-stacks-${var.aws_region}"
  s3_key        = "${var.nubis_version}/lambda/UserManagement.zip"
  role          = "${element(aws_iam_role.user_management.*.arn, count.index)}"
  handler       = "index.handler"
  description   = "Queries LDAP and inserts user into consul and create and delete IAM users"
  memory_size   = 128
  runtime       = "nodejs4.3"
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
  count = "${var.enabled * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  vpc_id      = "${element(aws_vpc.nubis.*.id, count.index)}"
  name_prefix = "MocoLdapOutbound-${element(split(",", var.environments), count.index)}-"
  description = "Allow outbound ldap connection to moco ldap"

  egress {
    from_port = "6363"
    to_port   = "6363"
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags {
    Name             = "MocoLdapOutboundSecurityGroup"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    Environment      = "${element(split(",",var.environments), count.index)}"
  }
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  count = "${var.enabled * var.enable_user_management_consul * length(split(",", var.environments))}"

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${element(aws_lambda_function.user_management.*.function_name, count.index)}"
  principal     = "events.amazonaws.com"
  source_arn    = "${element(aws_cloudwatch_event_rule.user_management_event_consul.*.arn, count.index)}"
}

resource "aws_cloudwatch_event_rule" "user_management_event_consul" {
  count = "${var.enabled * var.enable_user_management_consul * length(split(",", var.environments))}"
  name  = "user_management-consul-${element(split(",", var.environments), count.index)}"

  description         = "Sends payload over a periodic time"
  schedule_expression = "${var.user_management_rate}"
}

resource "aws_cloudwatch_event_target" "user_management_consul" {
  count = "${var.enabled * var.enable_user_management_consul * length(split(",", var.environments))}"

  rule = "${element(aws_cloudwatch_event_rule.user_management_event_consul.*.name, count.index)}"
  arn  = "${element(aws_lambda_function.user_management.*.arn, count.index)}"

  input = <<EOF
{
    "command": "./nubis-user-management",
    "args": [
        "-execType=consul",
        "-useDynamo=true",
        "-region=${var.aws_region}",
        "-environment=${element(split(",", var.environments), count.index)}",
        "-service=nubis",
        "-accountName=${var.account_name}",
        "-consulDomain=${var.nubis_domain}",
        "-consulPort=80",
        "-key=nubis/${element(split(",", var.environments), count.index)}/user-sync/config",
        "-lambda=true"
    ]
}
EOF
}

data template_file "user_management_config" {
  count    = "${var.enabled * var.enable_user_management_consul * length(split(",", var.environments))}"
  template = "${file("${path.module}/user_management.yml.tmpl")}"

  vars {
    region                  = "${var.aws_region}"
    environment             = "${element(split(",", var.environments), count.index)}"
    smtp_from_address       = "${var.user_management_smtp_from_address}"
    smtp_username           = "${var.user_management_smtp_username}"
    smtp_password           = "${var.user_management_smtp_password}"
    smtp_host               = "${var.user_management_smtp_host}"
    smtp_port               = "${var.user_management_smtp_port}"
    ldap_server             = "${var.user_management_ldap_server}"
    ldap_port               = "${var.user_management_ldap_port}"
    ldap_base_dn            = "${var.user_management_ldap_base_dn}"
    ldap_bind_user          = "${var.user_management_ldap_bind_user}"
    ldap_bind_password      = "${var.user_management_ldap_bind_password}"
    tls_cert                = "${replace(file("${path.cwd}/${var.user_management_tls_cert}"), "/(.*)\\n/", "    $1\n")}"
    tls_key                 = "${replace(file("${path.cwd}/${var.user_management_tls_key}"), "/(.*)\\n/", "    $1\n")}"
    sudo_user_ldap_group    = "${replace(var.user_management_sudo_groups, ",", "|")}"
    users_ldap_group        = "${replace(var.user_management_user_groups, ",", "|")}"
  }
}

resource "null_resource" "user_management_unicreds" {
  count = "${var.enabled * var.enable_user_management_consul * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  triggers {
    region            = "${var.aws_region}"
    environment       = "${element(split(",", var.environments), count.index)}"
    context           = "-E region:${var.aws_region} -E environment:${element(split(",", var.environments), count.index)} -E service:nubis"
    rendered_template = "${element(data.template_file.user_management_config.*.rendered, count.index)}"
    unicreds          = "unicreds -k ${module.meta.CredstashKeyID} -r ${var.aws_region} put-file nubis/${element(split(",", var.environments), count.index)}"
  }

  provisioner "local-exec" {
    command = "echo '${element(data.template_file.user_management_config.*.rendered, count.index)}' | ${self.triggers.unicreds}/user-sync/config /dev/stdin ${self.triggers.context}"
  }
}
