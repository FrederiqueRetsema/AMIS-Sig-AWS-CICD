##################################################################################
# VARIABLES
##################################################################################

# variable "aws_access_key"       {}
# variable "aws_secret_key"       {}
variable "aws_region"             { default = "eu-west-1"}
variable "aws_region_abbr"        { default = "euw1"}

variable "name_prefix"            { default = "AMIS" }
variable "user_prefix"            { default = "AMIS1" }
variable "stage_name"             { default = "prod" }
variable "log_level_api_gateway"  { default = "INFO" }

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
# access_key = var.aws_access_key
# secret_key = var.aws_secret_key
  region     = var.aws_region
}

##################################################################################
# DATA
##################################################################################

data "aws_iam_role" "api_gateway_role" {
    name = "${var.name_prefix}_${var.aws_region_abbr}_api_gateway_role"
}

data "aws_iam_role" "lambda_sig_role" {
    name = "${var.name_prefix}_${var.aws_region_abbr}_lambda_sig_role"
}

##################################################################################
# OTHER RESOURCES
##################################################################################

resource "aws_api_gateway_stage" "stage" {
  stage_name    = var.stage_name
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  deployment_id = aws_api_gateway_deployment.deployment.id
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on  = [aws_api_gateway_integration.integration,aws_api_gateway_rest_api.api_gateway, aws_api_gateway_resource.api_gateway_resource_sig, aws_api_gateway_method.api_gateway_method_post]
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
}

resource "aws_api_gateway_account" "api_gateway_account" {
  cloudwatch_role_arn = data.aws_iam_role.api_gateway_role.arn
}

resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = "${var.user_prefix}_api_gateway"
  description = "API Gateway for the shop example"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "api_gateway_resource_sig" {
  depends_on  = [aws_api_gateway_rest_api.api_gateway]
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "sig"
}

resource "aws_api_gateway_method" "api_gateway_method_post" {
  depends_on     = [aws_api_gateway_rest_api.api_gateway, aws_api_gateway_resource.api_gateway_resource_sig]
  rest_api_id    = aws_api_gateway_rest_api.api_gateway.id
  resource_id    = aws_api_gateway_resource.api_gateway_resource_sig.id
  http_method    = "POST"
  authorization  = "NONE"
  request_models = {"application/json"="Empty"}
}

resource "aws_api_gateway_method_settings" "method_settings" {
  rest_api_id    = aws_api_gateway_rest_api.api_gateway.id
  stage_name     = aws_api_gateway_stage.stage.stage_name
  method_path    = "*/*" 

  settings {
    metrics_enabled    = true
    data_trace_enabled = true
    logging_level      = var.log_level_api_gateway
  }
}

resource "aws_api_gateway_integration" "integration" {
  depends_on              = [aws_api_gateway_rest_api.api_gateway, aws_api_gateway_resource.api_gateway_resource_sig, aws_api_gateway_method.api_gateway_method_post, aws_lambda_function.sig, aws_lambda_permission.lambda_sig_permission]
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.api_gateway_resource_sig.id
  http_method             = aws_api_gateway_method.api_gateway_method_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.sig.invoke_arn
}

# Lambda sig
#
resource "aws_lambda_permission" "lambda_sig_permission" {
  depends_on    = [aws_lambda_function.sig]
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sig.function_name
  principal     = "apigateway.amazonaws.com"
}

resource "aws_lambda_function" "sig" {
    depends_on    = [aws_api_gateway_method.api_gateway_method_post]
    function_name = "${var.user_prefix}_sig"
    filename      = "./lambdas/sig.zip"
    role          = data.aws_iam_role.lambda_sig_role.arn
    handler       = "sig.lambda_handler"
    runtime       = "python3.8"
}

##################################################################################
# OUTPUT
##################################################################################

output "invoke_url" {
  value = "${aws_api_gateway_deployment.deployment.invoke_url}${aws_api_gateway_stage.stage.stage_name}/${aws_api_gateway_resource.api_gateway_resource_sig.path_part}"
}


