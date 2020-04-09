##################################################################################
# VARIABLES
##################################################################################

variable "aws_access_key"         {}
variable "aws_secret_key"         {}

variable "number_of_users"        {}
variable "offset_number_of_users" {}
variable "name_prefix"            {}
variable "account_number"         {}

variable "aws_region_sig"         {}
variable "aws_region_ec2"         {
    description = "Is not used in this script. Declaration is done to prevent warnings."
}

variable "domainname" {
    default = "your-domain-name-in-AWS"
}

variable key_prefix {
   description = "Prefix for key. Change this if you get a 'key already exists' message on creation"
   default = "KeyG-"
}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region_sig
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
##################################################################################

#
# Create as many keys as users
#

# Key itself

resource "aws_kms_key" "amis" {
    count                    = var.number_of_users
    description              = "${var.name_prefix}${count.index + var.offset_number_of_users}"
    key_usage                = "ENCRYPT_DECRYPT"
    customer_master_key_spec = "RSA_2048"
}

# Alias ("name") for the key

resource "aws_kms_alias" "amis" {
  count          = var.number_of_users
  name           = "alias/${var.key_prefix}${var.name_prefix}${count.index + var.offset_number_of_users}"
  target_key_id  = aws_kms_key.amis[count.index].key_id 
}

#
# IAM policies
#

# Policy for the users (both UI and CLI/SDK)
#
# The AWS services that we use in the shop example (API Gateway, Lambda, SNS, DynamoDB) can be used 
# without restrictions in the region that we use.
#
# The AWS services that are global (Route53, certificates, IAM) can be seen but not be modified.
#

resource "aws_iam_policy" "AMIS_CICD_policy" {
    name  = "${var.name_prefix}_CICD_Policy"
    description = "Policy for CI CD workshop on 01-07-2020. More info Frederique Retsema 06-823 90 591."
    policy = <<EOF
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
		"Resource": ["arn:aws:iam::${var.account_number}:role/AMIS*",
                             "arn:aws:iam::${var.account_number}:policy/AMIS*"]
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

# logs: needed to create entries in cloudwatch for this lambda policy
# sns: needed to send a message to the next lambda function
# kms: needed because AWS will encrypt the parameter with a default kms key. The public key is needed
#      to decrypt it.

resource "aws_iam_policy" "AMIS_CICD_lambda_accept_policy" {
    name = "AMIS_CICD_lambda_accept_policy"
    description = "Policy for CI CD workshop on 01-07-2020. More info Frederique Retsema 06-823 90 591."
    policy = <<EOF
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
                       "aws:RequestedRegion": "${var.aws_region_sig}"
                   }
                }
	}
      ]
}
EOF
}

# logs: needed to create entries in cloudwatch for this lambda policy
# sns: needed to send a message to the next lambda function
# kms: needed because AWS will encrypt the parameter with a default kms key. The public key is needed
#      to decrypt it.
#      it will also be used to decrypt the encrypted text from the client ("till" that sends the number
#      of sold items and the amout of money that is payed)

resource "aws_iam_policy" "AMIS_CICD_lambda_decrypt_policy" {
    name = "AMIS_CICD_lambda_decrypt_policy"
    description = "Policy for CI CD workshop on 01-07-2020. More info Frederique Retsema 06-823 90 591."
    policy = <<EOF
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
                       "aws:RequestedRegion": "${var.aws_region_sig}"
                   }
                }
	}
      ]
}
EOF
}

# logs: needed to create entries in cloudwatch for this lambda policy
# dynamodb: needed to create and update items (update does both)
# kms: needed because AWS will encrypt the parameter with a default kms key. The public key is needed
#      to decrypt it.

resource "aws_iam_policy" "AMIS_CICD_lambda_process_policy" {
    name = "AMIS_CICD_lambda_process_policy"
    description = "Policy for CI CD workshop on 01-07-2020. More info Frederique Retsema 06-823 90 591."
    policy = <<EOF
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
                       "aws:RequestedRegion": "${var.aws_region_sig}"
                   }
                }
      }
     ]
}
EOF
}

resource "aws_iam_role" "AMIS_CICD_lambda_accept_role" {
    name = "AMIS_CICD_lambda_accept_role"
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

resource "aws_iam_role" "AMIS_CICD_lambda_decrypt_role" {
    name = "AMIS_CICD_lambda_decrypt_role"
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

resource "aws_iam_role" "AMIS_CICD_lambda_process_role" {
    name = "AMIS_CICD_lambda_process_role"
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

resource "aws_iam_policy_attachment" "policy_to_accept_role" {
   name       = "policy_to_accept_role"
   roles      = [aws_iam_role.AMIS_CICD_lambda_accept_role.name]
   policy_arn = aws_iam_policy.AMIS_CICD_lambda_accept_policy.arn
}

resource "aws_iam_policy_attachment" "policy_to_decrypt_role" {
   name       = "policy_to_decrypt_role"
   roles      = [aws_iam_role.AMIS_CICD_lambda_decrypt_role.name]
   policy_arn = aws_iam_policy.AMIS_CICD_lambda_decrypt_policy.arn
}

resource "aws_iam_policy_attachment" "policy_to_process_role" {
   name       = "policy_to_process_role"
   roles      = [aws_iam_role.AMIS_CICD_lambda_process_role.name]
   policy_arn = aws_iam_policy.AMIS_CICD_lambda_process_policy.arn
}


resource "aws_iam_user" "AMIS_user" {
    count                    = var.number_of_users
    name                     = "${var.name_prefix}${count.index + var.offset_number_of_users}"
    force_destroy            = true
}

resource "aws_iam_group" "AMIS_group" {
    name = "AMIS-Sig-CICD"
}

resource "aws_iam_group_membership" "SIG_CICD" {
    name  = "SIG-CICD-membership"
    users = aws_iam_user.AMIS_user[*].name
    group = aws_iam_group.AMIS_group.name
}

resource "aws_iam_group_policy_attachment" "SIG_CICD_Policy_attachment" {
    group      = aws_iam_group.AMIS_group.name
    policy_arn = aws_iam_policy.AMIS_CICD_policy.arn
}

#
## DynamoDB
#

resource "aws_dynamodb_table" "AMIS-stores" {
    name           = "AMIS-stores"
    billing_mode   = "PROVISIONED"
    read_capacity  = 1
    write_capacity = 1
    hash_key       = "storeID"
    range_key      = "recordType"

    attribute {
        name = "storeID"
        type = "S"
    }

    attribute {
        name = "recordType"
        type = "S"
    }
}

# Doesn't work, see my github repository. Workaround = use a python-script.
#
#resource "aws_dynamodb_table_item" "AMIS-goudse-kaas-items" {
#    table_name     = aws_dynamodb_table.AMIS-stores.name
#    hash_key       = aws_dynamodb_table.AMIS-stores.hash_key
#    count          = var.number_of_users
#
#    item = <<ITEM
#{
#    "storeID"         : {"S": "${var.name_prefix}${count.index + var.offset_number_of_users}"},
#    "recordType"      : {"S": "store"},
#    "itemID"          : {"N": "1234"},
#    "itemDescription" : {"S": "something"},
#    "stock"           : {"N": "10000"},
#    "sellingPrice"    : {"N": "3"},
#    "grossAmount"     : {"N": "0"}
#}
#ITEM
#}

##################################################################################
# OUTPUT
##################################################################################


