#me#################################################################################
# VARIABLES
##################################################################################

variable "aws_access_key"         {}
variable "aws_secret_key"         {}
variable "aws_region_name"        {}
variable "aws_region_abbr"        {}

variable "account_number"         {}
variable "domainname"             {}

variable "name_prefix"            {}
variable "pub_key"                {}

variable "number_of_users"        {}
variable "offset_number_of_users" {}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region_name
}

##################################################################################
# DATA
#
# Amazon AMI: https://www.hashicorp.com/blog/hashicorp-terraform-supports-amazon-linux-2/
##################################################################################

data "aws_route53_zone" "zone" {
    name         = var.domainname
}

data "aws_iam_policy" "AmazonAPIGatewayPushToCloudWatchLogs" {
    arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs" 
}

data "aws_ami" "amazon_linux_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

}

data "aws_vpc" "vpc" {
  tags = { Name = "FRA" }
}

##################################################################################
# RESOURCES
##################################################################################

# IAM Objects
# -----------

resource "aws_iam_policy" "user_policy" {
    name        = "${var.name_prefix}_${var.aws_region_abbr}_CICD_user_policy"
    description = "Policy for CI CD workshop on 09-07-2020."
    policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
                  "acm:ListCertificates",
                  "acm:ListTagsForCertificate"
		],
		"Effect": "Allow",
		"Resource": "*"
      },
      {
        "Action": [
                  "acm:DescribeCertificate"
		],
		"Effect": "Allow",
		"Resource": "*"
      },
      {

        "Action": [
                  "route53:ListResourceRecordSets",
                  "route53:ListTagsForResource",
                  "route53:GetHostedZone",
                  "route53:ChangeResourceRecordSets"
                ],
		"Effect": "Allow",
	        "Resource": "arn:aws:route53:::hostedzone/${data.aws_route53_zone.zone.zone_id}"
      },
      {
        "Action": [
                  "iam:ListRolePolicies",
                  "iam:ListAttachedRolePolicies",
                  "iam:GetRole",
                  "iam:GetPolicy",
                  "iam:GetPolicyVersion",
                  "iam:PassRole"
		],
		"Effect": "Allow",
		"Resource": ["arn:aws:iam::${var.account_number}:role/${var.name_prefix}*",
                             "arn:aws:iam::${var.account_number}:policy/${var.name_prefix}*"]
      },
      {
        "Action": [
                  "kms:GetPublicKey"
		],
		"Effect": "Allow",
		"Resource": "arn:aws:kms:${var.aws_region_name}:${var.account_number}:key/${var.name_prefix}*"
      },
      {
        "Action": [
                  "route53:ListHostedZones",
                  "route53:GetHostedZoneCount",
                  "route53:GetChange",
                  "iam:ListRoles",
                  "iam:ListPolicies",
                  "kms:ListKeys",
                  "kms:ListAliases",
                  "apigateway:*",
		  "lambda:*",
                  "sns:*",
                  "dynamodb:*",
		  "cloudformation:*",
		  "cloudwatch:describe*",
		  "cloudwatch:get*"
		],
		"Effect": "Allow",
		"Resource": "*",
                "Condition": {
                   "StringEquals": {
                       "aws:RequestedRegion": "${var.aws_region_name}"
                   }
                }
	  }
	]
}
EOF
}

# Lambda accept policy

resource "aws_iam_policy" "lambda_accept_policy" {
    name        = "${var.name_prefix}_${var.aws_region_abbr}_CICD_lambda_accept_policy"
    description = "Policy for CI CD workshop on 09-07-2020."
    policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
		  "logs:CreateLogGroup",
		  "logs:CreateLogStream",
		  "logs:PutLogEvents",
		  "sns:Publish",
                  "kms:GetPublicKey"
                  ],
		"Effect": "Allow",
		"Resource": "*",
                "Condition": {
                   "StringEquals": {
                       "aws:RequestedRegion": "${var.aws_region_name}"
                   }
                }
	}
      ]
}
EOF
}

# EC2 policy

resource "aws_iam_policy" "ec2_policy" {
    name        = "${var.name_prefix}_${var.aws_region_abbr}_CICD_EC2_policy"
    description = "Policy for CI CD workshop on 09-07-2020."
    policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
                      "codecommit:*"
                  ],
		"Effect": "Allow",
		"Resource": "*",
                "Condition": {
                   "StringEquals": {
                       "aws:RequestedRegion": "${var.aws_region_name}"
                   }
                }
	}
      ]
}
EOF
}

# Lambda accept role

resource "aws_iam_role" "lambda_accept_role" {
    name                  = "${var.name_prefix}_${var.aws_region_abbr}_CICD_lambda_accept_role"
    description           =  "Policy for CI CD workshop on 09-07-2020."
    force_detach_policies = true
    assume_role_policy    =  <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
} 

resource "aws_iam_policy_attachment" "policy_to_accept_role" {
   name       = "${var.name_prefix}_${var.aws_region_abbr}_policy_to_accept_role"
   roles      = [aws_iam_role.lambda_accept_role.name]
   policy_arn = aws_iam_policy.lambda_accept_policy.arn
}

resource "aws_iam_role" "ec2_role" {
    name                  = "${var.name_prefix}_${var.aws_region_abbr}_CICD_ec2_role"
    description           =  "Policy for CI CD workshop on 09-07-2020."
    force_detach_policies = true
    assume_role_policy    =  <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
} 

resource "aws_iam_policy_attachment" "policy_attachment_ec2_role" {
   name       = "${var.name_prefix}_${var.aws_region_abbr}_policy_to_ec2_role"
   roles      = [aws_iam_role.ec2_role.name]
   policy_arn = aws_iam_policy.ec2_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
   name       = "${var.name_prefix}_${var.aws_region_abbr}_ec2_instance_profile"
   role       = aws_iam_role.ec2_role.name
}

# AmazonAPIGatewayPushToCloudWatchLogs
# Needed to log what happens in the API gateway

resource "aws_iam_role" "api_gateway_role" {
    name                  = "${var.name_prefix}_${var.aws_region_abbr}_api_gateway_role"
    description           = "Policy for CI CD workshop on 09-07-2020."
    force_detach_policies = true
    assume_role_policy    = <<EOF
{
    "Version" : "2012-10-17" ,
    "Statement" : [
        {
            "Effect" : "allow",
            "Principal" : {
                "Service": "apigateway.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
} 
EOF
}

resource "aws_iam_policy_attachment" "policy_to_cloudwatch_role" {
    name       = "${var.name_prefix}_${var.aws_region_abbr}_policy_to_cloudwatch_role"
    roles      = [aws_iam_role.api_gateway_role.name]
    policy_arn = data.aws_iam_policy.AmazonAPIGatewayPushToCloudWatchLogs.arn
}

# IAM users
#
# First, the user and the group are created.
# After that, there is a group membership object to connect users with groups and
# there is a policy attachment object to connect groups with policies

resource "aws_iam_user" "user" {
    count                    = var.number_of_users
    name                     = "${var.name_prefix}${count.index + var.offset_number_of_users}"
    force_destroy            = true
}

resource "aws_iam_group" "user_group" {
    name = "${var.name_prefix}-${var.aws_region_abbr}_Sig-CICD-group"
}

resource "aws_iam_group_membership" "user_group_membership" {
    name  = "${var.name_prefix}_${var.aws_region_abbr}_SIG-CICD-group_membership"
    users = aws_iam_user.user[*].name
    group = aws_iam_group.user_group.name
}

resource "aws_iam_group_policy_attachment" "user_group_policy_attachment" {
    group      = aws_iam_group.user_group.name
    policy_arn = aws_iam_policy.user_policy.arn
}

# CodeCommit repo
# ---------------

resource "aws_codecommit_repository" "repo" {
    count           = var.number_of_users
    repository_name = "${var.name_prefix}${count.index + var.offset_number_of_users}-repo"
    description     = "CI/CD workshop 09-07-2020"
}

# EC2/VPC resources
# -----------------

resource "aws_security_group" "security_group" {
    name            = "${var.name_prefix}-security-group"
    description     = "Allow anyone with a key to go to this VM"
    vpc_id          = data.aws_vpc.vpc.id

    ingress {
        description = "SSH"
        from_port   = 0
        to_port     = 22
        protocol    = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = -1
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.name_prefix}-security-group"
    }
}

resource "aws_key_pair" "ec2_key_pair" {
    key_name                  = "${var.name_prefix}-${var.aws_region_name}"
    public_key                = var.pub_key
}

resource "aws_instance" "ec2" {
  depends_on                  = [aws_iam_instance_profile.ec2_instance_profile]
  count                       = var.number_of_users
  ami                         = data.aws_ami.amazon_linux_ami.image_id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  user_data                   = file("user_data.sh")
  instance_type               = "t2.micro"
  key_name                    = "AMIS-${var.aws_region_name}"
  vpc_security_group_ids      = [aws_security_group.security_group.id]

  tags = {
    Name = "${var.name_prefix}${count.index + var.offset_number_of_users}-vm"
  }

}



##################################################################################
# OUTPUT
##################################################################################


