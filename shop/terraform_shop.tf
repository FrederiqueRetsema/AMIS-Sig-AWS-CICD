##################################################################################
# VARIABLES
##################################################################################

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "domainname"     {}

variable "prefix" {
    default = "AMIS0"
}

variable "key-prefix" {
    default = "KeyG-"
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

data "aws_iam_role" "lambda_accept_role" {
    name = "AMIS_CICD_lambda_accept_role"
}

data "aws_iam_role" "lambda_decrypt_role" {
    name = "AMIS_CICD_lambda_decrypt_role"
}

data "aws_iam_role" "lambda_process_role" {
    name = "AMIS_CICD_lambda_process_role"
}

data "aws_acm_certificate" "mydomain_certificate" {
    domain = "*.${var.domainname}"
}

data "aws_route53_zone" "my_zone" {
    name = var.domainname
}

##################################################################################
# RESOURCES
##################################################################################

# Route 53

resource "aws_route53_record" "my_shop_dns_record" {
    zone_id = data.aws_route53_zone.my_zone.zone_id
    name    = lower(var.prefix)
    type    = "A"

    alias {
        name                   = aws_api_gateway_domain_name.API_Gateway_domain_name.regional_domain_name
        zone_id                = aws_api_gateway_domain_name.API_Gateway_domain_name.regional_zone_id
        evaluate_target_health = true
    }
}

# Connection to certificate

resource "aws_acm_certificate_validation" "mycertificate_validation" {
    certificate_arn = data.aws_acm_certificate.mydomain_certificate.arn
}

# API Gateway

resource "aws_api_gateway_domain_name" "API_Gateway_domain_name" {
  domain_name              = "${lower(var.prefix)}.${var.domainname}"
  regional_certificate_arn = aws_acm_certificate_validation.mycertificate_validation.certificate_arn
  security_policy = "TLS_1_2"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "map_shop_prod_to_api_gateway_domain" {
  api_id = aws_api_gateway_rest_api.API_Gateway.id
  stage_name = aws_api_gateway_deployment.deployment_prod.stage_name
  domain_name = aws_api_gateway_domain_name.API_Gateway_domain_name.domain_name
}

resource "aws_api_gateway_rest_api" "API_Gateway" {
  name        = "${var.prefix}_API_Gateway"
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

resource "aws_api_gateway_deployment" "deployment_prod" {
  depends_on = [aws_api_gateway_integration.integration]
  rest_api_id = aws_api_gateway_rest_api.API_Gateway.id
  stage_name = "prod"
}

# Lambda
resource "aws_lambda_permission" "lambda_accept_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.accept.function_name
  principal     = "apigateway.amazonaws.com"
}

# Lambda accept

resource "aws_lambda_function" "accept" {
    function_name = "${var.prefix}_accept"
    filename = "./lambdas/accept/accept.zip"
    role = data.aws_iam_role.lambda_accept_role.arn
    handler = "accept.lambda_handler"
    runtime = "python3.8"
    environment {
        variables = {
            to_decrypt_topic_arn = aws_sns_topic.to_decrypt.arn
        }
    }
}

# SNS topic to_decrypt
# - For a description of the resend policies for Lambda, see https://docs.aws.amazon.com/sns/latest/dg/sns-message-delivery-retries.html

resource "aws_sns_topic" "to_decrypt" {
  name = "${var.prefix}_to_decrypt"
}

resource "aws_sns_topic_subscription" "decrypt_to_lambda" {
  topic_arn = aws_sns_topic.to_decrypt.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.decrypt.arn
}

# Lambda permission
resource "aws_lambda_permission" "lambda_decrypt_permission" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.decrypt.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.to_decrypt.arn
}

# Lambda process

resource "aws_lambda_function" "decrypt" {
    function_name = "${var.prefix}_decrypt"
    filename = "./lambdas/decrypt/decrypt.zip"
    role = data.aws_iam_role.lambda_decrypt_role.arn
    handler = "decrypt.lambda_handler"
    runtime = "python3.8"
    environment {
        variables = {
            key_prefix           = var.key-prefix,
            to_process_topic_arn = aws_sns_topic.to_process.arn
        }
    }
}

# SNS topic to_process
# - For a description of the resend policies for Lambda, see https://docs.aws.amazon.com/sns/latest/dg/sns-message-delivery-retries.html

resource "aws_sns_topic" "to_process" {
  name = "${var.prefix}_to_process"
}

resource "aws_sns_topic_subscription" "process_to_lambda" {
  topic_arn = aws_sns_topic.to_process.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.process.arn
}

# Lambda permission
resource "aws_lambda_permission" "lambda_process_permission" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.to_process.arn
}

# Lambda process

resource "aws_lambda_function" "process" {
    function_name = "${var.prefix}_process"
    filename = "./lambdas/process/process.zip"
    role = data.aws_iam_role.lambda_process_role.arn
    handler = "process.lambda_handler"
    runtime = "python3.8"
    environment {
        variables = {
            key_prefix = var.key-prefix
        }
    }
}

##################################################################################
# OUTPUT
##################################################################################

output "invoke_url" {
  value = aws_api_gateway_deployment.deployment_prod.invoke_url
}

