##################################################################################
# VARIABLES
##################################################################################

variable "aws_access_key"         {}
variable "aws_secret_key"         {}
variable "aws_region_name"        {}
variable "aws_region_abbr"        {}

variable "account_number"         {}
variable "domain_name"            { description = "Is not used in this script. Declaration is done to prevent warnings." }

variable "name_prefix"            {}
variable "pub_key"                {}

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
#
# Amazon AMI: https://www.hashicorp.com/blog/hashicorp-terraform-supports-amazon-linux-2/
##################################################################################

data "aws_route53_zone" "zone" {
    name         = var.domain_name
}

data "aws_iam_policy" "AmazonAPIGatewayPushToCloudWatchLogs" {
    arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs" 
}

data "aws_ami" "amazon_linux_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

}

#  tags = { Name = var.name_prefix }
data "aws_vpc" "vpc" {
}

##################################################################################
# RESOURCES
##################################################################################

# IAM Objects
# -----------

resource "aws_iam_policy" "user_policy" {
    name        = "${var.name_prefix}_${var.aws_region_abbr}_user_policy"
    description = "Policy for CI CD workshop on 09-07-2020."
    policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
                "s3:*"
                ],
                "Effect": "Allow",
                "Resource": ["arn:aws:s3:::${lower(var.name_prefix)}-sig-${lower(var.aws_region_abbr)}-bucket",
                             "arn:aws:s3:::${lower(var.name_prefix)}-sig-${lower(var.aws_region_abbr)}-bucket/*",
                             "arn:aws:s3:::codepipeline*",
                             "arn:aws:s3:::codepipeline*/*"]
      },
      {
        "Action": [
           "s3:*"
        ],
        "Effect": "Deny",
        "Resource": ["arn:aws:s3:::frpublic",
                     "arn:aws:s3:::frpublic/*",
                     "arn:aws:s3:::tsofra-laptop",
                     "arn:aws:s3:::tsofra-laptop/*",
                     "arn:aws:s3:::aws-bills-tsofra",
                     "arn:aws:s3:::aws-bills-tsofra/*"]
      },
      {
        "Action": [
                  "route53:ListHostedZones",
                  "route53:ListHealthChecks",
                  "route53:GetHostedZoneCount",
                  "route53:ListTrafficPolicies",
                  "route53:GetTrafficPolicyInstance",
                  "route53:GetTrafficPolicyInstanceCount",
                  "route53:GetHealthCheck",
                  "route53:GetHealthCheckCount",
                  "route53:GetChange",
                  "route53domains:ListDomains",
                  "iam:ListUsers",
                  "iam:ListGroups",
                  "iam:ListRoles",
                  "iam:ListPolicies",
                  "iam:ListInstanceProfiles",
                  "iam:GetServiceLastAccessedDetails",
                  "s3:GetBucketLocation",
                  "s3:ListAllMyBuckets"
		],
		"Effect": "Allow",
		"Resource": "*"
      },
      {
        "Action": [
                  "iam:ListUserPolicies",
                  "iam:ListUserTags",
                  "iam:ListSSHPublicKeys",
                  "iam:ListAccessKeys",
                  "iam:ListServiceSpecificCredentials",
                  "iam:ListAttachedUserPolicies",
                  "iam:ListGroupsForUser",
                  "iam:GetUser",
                  "iam:GenerateServiceLastAccessedDetails",
                  "iam:ListPoliciesGrantingServiceAccess"
                ],
                "Effect": "Allow",
                "Resource": "arn:aws:iam::300577164517:user/AMIS*"
      },
      {
        "Action": [
                  "iam:ListGroupPolicies",
                  "iam:ListAttachedGroupPolicies"
                ],
                "Effect": "Allow",
                "Resource": "arn:aws:iam::300577164517:group/AMIS*"
      },
      {
        "Action": [
                  "acm:ListCertificates",
                  "acm:ListTagsForCertificate",
                  "acm:DescribeCertificate",
                  "cloudformation:DescribeStacks",
                  "cloudformation:DescribeStackResources",
                  "ec2:ListInstanceProfiles",
                  "ec2:DescribeInstances",
                  "ec2:DescribeInstanceStatus",
                  "ec2:DescribeIamInstanceProfileAssociations",
                  "ec2:DescribeVpcs",
                  "ec2:DescribeSecurityGroups",
                  "ec2:DescribeSubnets",
                  "ec2:StartInstanceStatus",
                  "ec2:StopInstances",
                  "ec2:StartInstances",
                  "ecr:DescribeRepositories",
                  "ecr:ListImages",
                  "elasticfilesystem:DescribeFileSystems",
                  "events:DeleteRule",
                  "events:DescribeRule",
                  "events:DisableRule",
                  "events:EnableRule",
                  "events:ListTargetsByRule",
                  "events:ListRules",
                  "events:ListRuleNamesByTarget",
                  "events:PutRule",
                  "events:PutTargets",
                  "events:RemoveTargets",
                  "codecommit:*",
                  "codeartifact:*",
                  "codebuild:*",
                  "codedeploy:*",
                  "codepipeline:*",
                  "apigateway:*",
                  "lambda:*",
                  "dynamodb:*",
                  "cloudwatch:GetMetricStatistics",
                  "cloudwatch:DescribeAlarms",
                  "logs:*",
                  "codeguru-reviewer:ListCodeReviews",
                  "codestar-notifications:ListNotificationRules",
                  "codeguru-reviewer:ListRepositoryAssociations",
                  "waf:ListWebACLs",
                  "waf:AssociateWebACL",
                  "wafv2:ListWebACLs",
                  "wafv2:AssociateWebACL",
                  "waf-regional:ListWebACLs",
                  "waf-regional:AssociateWebACL"
		],
		"Effect": "Allow",
		"Resource": "*",
                "Condition": {
                   "StringEquals": {
                       "aws:RequestedRegion": "${var.aws_region_name}"
                   }
                }
      },
      {
       "Action": [
                   "iam:CreateRole",
                   "iam:AttachRolePolicy"
                 ],
                 "Effect": "Allow",
                 "Resource": "arn:aws:iam::${var.account_number}:role/service-role/cwe-role-${var.aws_region_name}-*"
      },
      {
       "Action": [
                   "iam:CreatePolicy",
                   "iam:CreatePolicyVersion",
                   "iam:DeletePolicyVersion"
                 ],
                 "Effect": "Allow",
                 "Resource": "*",
                 "Condition": {
                    "ArnNotLike": {
                        "aws:SourceArn": ["arn:aws:iam::${var.account_number}:policy/${var.name_prefix}*",
                                          "arn:aws:iam::${var.account_number}:policy/FRA*"]
                 }
            }
      },
      {
            "Effect": "Allow",
            "Action": [
                "ssm:PutParameter"
            ],
            "Resource": "arn:aws:ssm:*:*:parameter/CodeBuild/*"
      },
      {
            "Effect": "Allow",
            "Action": [
                "codestar-notifications:CreateNotificationRule",
                "codestar-notifications:DescribeNotificationRule",
                "codestar-notifications:UpdateNotificationRule",
                "codestar-notifications:DeleteNotificationRule",
                "codestar-notifications:Subscribe",
                "codestar-notifications:Unsubscribe"
            ],
            "Resource": "*",
            "Condition": {
                "StringLike": {
                    "codestar-notifications:NotificationsForResource": "arn:aws:codebuild:*"
                }
            }
      },
      {
            "Effect": "Allow",
            "Action": [
                "codestar-notifications:ListNotificationRules",
                "codestar-notifications:ListEventTypes",
                "codestar-notifications:ListTargets",
                "codestar-notifications:ListTagsforResource"
            ],
            "Resource": "*"
      },
      {

        "Action": [
                  "route53:ListResourceRecordSets",
                  "route53:ListTagsForResource",
                  "route53:GetHostedZone",
                  "route53:ChangeResourceRecordSets"
                ],
		"Effect": "Allow",
	        "Resource": "arn:aws:route53:::hostedzone/${data.aws_route53_zone.zone.zone_id}"
      },
      {
        "Action": [
                  "iam:ListRolePolicies",
                  "iam:ListAttachedRolePolicies",
                  "iam:GetRole",
                  "iam:GetPolicy",
                  "iam:GetPolicyVersion"
		],
		"Effect": "Allow",
		"Resource": ["arn:aws:iam::${var.account_number}:role/${var.name_prefix}*",
                             "arn:aws:iam::${var.account_number}:policy/${var.name_prefix}*",
                             "arn:aws:iam::${var.account_number}:role/service-role/cwe-role-${var.aws_region_name}-*"]
      },
      {
         "Action": [
                   "iam:PassRole"
                   ],
         "Effect": "Allow",
         "Resource": [ "arn:aws:iam::*:role/AMIS_${var.aws_region_abbr}_codebuild_role"]
      },
      {
         "Action": [
                   "iam:PassRole"
                   ],
         "Effect": "Allow",
         "Resource": [ "arn:aws:iam::*:role/service-role/cwe-role-*"],
         "Condition": {
            "StringEquals": {
               "iam:PassedToService": [
                 "events.amazonaws.com"
               ]
             }
         }
      },
      {
        "Action": [
                "iam:PassRole"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": [
                        "codepipeline.amazonaws.com"
                    ]
                }
            }
      },
      {
        "Action": [
                  "kms:GetPublicKey"
		],
		"Effect": "Allow",
		"Resource": "arn:aws:kms:${var.aws_region_name}:${var.account_number}:*"
      }
   ]
}
EOF
}

# Lambda sig policy

resource "aws_iam_policy" "lambda_sig_policy" {
    name        = "${var.name_prefix}_${var.aws_region_abbr}_lambda_sig_policy"
    description = "Policy for CI CD workshop on 09-07-2020."
    policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
		  "logs:CreateLogGroup",
		  "logs:CreateLogStream",
		  "logs:PutLogEvents"
        ],
		"Effect": "Allow",
		"Resource": "*",
                "Condition": {
                   "StringEquals": {
                       "aws:RequestedRegion": "${var.aws_region_name}"
                   }
                }
	}
      ]
}
EOF
}

resource "aws_iam_policy" "lambda_stop_ec2_policy" {
    name        = "${var.name_prefix}_${var.aws_region_abbr}_lambda_stop_ec2_policy"
    description = "Policy for CI CD workshop on 09-07-2020."
    policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
		  "logs:CreateLogGroup",
		  "logs:CreateLogStream",
		  "logs:PutLogEvents"
        ],
		"Effect": "Allow",
		"Resource": "*",
                "Condition": {
                   "StringEquals": {
                       "aws:RequestedRegion": "${var.aws_region_name}"
                   }
                }
      },
      {
        "Action": [
		  "ec2:DescribeInstances",
		  "ec2:StopInstances"
        ],
		"Effect": "Allow",
		"Resource": "*",
                "Condition": {
                   "StringEquals": {
                       "aws:RequestedRegion": "${var.aws_region_name}"
                   }
                }
	}
      ]
}
EOF
}

# EC2 policy

resource "aws_iam_policy" "ec2_policy" {
    name        = "${var.name_prefix}_${var.aws_region_abbr}_EC2_policy"
    description = "Policy for CI CD workshop on 09-07-2020."
    policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
            "codecommit:*",
            "codebuild:*",
            "apigateway:*",
	    "lambda:*",
            "dynamodb:*",
            "ec2:DescribeAccounts",
            "acm:ListCertificates",
            "acm:DescribeCertificate",
            "acm:ListTagsForCertificate",
	    "logs:CreateLogGroup",
	    "logs:CreateLogStream",
	    "logs:PutLogEvents",
            "dynamodb:GetItem",
            "dynamodb:PutItem"
         ],
	"Effect": "Allow",
	"Resource": "*",
        "Condition": {
            "StringEquals": {
                "aws:RequestedRegion": "${var.aws_region_name}"
            }
        }
      },
      {
        "Action": [
           "s3:*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Action": [
           "s3:*"
        ],
        "Effect": "Deny",
        "Resource": ["arn:aws:s3:::frpublic",
                     "arn:aws:s3:::tsofra-laptop",
                     "arn:aws:s3:::aws-bills-tsofra"]
      },
      {
        "Action": [
           "route53:GetHostedZone",
           "route53:ListTagsForResource",
           "route53:ChangeResourceRecordSets",
           "route53:ListResourceRecordSets"
        ],
        "Effect": "Allow",
	"Resource": "arn:aws:route53:::hostedzone/${data.aws_route53_zone.zone.zone_id}"
      },
      {
        "Action": [
                "iam:PassRole",
                "iam:GetRole",
                "route53:ListHostedZones",
                "route53:GetChange"
         ],
	"Effect": "Allow",
	"Resource": "*"
      }
    ]
}
EOF
}

resource "aws_iam_policy" "codebuild_policy" {
    name        = "${var.name_prefix}_${var.aws_region_abbr}_codebuild_policy"
    description = "Policy for CI CD workshop on 09-07-2020."
    policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
            "codecommit:*",
            "codebuild:*",
            "apigateway:*",
	    "lambda:*",
            "dynamodb:*",
            "ec2:DescribeAccounts",
            "acm:ListCertificates",
            "acm:DescribeCertificate",
            "acm:ListTagsForCertificate",
	    "logs:CreateLogGroup",
	    "logs:CreateLogStream",
	    "logs:PutLogEvents",
            "dynamodb:GetItem",
            "dynamodb:PutItem"
         ],
	"Effect": "Allow",
	"Resource": "*",
        "Condition": {
            "StringEquals": {
                "aws:RequestedRegion": "${var.aws_region_name}"
            }
        }
      },
      {
        "Action": [
           "s3:*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Action": [
           "s3:*"
        ],
        "Effect": "Deny",
        "Resource": ["arn:aws:s3:::frpublic",
                     "arn:aws:s3:::tsofra-laptop",
                     "arn:aws:s3:::aws-bills-tsofra"]
      },
      {
        "Action": [
           "route53:GetHostedZone",
           "route53:ListTagsForResource",
           "route53:ChangeResourceRecordSets",
           "route53:ListResourceRecordSets"
        ],
        "Effect": "Allow",
	"Resource": "arn:aws:route53:::hostedzone/${data.aws_route53_zone.zone.zone_id}"
      },
      {
        "Action": [
                "iam:PassRole",
                "iam:GetRole",
                "route53:ListHostedZones",
                "route53:GetChange"
         ],
	"Effect": "Allow",
	"Resource": "*"
      }
    ]
}
EOF
}

resource "aws_iam_policy" "codepipeline_policy" {
    name        = "${var.name_prefix}_${var.aws_region_abbr}_codepipeline_policy"
    description = "Policy for CI CD workshop on 09-07-2020."
    policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "iam:PassRole"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Condition": {
                "StringEqualsIfExists": {
                    "iam:PassedToService": [
                        "cloudformation.amazonaws.com",
                        "elasticbeanstalk.amazonaws.com",
                        "ec2.amazonaws.com",
                        "ecs-tasks.amazonaws.com"
                    ]
                },
                "StringEquals": {
                    "aws:RequestedRegion": "${var.aws_region_name}"
                }
            }
        },
        {
            "Action": [
                "codecommit:*",
                "codestar-connections:UseConnection"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "${var.aws_region_name}"
                }
            }
        },
        {
            "Action": [
                "elasticbeanstalk:*",
                "ec2:*",
                "elasticloadbalancing:*",
                "autoscaling:*",
                "cloudwatch:*",
                "s3:*",
                "sns:*",
                "cloudformation:*",
                "rds:*",
                "sqs:*",
                "ecs:*"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Action": [
                "lambda:InvokeFunction",
                "lambda:ListFunctions"
            ],
            "Resource": "*",
            "Effect": "Allow",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "${var.aws_region_name}"
                }
            }
        },
        {
            "Action": [
                "opsworks:CreateDeployment",
                "opsworks:DescribeApps",
                "opsworks:DescribeCommands",
                "opsworks:DescribeDeployments",
                "opsworks:DescribeInstances",
                "opsworks:DescribeStacks",
                "opsworks:UpdateApp",
                "opsworks:UpdateStack"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "${var.aws_region_name}"
                }
            }
        },
        {
            "Action": [
                "cloudformation:CreateStack",
                "cloudformation:DeleteStack",
                "cloudformation:DescribeStacks",
                "cloudformation:UpdateStack",
                "cloudformation:CreateChangeSet",
                "cloudformation:DeleteChangeSet",
                "cloudformation:DescribeChangeSet",
                "cloudformation:ExecuteChangeSet",
                "cloudformation:SetStackPolicy",
                "cloudformation:ValidateTemplate"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "${var.aws_region_name}"
                }
            }
        },
        {
            "Action": [
                "codebuild:BatchGetBuilds",
                "codebuild:StartBuild"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "${var.aws_region_name}"
                }
            }
        },
        {
            "Action": [
                "ecr:DescribeImages"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "${var.aws_region_name}"
                }
            }
        },
        {
            "Action": [
                "states:DescribeExecution",
                "states:DescribeStateMachine",
                "states:StartExecution"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "${var.aws_region_name}"
                }
            }
        },
        {
            "Action": [
                "appconfig:StartDeployment",
                "appconfig:StopDeployment",
                "appconfig:GetDeployment"
            ],
            "Effect": "Allow",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "${var.aws_region_name}"
                }
            }
        },
        {
            "Action": [
                "iam:PassRole"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:iam::*:role/service-role/cwe-role-*",
            "Condition": {
                "StringEquals": {
                    "iam:PassedToService": "events.amazonaws.com"
                }
            }
           
        }
    ]
}
EOF
}

# Lambda roles

resource "aws_iam_role" "lambda_sig_role" {
    name                  = "${var.name_prefix}_${var.aws_region_abbr}_lambda_sig_role"
    description           =  "Policy for CI CD workshop on 09-07-2020."
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
   name       = "${var.name_prefix}_${var.aws_region_abbr}_policy_to_sig_role"
   roles      = [aws_iam_role.lambda_sig_role.name]
   policy_arn = aws_iam_policy.lambda_sig_policy.arn
}

resource "aws_iam_role" "lambda_stop_ec2_role" {
    name                  = "${var.name_prefix}_${var.aws_region_abbr}_lambda_stop_ec2_role"
    description           =  "Policy for CI CD workshop on 09-07-2020."
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

resource "aws_iam_policy_attachment" "policy_to_stop_ec2_role" {
   name       = "${var.name_prefix}_${var.aws_region_abbr}_policy_to_stop_ec2_role"
   roles      = [aws_iam_role.lambda_stop_ec2_role.name]
   policy_arn = aws_iam_policy.lambda_stop_ec2_policy.arn
}

resource "aws_iam_role" "ec2_role" {
    name                  = "${var.name_prefix}_${var.aws_region_abbr}_ec2_role"
    description           =  "Policy for CI CD workshop on 09-07-2020."
    force_detach_policies = true
    assume_role_policy    =  <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
} 

resource "aws_iam_policy_attachment" "policy_attachment_ec2_role" {
   name       = "${var.name_prefix}_${var.aws_region_abbr}_policy_to_ec2_role"
   roles      = [aws_iam_role.ec2_role.name]
   policy_arn = aws_iam_policy.ec2_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
   name       = "${var.name_prefix}_${var.aws_region_abbr}_ec2_instance_profile"
   role       = aws_iam_role.ec2_role.name
}

resource "aws_iam_role" "codebuild_role" {
    name                  = "${var.name_prefix}_${var.aws_region_abbr}_codebuild_role"
    description           =  "Policy for CI CD workshop on 09-07-2020."
    force_detach_policies = true
    assume_role_policy    =  <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "codebuild.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
} 

resource "aws_iam_policy_attachment" "policy_attachment_codebuild_role" {
   name       = "${var.name_prefix}_${var.aws_region_abbr}_policy_to_codebuild_role"
   roles      = [aws_iam_role.codebuild_role.name]
   policy_arn = aws_iam_policy.codebuild_policy.arn
}

resource "aws_iam_role" "codepipeline_role" {
    name                  = "${var.name_prefix}_${var.aws_region_abbr}_codepipeline_role"
    description           =  "Policy for CI CD workshop on 09-07-2020."
    force_detach_policies = true
    assume_role_policy    =  <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "codepipeline.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
} 

resource "aws_iam_policy_attachment" "policy_attachment_codepipeline_role" {
   name       = "${var.name_prefix}_${var.aws_region_abbr}_policy_to_codepipeline_role"
   roles      = [aws_iam_role.codepipeline_role.name]
   policy_arn = aws_iam_policy.codepipeline_policy.arn
}

# AmazonAPIGatewayPushToCloudWatchLogs
# Needed to log what happens in the API gateway

resource "aws_iam_role" "api_gateway_role" {
    name                  = "${var.name_prefix}_${var.aws_region_abbr}_api_gateway_role"
    description           = "Policy for CI CD workshop on 09-07-2020."
    force_detach_policies = true
    assume_role_policy    = <<EOF
{
    "Version" : "2012-10-17" ,
    "Statement" : [
        {
            "Effect" : "allow",
            "Principal" : {
                "Service": "apigateway.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
} 
EOF
}

resource "aws_iam_policy_attachment" "policy_to_cloudwatch_role" {
    name       = "${var.name_prefix}_${var.aws_region_abbr}_policy_to_cloudwatch_role"
    roles      = [aws_iam_role.api_gateway_role.name]
    policy_arn = data.aws_iam_policy.AmazonAPIGatewayPushToCloudWatchLogs.arn
}

# IAM users
#
# First, the user and the group are created.
# After that, there is a group membership object to connect users with groups and
# there is a policy attachment object to connect groups with policies

resource "aws_iam_user" "user" {
    count                    = var.number_of_users
    name                     = "${var.name_prefix}${count.index + var.offset_number_of_users}"
    force_destroy            = true
}

resource "aws_iam_group" "user_group" {
    name = "${var.name_prefix}-${var.aws_region_abbr}_group"
}

resource "aws_iam_group_membership" "user_group_membership" {
    name  = "${var.name_prefix}_${var.aws_region_abbr}_group_membership"
    users = aws_iam_user.user[*].name
    group = aws_iam_group.user_group.name
}

resource "aws_iam_group_policy_attachment" "user_group_policy_attachment" {
    group      = aws_iam_group.user_group.name
    policy_arn = aws_iam_policy.user_policy.arn
}

# CodeCommit repo
# ---------------

resource "aws_codecommit_repository" "repo" {
    count           = var.number_of_users
    repository_name = "${var.name_prefix}${count.index + var.offset_number_of_users}-repo"
    description     = "CI/CD workshop 09-07-2020"
}

# EC2/VPC resources
# -----------------

resource "aws_security_group" "security_group" {
    name            = "${var.name_prefix}-security-group"
    description     = "Allow anyone with a key to go to this VM"
    vpc_id          = data.aws_vpc.vpc.id

    ingress {
        description = "SSH"
        from_port   = 0
        to_port     = 22
        protocol    = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = -1
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.name_prefix}-security-group"
    }
}

resource "aws_key_pair" "ec2_key_pair" {
    key_name                  = "${var.name_prefix}-${var.aws_region_name}"
    public_key                = var.pub_key
}

resource "aws_instance" "ec2" {
  depends_on                  = [aws_iam_instance_profile.ec2_instance_profile]
  count                       = var.number_of_users
  ami                         = data.aws_ami.amazon_linux_ami.image_id
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  user_data                   = file("user_data.sh")
  instance_type               = "t2.micro"
  key_name                    = "AMIS-${var.aws_region_name}"
  vpc_security_group_ids      = [aws_security_group.security_group.id]

  tags = {
    Name = "${var.name_prefix}${count.index + var.offset_number_of_users}-vm"
  }

}

resource "aws_dynamodb_table" "state_locking_table" {
    count          = var.number_of_users
    name           = "${var.name_prefix}${count.index + var.offset_number_of_users}_state_locking"
    billing_mode   = "PROVISIONED"
    read_capacity  = 1
    write_capacity = 1
    hash_key       = "LockID"

    attribute {
        name = "LockID"
        type = "S"
    }
}

resource "aws_s3_bucket" "sig-bucket" {
    bucket = "${lower(var.name_prefix)}-sig-${lower(var.aws_region_abbr)}-bucket"
    acl    = "private"
}

resource "aws_s3_access_point" "sig-bucket-access-point" {
    bucket = aws_s3_bucket.sig-bucket.id
    name   = "sig-bucket-access-point"

    vpc_configuration {
        vpc_id = data.aws_vpc.vpc.id
    }
}

resource "aws_lambda_permission" "lambda_stop_ec2_permission" {
  depends_on    = [aws_lambda_function.stop_ec2]
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stop_ec2.function_name
  principal     = "cloudwatch.amazonaws.com"
}

resource "aws_lambda_function" "stop_ec2" {
    function_name = "${var.name_prefix}_sig_${var.aws_region_abbr}_stop_ec2"
    filename      = "./lambdas/stop_ec2/stop_ec2.zip"
    role          = aws_iam_role.lambda_stop_ec2_role.arn
    handler       = "stop_ec2.lambda_handler"
    runtime       = "python3.8"
    timeout       = 60
    environment {
        variables = {
            region = var.aws_region_name
        }
    }
}

resource "aws_cloudwatch_event_rule" "stop_ec2_event_rule" {
  name                = "${var.name_prefix}_stop_ec2_rule"
  description         = "Stop EC2's every night at 00:00 CET"
  schedule_expression = "cron(0 22 * * ? *)"
}

resource "aws_cloudwatch_event_target" "stop_ec2_event_target" {
  rule                = aws_cloudwatch_event_rule.stop_ec2_event_rule.name
  target_id           = "StartLambda"
  arn                 = aws_lambda_function.stop_ec2.arn
}

##################################################################################
# OUTPUT
##################################################################################


