##################################################################################
# VARIABLES
##################################################################################

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region"     {}

variable "domainname"     {}

variable "name_prefix"    {}
variable "user_prefix"    {}
variable "key_prefix"     {}

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

data "aws_iam_role" "lambda_accept_role" {
    name = "${var.name_prefix}_CICD_lambda_accept_role"
}

data "aws_iam_role" "lambda_decrypt_role" {
    name = "${var.name_prefix}_CICD_lambda_decrypt_role"
}

data "aws_iam_role" "lambda_process_role" {
    name = "${var.name_prefix}_CICD_lambda_process_role"
}

data "aws_acm_certificate" "domain_certificate" {
    domain = "*.${var.domainname}"
}

data "aws_route53_zone" "my_zone" {
    name = var.domainname
}

##################################################################################
# RESOURCES
#
# Order: from client to DynamoDB
# - Connection to certificate
# - Route53
# - API Gateway
# - Lambda function accept
# - SNS topic to_decrypt
# - Lambda function decrypt
# - SNS topic to_process
# - Lambda function process
##################################################################################

#
# Connection to certificate
#
# Is needed to be sure that the certificate is validated
#

resource "aws_acm_certificate_validation" "mycertificate_validation" {
    certificate_arn = data.aws_acm_certificate.domain_certificate.arn
}

#
# Route 53
# 
# DNS-entry for <user_prefix>.<your domainname>, will point to the gateway domain
#

resource "aws_route53_record" "my_shop_dns_record" {
    zone_id = data.aws_route53_zone.my_zone.zone_id
    name    = lower(var.user_prefix)
    type    = "A"

    alias {
        name                   = aws_api_gateway_domain_name.API_Gateway_domain_name.regional_domain_name
        zone_id                = aws_api_gateway_domain_name.API_Gateway_domain_name.regional_zone_id
        evaluate_target_health = true
    }
}

#
# API Gateway
#
# These objects are defined in the order in which they are used from Route53, via the moment the POST 
# request is done to the API gateway, to the Lambda function it is calling:
# - aws_api_gateway_base_path_mapping : will define what stage and what method (if any, not used here)
#                                       is used when the DNS record is used. You can have multiple 
#                                       mappings (f.e. for multiple stages, or including the 
#                                       "resource" path - or not) for one domain.
#                                       This mapping is only used when you use a route 53 DNS entry 
#                                       to go to the API gateway)
# - aws_api_gateway_domain_name       : links the name of the domain (and the certificate) to the 
#                                       API gateway that it is using
#                                       (only used when you use a route 53 DNS entry to go to the 
#                                        API gateway)
# - aws_api_gateway_deployment        : is the version of the API. We only use prod in our
#                                       example. This is also the object that contains the DNS
#                                       for the API, f.e.
#                                       https://4rgbh0ivlf.execute-api.eu-west-1.amazonaws.com/prod )
# - aws_api_gateway_rest_api          : the API gateway itself. Is also used when you use the 
#                                       DNS-name that the API gateway provides you (f.e.
# - aws_api_gateway_resource          : this is the "/shop" part of the URL. 
# - aws_api_gateway_method            : this is the way the "/shop" part is addressed. In our example,
#                                       this is POST (could also have been GET)
# - aws_api_gateway_integration       : is the connection between the API gateway and the Lambda 
#                                       function that is behind it. 
#

resource "aws_api_gateway_base_path_mapping" "map_shop_prod_to_api_gateway_domain" {
  api_id = aws_api_gateway_rest_api.API_Gateway.id
  stage_name = aws_api_gateway_deployment.deployment_prod.stage_name
  domain_name = aws_api_gateway_domain_name.API_Gateway_domain_name.domain_name
}

resource "aws_api_gateway_domain_name" "API_Gateway_domain_name" {
  domain_name              = "${lower(var.user_prefix)}.${var.domainname}"
  regional_certificate_arn = aws_acm_certificate_validation.mycertificate_validation.certificate_arn
  security_policy          = "TLS_1_2"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "deployment_prod" {
  depends_on  = [aws_api_gateway_integration.integration]
  rest_api_id = aws_api_gateway_rest_api.API_Gateway.id
  stage_name  = "prod"
}

resource "aws_api_gateway_rest_api" "API_Gateway" {
  name        = "${var.user_prefix}_API_Gateway"
  description = "Part of workshop on 01-07-2020"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "API_Gateway_resource_shop" {
  rest_api_id = aws_api_gateway_rest_api.API_Gateway.id
  parent_id   = aws_api_gateway_rest_api.API_Gateway.root_resource_id
  path_part   = "shop"
}

resource "aws_api_gateway_method" "API_Gateway_method" {
  rest_api_id    = aws_api_gateway_rest_api.API_Gateway.id
  resource_id    = aws_api_gateway_resource.API_Gateway_resource_shop.id
  http_method    = "POST"
  authorization  = "NONE"
  request_models = {"application/json"="Empty"}
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.API_Gateway.id
  resource_id             = aws_api_gateway_resource.API_Gateway_resource_shop.id
  http_method             = aws_api_gateway_method.API_Gateway_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.accept.invoke_arn
}

#
# Lambda accept
#
# These objects are defined in the order in which they are used from the call 
# from the API gateway to the SNS topic:
# - aws_lambda_permissions: connection between the API gateway (which needs 
#                           permission to call this specific Lambda function)
#                           and the Lambda function accept.
# - aws_lambda_function:    the actual Lambda function. The use of a zip file
#                           is mandatory in Terraform.
#                           We use environment variables to pass the AWS Resource Name (ARN) of the
#                           SNS topic to the Lambda code.
# 
resource "aws_lambda_permission" "lambda_accept_permission" {
  depends_on    = [aws_lambda_function.accept, aws_api_gateway_integration.integration]
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.accept.function_name
  principal     = "apigateway.amazonaws.com"
}

resource "aws_lambda_function" "accept" {
    depends_on    = [aws_api_gateway_resource.API_Gateway_resource_shop]
    function_name = "${var.user_prefix}_accept"
    filename      = "./lambdas/accept/accept.zip"
    role          = data.aws_iam_role.lambda_accept_role.arn
    handler       = "accept.lambda_handler"
    runtime       = "python3.8"
    environment {
        variables = {
            to_decrypt_topic_arn = aws_sns_topic.to_decrypt.arn
        }
    }
}

# SNS topic to_decrypt
#
# These objects are defined in the order in which they are used from the call 
# from Lambda function accept to the delivery to the Lambda function 
# decrypt:
# - aws_sns_topic:              topic of the SNS messaging system
# - aws_sns_topic_subscription: subscribers to the topic

resource "aws_sns_topic" "to_decrypt" {
  name = "${var.user_prefix}_to_decrypt"
}

resource "aws_sns_topic_subscription" "decrypt_to_lambda" {
  topic_arn  = aws_sns_topic.to_decrypt.arn
  protocol   = "lambda"
  endpoint   = aws_lambda_function.decrypt.arn
}

# Lambda decrypt
#
# These objects are defined in the order in which they are used from the call 
# from the SNS topic to the lambda function:
# - aws_lambda_permissions: connection between the SNS topic to_decrypt (which needs
#                           permission to call this specific Lambda function)
#                           and the Lambda function decrypt.
# - aws_lambda_function:    the actual Lambda function. The use of a zip file
#                           is mandatory in Terraform.
#                           We use environment variables to pass the AWS Resource Name (ARN) of the
#                           SNS topic and the key prefix to the Lambda code.

resource "aws_lambda_permission" "lambda_decrypt_permission" {
  depends_on    = [aws_lambda_function.decrypt,aws_sns_topic.to_decrypt]
  statement_id  = "AllowExecutionFromSNSToDecrypt"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.decrypt.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.to_decrypt.arn
}

resource "aws_lambda_function" "decrypt" {
    function_name = "${var.user_prefix}_decrypt"
    filename      = "./lambdas/decrypt/decrypt.zip"
    role          = data.aws_iam_role.lambda_decrypt_role.arn
    handler       = "decrypt.lambda_handler"
    runtime       = "python3.8"
    environment {
        variables = {
            key_prefix           = var.key_prefix,
            to_process_topic_arn = aws_sns_topic.to_process.arn
        }
    }
}

# SNS topic to_process
#
# These objects are defined in the order in which they are used from the call 
# from Lambda function decrypt to the delivery to the Lambda function 
# process:
# - aws_sns_topic:              topic of the SNS messaging system
# - aws_sns_topic_subscription: subscribers to the topic

resource "aws_sns_topic" "to_process" {
  name = "${var.user_prefix}_to_process"
}

resource "aws_sns_topic_subscription" "process_to_lambda" {
  topic_arn = aws_sns_topic.to_process.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.process.arn
}

# Lambda process
#
# These objects are defined in the order in which they are used from the call 
# from the SNS topic to the lambda function:
# - aws_lambda_permissions: connection between the SNS topic to_process (which needs
#                           permission to call this specific Lambda function)
#                           and the Lambda function process.
# - aws_lambda_function:    the actual Lambda function. The use of a zip file
#                           is mandatory in Terraform.

resource "aws_lambda_permission" "lambda_process_permission" {
  depends_on    = [aws_lambda_function.process, aws_sns_topic.to_process]
  statement_id  = "AllowExecutionFromSNSToProcess"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.to_process.arn
}

resource "aws_lambda_function" "process" {
    function_name = "${var.user_prefix}_process"
    filename = "./lambdas/process/process.zip"
    role = data.aws_iam_role.lambda_process_role.arn
    handler = "process.lambda_handler"
    runtime = "python3.8"
}

##################################################################################
# OUTPUT
#
# The output is needed for people who don't have (or don't want to use) a
# domain in Route53
##################################################################################

output "invoke_url" {
  value = "${aws_api_gateway_deployment.deployment_prod.invoke_url}/${aws_api_gateway_resource.API_Gateway_resource_shop.path_part}"
}

