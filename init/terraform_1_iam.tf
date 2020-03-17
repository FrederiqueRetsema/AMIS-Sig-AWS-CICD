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

#resource "aws_kms_key" "amis" {
#  count                    = var.number_of_users
#  description              = "${var.nameprefix}${count.index}"
#  key_usage                = "ENCRYPT_DECRYPT"
#  customer_master_key_spec = "RSA_2048"
#  
#}

#resource "aws_kms_alias" "amis" {
#  count          = var.number_of_users
#  name           = "alias/${var.nameprefix}${count.index}"
#  target_key_id  = aws_kms_key.amis[count.index].key_id 
#}

resource "aws_iam_policy" "AMIS_CICD_policy" {
    name = "AMIS_CICD_Policy"
	description = "Policy for CD CD workshop on 01-07-2020. More info Frederique Retsema 06-823 90 591."
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
		  "lambda:*",
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

##################################################################################
# OUTPUT
##################################################################################

#output "passwords" {
#  value = aws_iam_user_login_profile.AWS_SIG_Login_profile[*].encrypted_password
#}

