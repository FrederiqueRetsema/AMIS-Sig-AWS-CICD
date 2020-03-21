##################################################################################
# VARIABLES
##################################################################################

variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "prefix" {
    default = "AMIS0"
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

#resource "aws_api_gateway_stage" "prod" {
#  stage_name = "prod"
#  rest_api_id = aws_api_gateway_rest_api.API_Gateway.id
#  deployment_id = aws_api_gateway_deployment.deployment_prod.id
#}

# Lambda
resource "aws_lambda_permission" "lambda_permission" {
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

resource "aws_sns_topic" "to_process" {
  name = "${var.prefix}_to_process"
  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1000
    }
  }
}
EOF
}

# SNS subscriptions for lambda process
#resource "aws_sns_topic_subscription" "to_process_subscription_lambda" {
#  topic_arn = aws_sns_topic.to_process.arn
#  protocol  = "lambda"
#  endpoint  = var.email
#}

# Lambda process

#resource "aws_lambda_function" "process" {
#    function_name = "${var.prefix}_process"
#    filename = "./lambdas/process/process.zip"
#    role = data.aws_iam_role.lambda_process_role.arn
#    handler = "process.lambda_handler"
#    runtime = "python3.8"
#    environment {
#        variables = {
#            to_process_topic_arn = aws_sns_topic.to_process.arn
#        }
#    }
#}

# DynamoDB table

#resource "aws_dynamodb_table" "inventory_sales" {
#}


##################################################################################
# OUTPUT
##################################################################################

output "invoke_url" {
  value = aws_api_gateway_deployment.deployment_prod.invoke_url
}

