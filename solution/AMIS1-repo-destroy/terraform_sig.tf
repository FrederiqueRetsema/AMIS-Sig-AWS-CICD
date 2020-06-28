##################################################################################
##################################################################################
# VARIABLES
##################################################################################

# variable "aws_access_key"          {}
# variable "aws_secret_key"          {}
variable "aws_region"                { default = "eu-west-1"}
variable "aws_region_abbr"           { default = "euw1"}

variable "name_prefix"               { default = "AMIS" }
variable "user_prefix"               { default = "AMIS1" }
variable "sig_version"               { default = "v3" }

variable "stage_name"                { default = "prod" }
variable "log_level_api_gateway"     { default = "INFO" }
variable "domainname"                { default = "cloudhotel.org" }

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
# access_key = var.aws_access_key
# secret_key = var.aws_secret_key
  region     = var.aws_region
}

terraform {
    backend "s3" {
        encrypt        = false
        bucket         = "amis-sig-euw1-bucket"
        key            = "terraform/AMIS1/terraform.tfstate"
        dynamodb_table = "AMIS1_state_locking"
        region         = "eu-west-1"
    }
}

