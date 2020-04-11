##################################################################################
# VARIABLES
##################################################################################

variable "aws_access_key"         {}
variable "aws_secret_key"         {}
variable "aws_region"             {}

variable "account_number"         {}
variable "domainname"             {}

variable "name_prefix"            {}
variable "key_prefix"             {}

variable "number_of_users"        {}
variable "offset_number_of_users" {}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region
}

##################################################################################
# DATA
##################################################################################

data "aws_acm_certificate" "domain_certificate" {
    domain = "*.${var.domainname}"
}

data "aws_route53_zone" "zone" {
    name = var.domainname
}

##################################################################################
# RESOURCES
# 
# Resources are created in the following order:
# - IAM objects
# - KMS objects
# - DynamoDB objects
##################################################################################

# IAM Objects
# -----------
#
# IAM objects are created in the following order:
# - policies
# - roles
# - users
# - groups

# Policy for the users (both UI and CLI/SDK)
#
# The AWS services that we use in the shop example (API Gateway, Lambda, SNS, DynamoDB) can be used 
# without restrictions in the region that is used by the users that have this policy.
#
# The AWS services that are global (Route53, certificates, IAM) can be seen but not be modified.
#

resource "aws_iam_policy" "user_policy" {
    name        = "${var.name_prefix}_CICD_user_policy"
    description = "Policy for CI CD workshop on 01-07-2020. More info Frederique Retsema 06-823 90 591."
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
		"Resource": "${data.aws_acm_certificate.domain_certificate.arn}"
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
		"Resource": "arn:aws:kms:eu-west-1:${var.account_number}:key/${var.name_prefix}*"
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
		"Resource": "*"
	  }
	]
}
EOF
}

# Lambda accept policy
#
# Used by the Lambda accept role (and Lambda accept function)
#
# logs: needed to create entries in cloudwatch for this lambda policy
# sns : needed to send a message to the decrypt function
# kms : needed because AWS will encrypt the environment parameter with a default kms key. 
#       The public key is needed to decrypt it.

resource "aws_iam_policy" "lambda_accept_policy" {
    name        = "${var.name_prefix}_CICD_lambda_accept_policy"
    description = "Policy for CI CD workshop on 01-07-2020. More info Frederique Retsema 06-823 90 591."
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
                       "aws:RequestedRegion": "${var.aws_region}"
                   }
                }
	}
      ]
}
EOF
}

# Lambda decrypt policy
# 
# Used by the Lambda decrypt role (and Lambda decrypt function)
#
# logs: needed to create entries in cloudwatch for this lambda policy
# sns : needed to send a message to the process function
# kms : GetPublicKey needed because AWS will encrypt the parameter with a default kms key. The public key is needed
#       to decrypt it.
#       Decrypt is used to decrypt the encrypted text from the client ("cash machine")

resource "aws_iam_policy" "lambda_decrypt_policy" {
    name        = "${var.name_prefix}_CICD_lambda_decrypt_policy"
    description = "Policy for CI CD workshop on 01-07-2020. More info Frederique Retsema 06-823 90 591."
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
                  "kms:GetPublicKey",
                  "kms:Decrypt"
                  ],
		"Effect": "Allow",
		"Resource": "*",
                "Condition": {
                   "StringEquals": {
                       "aws:RequestedRegion": "${var.aws_region}"
                   }
                }
	}
      ]
}
EOF
}

# Lambda process policy
# 
# Used by the Lambda process role (and Lambda process function)
#
# logs    : needed to create entries in cloudwatch for this lambda policy
# dynamodb: needed to create and update items (update does both)
# kms     : needed because AWS will encrypt the parameter with a default kms key. The public key is needed
#           to decrypt it.

resource "aws_iam_policy" "lambda_process_policy" {
    name        = "${var.name_prefix}_CICD_lambda_process_policy"
    description = "Policy for CI CD workshop on 01-07-2020. More info Frederique Retsema 06-823 90 591."
    policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
		  "logs:CreateLogGroup",
		  "logs:CreateLogStream",
		  "logs:PutLogEvents",
		  "dynamodb:GetItem",
		  "dynamodb:UpdateItem",
		  "dynamodb:PutItem",
                  "kms:GetPublicKey"
                  ],
		"Effect": "Allow",
		"Resource": "*",
                "Condition": {
                   "StringEquals": {
                       "aws:RequestedRegion": "${var.aws_region}"
                   }
                }
      }
     ]
}
EOF
}

# Lambda accept role
# 
# Used by the Lambda accept function. 
#

resource "aws_iam_role" "lambda_accept_role" {
    name                  = "${var.name_prefix}_CICD_lambda_accept_role"
    description           =  "Policy for CI CD workshop on 01-07-2020. More info Frederique Retsema 06-823 90 591."
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
   name       = "${var.name_prefix}_policy_to_accept_role"
   roles      = [aws_iam_role.lambda_accept_role.name]
   policy_arn = aws_iam_policy.lambda_accept_policy.arn
}

# Lambda decrypt role
# 
# Used by the Lambda decrypt function
#

resource "aws_iam_role" "lambda_decrypt_role" {
    name = "${var.name_prefix}_CICD_lambda_decrypt_role"
    description =  "Policy for CI CD workshop on 01-07-2020. More info Frederique Retsema 06-823 90 591."
    force_detach_policies = true
    assume_role_policy =  <<EOF
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

resource "aws_iam_policy_attachment" "policy_to_decrypt_role" {
   name       = "${var.name_prefix}_policy_to_decrypt_role"
   roles      = [aws_iam_role.lambda_decrypt_role.name]
   policy_arn = aws_iam_policy.lambda_decrypt_policy.arn
}

# Lambda process role
# 
# Used by the Lambda process function
#

resource "aws_iam_role" "lambda_process_role" {
    name = "${var.name_prefix}_CICD_lambda_process_role"
    description =  "Policy for CI CD workshop on 01-07-2020. More info Frederique Retsema 06-823 90 591."
    force_detach_policies = true
    assume_role_policy =  <<EOF
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

resource "aws_iam_policy_attachment" "policy_to_process_role" {
   name       = "${var.name_prefix}_policy_to_process_role"
   roles      = [aws_iam_role.lambda_process_role.name]
   policy_arn = aws_iam_policy.lambda_process_policy.arn
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
    name = "${var.name_prefix}-Sig-CICD-group"
}

resource "aws_iam_group_membership" "user_group_membership" {
    name  = "${var.name_prefix}_SIG-CICD-group_membership"
    users = aws_iam_user.user[*].name
    group = aws_iam_group.user_group.name
}

resource "aws_iam_group_policy_attachment" "user_group_policy_attachment" {
    group      = aws_iam_group.user_group.name
    policy_arn = aws_iam_policy.user_policy.arn
}

# Keys and key aliases
#
# Though the user interface suggests that an alias (name of the key in the user interface) is just 
# a parameter of a key, in the SDK these are two objects. 

resource "aws_kms_key" "key" {
    count                    = var.number_of_users
    description              = "${var.name_prefix}${count.index + var.offset_number_of_users}"
    key_usage                = "ENCRYPT_DECRYPT"
    customer_master_key_spec = "RSA_2048"
}

resource "aws_kms_alias" "key_alias" {
  count          = var.number_of_users
  name           = "alias/${var.key_prefix}${var.name_prefix}${count.index + var.offset_number_of_users}"
  target_key_id  = aws_kms_key.key[count.index].key_id 
}


# DynamoDB table
#
# We use a provisioned table because we are in a development/test environment. Setting the read and
# write capacity to 1 will limit the number of reads and writes to one per second.
#
# In production environments, we could use on-demand read/write capacity. This is a little bit more
# expensive, but then we do have a one-to-one relationship between the costs and the number of 
# read/writes.
#
# Mind, that trottling can still occur with on-demand capacity: the initial throughput for 
# On-Demand capacity mode is 2,000 write request units, and 6,000 read request units. This can grow
# (via auto scaling) to 40,000 write request units and 40,000 read request units. When you need to
# have more capacity, you can request this via a service ticket to AWS.

resource "aws_dynamodb_table" "shops-table" {
    name           = "${var.name_prefix}-shops"
    billing_mode   = "PROVISIONED"
    read_capacity  = 1
    write_capacity = 1
    hash_key       = "shop_id"
    range_key      = "record_type"

    attribute {
        name = "shop_id"
        type = "S"
    }

    attribute {
        name = "record_type"
        type = "S"
    }
}

# aws_dynamodb_table_item (to add records to our table) doesn't work, see my github repository 
# (https://github.com/terraform-providers/terraform-provider-aws/issues/12545). 
# Workaround: use a python-script to add the records to the database.

##################################################################################
# OUTPUT
##################################################################################


