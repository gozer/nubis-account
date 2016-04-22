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

  provisioner "local-exec" {
    command = "sleep 30"
  }
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

resource "aws_cloudformation_stack" "dummy-vpc" {
  count = "${var.enabled * var.enable_stack_compat}"

  lifecycle {
    create_before_destroy = true
  }

  name = "${var.aws_region}-vpc"

  template_url = "http://nubis-stacks.s3.amazonaws.com/${var.nubis_version}/vpc/dummy.template"

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
  }
}

#XXX: This is because it's fed to a module input, so it can't be undefined
#XXX: even in regions where enabled=0, unfortunately
resource "aws_lambda_function" "UUID" {
  #    count = "${var.enabled}"
  lifecycle {
    create_before_destroy = true
  }

  function_name = "UUID"
  s3_bucket     = "nubis-stacks"
  s3_key        = "${var.nubis_version}/lambda/UUID.zip"
  handler       = "index.handler"
  description   = "Generate UUIDs for use in Cloudformation stacks"
  memory_size   = 128
  runtime       = "nodejs"
  timeout       = "10"
  role          = "${aws_iam_role.lambda.arn}"
}

resource "aws_lambda_function" "LookupStackOutputs" {
  count         = "${var.enabled * var.enable_stack_compat}"
  function_name = "LookupStackOutputs"
  s3_bucket     = "nubis-stacks"
  s3_key        = "${var.nubis_version}/lambda/LookupStackOutputs.zip"
  handler       = "index.handler"
  description   = "Gather outputs from Cloudformation stacks to be used in other Cloudformation stacks"
  memory_size   = 128
  runtime       = "nodejs"
  timeout       = "10"
  role          = "${aws_iam_role.lambda.arn}"
}

resource "aws_lambda_function" "LookupNestedStackOutputs" {
  count         = "${var.enabled * var.enable_stack_compat}"
  function_name = "LookupNestedStackOutputs"
  s3_bucket     = "nubis-stacks"
  s3_key        = "${var.nubis_version}/lambda/LookupNestedStackOutputs.zip"
  handler       = "index.handler"
  description   = "Gather outputs from Cloudformation enviroment specific nested stacks to be used in other Cloudformation stacks"
  memory_size   = 128
  runtime       = "nodejs"
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
  count = "${var.enabled * length(split(",", var.environments))}"

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

  availability_zone = "${element(split(",",aws_cloudformation_stack.availability_zones.outputs.AvailabilityZones), count.index % 3 )}"

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

  availability_zone = "${element(split(",",aws_cloudformation_stack.availability_zones.outputs.AvailabilityZones), count.index % 3 )}"

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

  provisioner "local-exec" {
    command = "sleep 10"
  }

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

  depends_on = ["aws_route_table.public"]
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

  provisioner "local-exec" {
    command = "sleep 10"
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
  count = "${3 * var.enabled * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
    ignore_changes        = ["attachment"]
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

resource "atlas_artifact" "nubis-nat" {
  count = "${var.enabled}"

  lifecycle {
    create_before_destroy = true
  }

  name = "nubisproject/nubis-nat"
  type = "amazon.image"

  metadata {
    project_version = "${var.nubis_version}"
  }
}

resource "aws_autoscaling_group" "nat" {
  count = "${var.enabled * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  name = "nubis-nat-${element(split(",",var.environments), count.index)}- (${element(aws_launch_configuration.nat.*.name, count.index)})"

  # Subnets
  vpc_zone_identifier = [
    "${element(aws_subnet.public.*.id, 3*count.index)}",
    "${element(aws_subnet.public.*.id, 3*count.index+1)}",
    "${element(aws_subnet.public.*.id, 3*count.index+2)}",
  ]

  max_size             = 2
  min_size             = 1
  desired_capacity     = 1
  launch_configuration = "${element(aws_launch_configuration.nat.*.name, count.index )}"

  tag {
    key                 = "Name"
    value               = "nubis-nat-${element(split(",",var.environments), count.index)}"
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
    value               = "${element(split(",",var.environments), count.index)}"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "nat" {
  count = "${var.enabled * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  name_prefix = "nubis-nat-${element(split(",",var.environments), count.index )}-"

  # Somewhat nasty, since Atlas doesn't have an elegant way to access the id for a region
  # the id is "region:ami,region:ami,region:ami"
  # so we split it all and find the index of the region
  # add on, and pick that element
  image_id = "${ element(split(",",replace(atlas_artifact.nubis-nat.id,":",",")) ,1 + index(split(",",replace(atlas_artifact.nubis-nat.id,":",",")), var.aws_region)) }"

  instance_type               = "t2.nano"
  associate_public_ip_address = true
  key_name                    = "${var.ssh_key_name}"

  iam_instance_profile = "${element(aws_iam_instance_profile.nat.*.id, count.index)}"

  security_groups = [
    "${element(aws_security_group.internet_access.*.id, count.index)}",
    "${element(aws_security_group.nat.*.id, count.index)}",
    "${element(aws_security_group.ssh.*.id, count.index)}",
    "${element(aws_security_group.shared_services.*.id, count.index)}",
  ]

  user_data = <<USER_DATA
NUBIS_PROJECT='nubis-nat-${element(split(",",var.environments), count.index)}'
NUBIS_ENVIRONMENT='${element(split(",",var.environments), count.index)}'
NUBIS_DOMAIN='${var.nubis_domain}'
NUBIS_MIGRATE='1'
NUBIS_ACCOUNT='${var.account_name}'
NUBIS_PURPOSE='Nat Instance'
USER_DATA
}

# XXX: This could be a global
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

resource "aws_iam_policy_attachment" "credstash" {
  count = "${var.enabled * length(split(",", var.environments))}"

  name = "credstash-${var.aws_region}"

  #XXX: concat and compact should work here, but element() isn't a list, so BUG
  roles = [
    "${split(",",replace(replace(concat(element(split(",",module.jumphost.iam_roles), count.index), ",", element(split(",",module.consul.iam_roles), count.index), ",", element(split(",",module.fluent-collector.iam_roles), count.index), ",", element(aws_iam_role.nat.*.id, count.index) ), "/(,+)/",","),"/(^,+|,+$)/", ""))}",
  ]

  policy_arn = "${element(aws_iam_policy.credstash.*.arn, count.index)}"
}

module "jumphost" {
  source = "github.com/nubisproject/nubis-jumphost//nubis/terraform?ref=v1.1.0"

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
}

module "fluent-collector" {
  source = "github.com/nubisproject/nubis-fluent-collector//nubis/terraform/multi?ref=v1.1.0"

  enabled = "${var.enabled * var.enable_fluent}"

  environments = "${var.environments}"
  aws_profile  = "${var.aws_profile}"
  aws_region   = "${var.aws_region}"

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

  nubis_domain = "${var.nubis_domain}"

  service_name = "${var.account_name}"
}

module "consul" {
  source = "../consul"

  enabled = "${var.enabled * var.enable_consul}"

  environments = "${var.environments}"

  aws_profile    = "${var.aws_profile}"
  aws_region     = "${var.aws_region}"
  aws_account_id = "${var.aws_account_id}"

  my_ip           = "${var.my_ip}"
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
module "ci" {
  source = "github.com/nubisproject/nubis-ci//nubis/terraform?ref=v1.1.0"

  enabled = "${var.enabled * var.enable_ci}"

  environment = "${element(split(",",var.environments), 0)}"
  aws_profile = "${var.aws_profile}"
  region      = "${var.aws_region}"

  key_name          = "${var.ssh_key_name}"
  version           = "${var.nubis_version}"
  technical_contact = "${var.technical_contact}"

  nubis_domain = "${var.nubis_domain}"
  zone_id      = "${module.meta.HostedZoneId}"

  vpc_id = "${element(aws_vpc.nubis.*.id, 0)}"

  # XXX: Only first 3
  private_subnets = "${element(aws_subnet.private.*.id, 0)},${element(aws_subnet.private.*.id, 1)},${element(aws_subnet.private.*.id, 2)}"
  public_subnets  = "${element(aws_subnet.public.*.id, 0)},${element(aws_subnet.public.*.id, 1)},${element(aws_subnet.public.*.id, 2)}"

  internet_security_group_id        = "${element(aws_security_group.internet_access.*.id, 0)}"
  shared_services_security_group_id = "${element(aws_security_group.shared_services.*.id, 0)}"
  ssh_security_group_id             = "${element(aws_security_group.ssh.*.id, 0)}"

  domain = "${var.nubis_domain}"

  account_name = "${var.account_name}"

  project                    = "${var.ci_project}"
  git_repo                   = "${var.ci_git_repo}"
  github_oauth_client_secret = "${var.ci_github_oauth_client_secret}"
  github_oauth_client_id     = "${var.ci_github_oauth_client_id}"

  s3_bucket_name = "ci-skel-${module.ci-uuid.uuids}"

  email = "${var.technical_contact}"
}

module "opsec" {
  source = "../opsec"

  enabled = "${var.enabled * var.enable_opsec}"

  aws_profile = "${var.aws_profile}"
  aws_region  = "${var.aws_region}"
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
  count = "${var.enabled * var.enable_vpn * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  bgp_asn = "${var.vpn_bgp_asn}"

  ip_address = "${element(split(",", var.ipsec_targets), count.index)}"
  type       = "ipsec.1"

  tags {
    Name             = "${var.aws_region}-${element(split(",",var.environments), count.index)}-customer-gateway"
    ServiceName      = "${var.account_name}"
    TechnicalContact = "${var.technical_contact}"
    Environment      = "${element(split(",",var.environments), count.index)}"
  }
}

resource "aws_vpn_connection" "main" {
  count = "${var.enabled * var.enable_vpn * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  vpn_gateway_id      = "${element(aws_vpn_gateway.vpn_gateway.*.id, count.index)}"
  customer_gateway_id = "${element(aws_customer_gateway.customer_gateway.*.id, count.index)}"
  type                = "${element(aws_customer_gateway.customer_gateway.*.type, count.index)}"
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

  #    depends_on = ["aws_route_table.public"]
}

resource "aws_route" "vpn-private" {
  count = "${3 * var.enabled * var.enable_vpn * length(split(",", var.environments))}"

  lifecycle {
    create_before_destroy = true
  }

  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"

  destination_cidr_block = "10.0.0.0/8"
  gateway_id             = "${element(aws_vpn_gateway.vpn_gateway.*.id, count.index/3)}"

  #    depends_on = ["aws_route_table.private"]
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
  count   = "${var.enabled * length(split(",", var.environments))}"
  zone_id = "${element(aws_route53_zone.proxy.*.zone_id, count.index)}"
  name    = "proxy.${element(split(",",var.environments), count.index)}.${var.aws_region}.${var.account_name}.${var.nubis_domain}"

  type = "A"
  ttl  = "60"

  records = [
    "${element(aws_network_interface.private-nat.*.private_ips, 0 + ( count.index * 3 ))}",
    "${element(aws_network_interface.private-nat.*.private_ips, 1 + ( count.index * 3 ))}",
    "${element(aws_network_interface.private-nat.*.private_ips, 2 + ( count.index * 3 ))}",
  ]
}
