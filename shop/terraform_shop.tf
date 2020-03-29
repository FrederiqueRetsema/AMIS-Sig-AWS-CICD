##################################################################################
# VARIABLES
##################################################################################

variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "prefix" {
    default = "AMIS0"
}

variable "key-prefix" {
    default = "KeyD-"
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

data "aws_iam_role" "lambda_process_role" {
    name = "AMIS_CICD_lambda_process_role"
}

##################################################################################
# RESOURCES
##################################################################################

# API Gateway

resource "aws_api_gateway_rest_api" "API_Gateway" {
  name        = "${var.prefix}_API_Gateway"
  description = "Part of workshop on 01-07-2020"
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

