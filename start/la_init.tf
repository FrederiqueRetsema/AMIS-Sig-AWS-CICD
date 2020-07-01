##################################################################################
# VARIABLES
##################################################################################

# variable "aws_access_key"       {}
# variable "aws_secret_key"       {}
variable "aws_region"             { default = "us-east-1"}

variable "name_prefix"            { default = "AMIS" }
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

data "aws_iam_policy" "AmazonAPIGatewayPushToCloudWatchLogs" {
    arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs" 
}

##################################################################################
# RESOURCES
##################################################################################

resource "aws_iam_role" "api_gateway_role" {
    name                  = "${var.name_prefix}_api_gateway_role"
    description           =  "Needed to log what happens in the API Gateway."
    force_detach_policies = true
    assume_role_policy    =  <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "apigateway.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
} 

resource "aws_iam_policy_attachment" "policy_to_cloudwatch_role" {
    name       = "${var.name_prefix}_policy_to_cloudwatch_role"
    roles      = [aws_iam_role.api_gateway_role.name]
    policy_arn = data.aws_iam_policy.AmazonAPIGatewayPushToCloudWatchLogs.arn
}

resource "aws_iam_role" "lambda_sig_role" {
    name                  = "${var.name_prefix}_lambda_sig_role"
    description           =  "Lambda sig function role"
    force_detach_policies = true
    assume_role_policy    =  <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
} 

resource "aws_iam_policy_attachment" "policy_to_sig_role" {
   name       = "${var.name_prefix}_policy_to_sig_role"
   roles      = [aws_iam_role.lambda_sig_role.name]
   policy_arn = aws_iam_policy.lambda_sig_policy.arn
}

resource "aws_iam_policy" "lambda_sig_policy" {
    name        = "${var.name_prefix}_lambda_sig_policy"
    description = "Policy for the Lambda sig function"
    policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
		  "logs:CreateLogGroup",
		  "logs:CreateLogStream",
		  "logs:PutLogEvents",
		  "sns:Publish"
        ],
		"Effect": "Allow",
		"Resource": "*",
                "Condition": {
                   "StringEquals": {
                       "aws:RequestedRegion": "${var.aws_region}"
                   }
                }
	}
      ]
}
EOF
}
