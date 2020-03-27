##################################################################################
# VARIABLES
##################################################################################

variable "aws_access_key" {}
variable "aws_secret_key" {}

variable number_of_users {
   description = "Number of users that will attend the workshop"
   default = 5
}
variable nameprefix {
   description = "Prefix that is used for both the username and the keyname"
   default = "AMIS"
}
variable keyprefix {
   description = "Prefix for key. Change this if you get a 'key already exists' message on creation"
   default = "KeyC-"
}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = "eu-west-1"
}

##################################################################################
# DATA
##################################################################################

data "aws_availability_zones" "available" {}

##################################################################################
# RESOURCES
##################################################################################

#
# Create as many keys as users
#

resource "aws_kms_key" "amis" {
    count                    = var.number_of_users
    description              = "${var.nameprefix}${count.index}"
    key_usage                = "ENCRYPT_DECRYPT"
    customer_master_key_spec = "RSA_2048"
}


resource "aws_kms_alias" "amis" {
  count          = var.number_of_users
  name           = "alias/${var.keyprefix}${var.nameprefix}${count.index}"
  target_key_id  = aws_kms_key.amis[count.index].key_id 
}

resource "aws_iam_policy" "AMIS_CICD_policy" {
    name = "AMIS_CICD_Policy"
    description = "Policy for CI CD workshop on 01-07-2020. More info Frederique Retsema 06-823 90 591."
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
                  "apigateway:*",
		  "lambda:*",
                  "sns:*",
		  "cloudformation:*",
		  "cloudwatch:describe*",
		  "cloudwatch:get*",
                  "iam:ListRoles",
                  "iam:ListRolePolicies",
                  "iam:ListAttachedRolePolicies",
                  "iam:GetRole",
                  "iam:GetPolicy",
                  "iam:GetPolicyVersion",
                  "iam:PassRole",
                  "kms:GetPublicKey"
		],
		"Effect": "Allow",
		"Resource": "*"
	  }
	]
}
EOF
}

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
		"Resource": "*"
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

resource "aws_iam_policy_attachment" "policy_to_role" {
   name       = "policy_to_role"
   roles      = [aws_iam_role.AMIS_CICD_lambda_accept_role.name]
   policy_arn = aws_iam_policy.AMIS_CICD_lambda_accept_policy.arn
}

resource "aws_iam_user" "AMIS_user" {
    count                    = var.number_of_users
    name                     = "${var.nameprefix}${count.index}"
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
	policy_arn =  aws_iam_policy.AMIS_CICD_policy.arn
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

#resource "aws_dynamodb_table_item" "AMIS-goudse-kaas-items" {
#    table_name     = aws_dynamodb_table.AMIS-stores.name
#    hash_key       = aws_dynamodb_table.AMIS-stores.hash_key
#    count          = var.number_of_users
#
#    item = <<ITEM
#{
#    "storeID"         : {"S": "${var.nameprefix}${count.index}"},
#    "recordType"      : {"S": "store"},
#    "itemID"          : {"N": "1234"},
#    "itemDescription" : {"S": "Goudse kaas, oud 48+, 6 plakken"},
#    "stock"           : {"N": "10000"},
#    "sellingPrice"    : {"N": "3"},
#    "grossAmount"     : {"N": "0"}
#}
#ITEM
#}
#
#resource "aws_dynamodb_table_item" "AMIS-Beemster-kaas-items" {
#    table_name     = aws_dynamodb_table.AMIS-stores.name
#    hash_key       = aws_dynamodb_table.AMIS-stores.hash_key
#    count          = var.number_of_users
#
#    item = <<ITEM
#{
#    "storeID"         : { "S": "${var.nameprefix}${count.index}"},
#    "recordType"      : { "S": "store"},
#    "itemID"          : { "N": "98"},
#    "itemDescription" : { "S": "Beemster kaas, 500g"},
#    "stock"           : { "N": "10000" },
#    "sellingPrice"    : { "N": "9.90" },
#    "grossAmount"     : { "N": "0" }
#}
#ITEM
#}
#

##################################################################################
# OUTPUT
##################################################################################

#output "passwords" {
#  value = aws_iam_user_login_profile.AWS_SIG_Login_profile[*].encrypted_password
#}

