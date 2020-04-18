##################################################################################
# VARIABLES
##################################################################################

variable "aws_access_key"         {}
variable "aws_secret_key"         {}
variable "aws_region_name"        {}
variable "aws_region_abbr"        {description = "Is not used in this script. Declaration is done to prevent warnings." }

variable "account_number"         {description = "Is not used in this script. Declaration is done to prevent warnings." }
variable "domainname"             {}

variable "name_prefix"            {}
variable "key_prefix"             {description = "Is not used in this script. Declaration is done to prevent warnings." }

variable "number_of_users"        {description = "Is not used in this script. Declaration is done to prevent warnings." }
variable "offset_number_of_users" {description = "Is not used in this script. Declaration is done to prevent warnings." }

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


##################################################################################
# RESOURCES
##################################################################################

#
# VPC (domain should be connected to VPC)
#

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "${var.name_prefix}-sig"
  }
}

#
# Domain
#

resource "aws_route53_zone" "private" {
  name = var.domainname
  
  vpc {
    vpc_id = aws_vpc.vpc.id
  }
}


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
    zone_id  = aws_route53_zone.private.zone_id
    name     = aws_acm_certificate.certificate.domain_validation_options[0].resource_record_name
    type     = aws_acm_certificate.certificate.domain_validation_options[0].resource_record_type
    records  = [aws_acm_certificate.certificate.domain_validation_options[0].resource_record_value]
    ttl      = "300"
}

##################################################################################
# OUTPUT
##################################################################################


