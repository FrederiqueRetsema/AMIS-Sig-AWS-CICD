##################################################################################
# VARIABLES
##################################################################################

variable "aws_access_key"         {}
variable "aws_secret_key"         {}
variable "aws_region"             {}

variable "use_public_domain"      {}
variable "domainname"             {}

variable "name_prefix"            {}

variable "stage_name"             { default = "prod" }
variable "log_level_api_gateway"  { default = "INFO" }

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

data "aws_iam_role" "api_gateway_role" {
    name = "${var.name_prefix}_api_gateway_role"
}

data "aws_iam_role" "lambda_role" {
    name = "${var.name_prefix}_lambda_role"
}

data "aws_acm_certificate" "domain_certificate" {
    count  = var.use_public_domain
    domain = "*.${var.domainname}"
}

data "aws_route53_zone" "my_zone" {
    count  = var.use_public_domain
    name = var.domainname
}

##################################################################################
# RESOURCES
##################################################################################

resource "aws_acm_certificate_validation" "mycertificate_validation" {
    count = var.use_public_domain
    certificate_arn = data.aws_acm_certificate.domain_certificate[count.index].arn
}

resource "aws_route53_record" "myshop_dns_record" {
    count   = var.use_public_domain
    zone_id = data.aws_route53_zone.my_zone[count.index].zone_id
    name    = lower(var.name_prefix)
    type    = "A"

    alias {
        name                   = aws_api_gateway_domain_name.api_gateway_domain_name[count.index].regional_domain_name
        zone_id                = aws_api_gateway_domain_name.api_gateway_domain_name[count.index].regional_zone_id
        evaluate_target_health = true
    }
}

#
# API Gateway
#

resource "aws_api_gateway_base_path_mapping" "map_shop_stage_name_to_api_gateway_domain" {
  count       = var.use_public_domain
  depends_on  = [aws_api_gateway_rest_api.api_gateway, aws_api_gateway_deployment.deployment, aws_api_gateway_domain_name.api_gateway_domain_name]
  api_id      = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = aws_api_gateway_stage.stage.stage_name
  domain_name = aws_api_gateway_domain_name.api_gateway_domain_name[count.index].domain_name
}

resource "aws_api_gateway_domain_name" "api_gateway_domain_name" {
  count                    = var.use_public_domain
  domain_name              = "${lower(var.name_prefix)}.${var.domainname}"
  regional_certificate_arn = aws_acm_certificate_validation.mycertificate_validation[count.index].certificate_arn
  security_policy          = "TLS_1_2"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

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
  name        = "${var.name_prefix}_api_gateway"
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
  depends_on              = [aws_api_gateway_rest_api.api_gateway, aws_api_gateway_resource.api_gateway_resource_sig, aws_api_gateway_method.api_gateway_method_post, aws_lambda_function.accept, aws_lambda_permission.lambda_accept_permission]
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.api_gateway_resource_sig.id
  http_method             = aws_api_gateway_method.api_gateway_method_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.accept.invoke_arn
}

# Lambda sig
#
resource "aws_lambda_permission" "lambda_sig_permission" {
  depends_on    = [aws_lambda_function.accept]
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sig.function_name
  principal     = "apigateway.amazonaws.com"
}

resource "aws_lambda_function" "sig" {
    depends_on    = [aws_api_gateway_method.api_gateway_method_post]
    function_name = "${var.name_prefix}_sig"
    filename      = "./lambdas/sig.zip"
    role          = data.aws_iam_role.lambda_sig_role.arn
    handler       = "accept.lambda_handler"
    runtime       = "python3.8"
}

##################################################################################
# OUTPUT
##################################################################################

output "invoke_url" {
  value = "${aws_api_gateway_deployment.deployment.invoke_url}${aws_api_gateway_stage.stage.stage_name}/${aws_api_gateway_resource.api_gateway_resource_sig.path_part}"
}

