##################################################################################
# VARIABLES
##################################################################################

variable "aws_access_key"         {}
variable "aws_secret_key"         {}
variable "aws_region_name"        {}
variable "aws_region_abbr"        {}

variable "account_number"         {}
variable "domainname"             {}

variable "name_prefix"            {description = "Is not used in this script. Declaration is done to prevent warnings." }
variable "key_prefix"             {description = "Is not used in this script. Declaration is done to prevent warnings." }

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
##################################################################################

data "aws_route53_zone" "my_zone" {
    name         = var.domainname
    private_zone = false
}

##################################################################################
# RESOURCES
##################################################################################

#
# Certificate: needed for use of domain within API gateway
#

resource "aws_acm_certificate" "certificate" {
  domain_name       = "*.${var.domainname}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

#
# Check record in Route53: AWS will use this to look if you are the owner of 
# the domain that the certificate is requested for.
#

resource "aws_route53_record" "certificate_check_record" {
    zone_id  = data.aws_route53_zone.my_zone.zone_id
    name     = aws_acm_certificate.certificate.domain_validation_options[0].resource_record_name
    type     = aws_acm_certificate.certificate.domain_validation_options[0].resource_record_type
    records  = [aws_acm_certificate.certificate.domain_validation_options[0].resource_record_value]
    ttl      = "300"
}

##################################################################################
# OUTPUT
##################################################################################


