# init-infra.sh
# =============

# generate_key_pair_if_necessary
# ------------------------------

function generate_key_pair_if_necessary {

  name_prefix=$1
  aws_region_name=$2

  if (! test -f ${name_prefix}-${aws_region_name}.pub)
  then
    ssh-keygen -f ./${name_prefix}-${aws_region_name} -N ""
  fi

}

# zip_lambda_function
# -------------------

function zip_lambda_function {

  function_name=$1

  cd lambdas/${function_name}
  zip ${function_name}.zip ${function_name}.py
  cd ../..

}

# terraform_init
# --------------

function terraform_init {

  ../../terraform init --var-file=../../terraform.tfvars
  if (test $? -ne 0)
  then
    echo "Init of infra failed"
    exit 1
  fi

}

# terraform_plan
# --------------

function terraform_plan {

  ../../terraform plan --var-file=../../terraform.tfvars --out terraform.tfplans -var "pub_key=${pub_key}"
  if (test $? -ne 0)
  then
    echo "Plan of infra failed"
    exit 1
  fi

}

# terraform_apply
# ---------------

function terraform_apply {

  ../../terraform apply "terraform.tfplans" 
  if (test $? -ne 0)
  then
    echo "Apply of infra failed"
    exit 1
  fi

}

# add_passwords_to_users
# ----------------------
# If you don't want your users to change their password immediately, then add --no-password-reset-required to the aws iam create-login-profile

function add_passwords_to_users {

  prefix_pwd=$1
  postfix_pwd=$2
  offset_number_of_users=$3
  last_number_of_users=$4

  for i in $(seq ${offset_number_of_users} ${last_number_of_users})
  do
    aws iam create-login-profile --user-name "${name_prefix}$i" --password "${prefix_pwd}${i}${postfix_pwd}" 
  
    if (test $? -ne 0)
    then
      echo "AWS CLI failed (IAM create-logon-profile)"
      #exit 1
    fi
  
  done

}

# get_approval_pool_members
# -------------------------

function get_approval_pool_members {

  account_number=$1
  name_prefix=$2
  offset_number_of_users=$3
  last_number_of_users=$4

  approval_pool_members="\"arn:aws:iam::${account_number}:user/${name_prefix}0\""
  for i in $(seq ${offset_number_of_users} ${last_number_of_users})
  do
    approval_pool_members+=",\"arn:aws:iam::${account_number}:user/${name_prefix}${i}\""
  done

  echo ${approval_pool_members}
}

# create_approval_rule_templates
# ------------------------------

function create_approval_rule_templates {

  name_prefix=$1
  approval_pool_members=$2
  offset_number_of_users=$3
  last_number_of_users=$4

  for i in $(seq ${offset_number_of_users} ${last_number_of_users})
  do
      aws codecommit create-approval-rule-template --approval-rule-template-name "rule template ${name_prefix}${i}-repo" --approval-rule-template-description "Requires another AMIS user to approve the pull request" --approval-rule-template-content "{\"Version\": \"2018-11-08\", \"Statements\": [{\"Type\": \"Approvers\", \"NumberOfApprovalsNeeded\": 1,\"ApprovalPoolMembers\": [${approval_pool_members}]}]}"
  
      aws codecommit associate-approval-rule-template-with-repository --approval-rule-template-name "rule template ${name_prefix}${i}-repo" --repository-name "${name_prefix}${i}-repo"
  done

}

# 
# Main program
# ============
#

prefix_pwd=$1
postfix_pwd=$2

name_prefix=`grep name_prefix ../../terraform.tfvars | awk -F"\"" '{print $2}'`
number_of_users=`grep number_of_users ../../terraform.tfvars | grep -v offset | awk -F"=" '{print $2}' | tr -d '[:space:]'`
offset_number_of_users=`grep offset_number_of_users ../../terraform.tfvars | awk -F"=" '{print $2}' | tr -d '[:space:]'`
last_number_of_users=$(( $offset_number_of_users + $number_of_users - 1 ))
aws_region_name=`grep aws_region_name ../../terraform.tfvars | awk -F"\"" '{print $2}' | tr -d '[:space:]'`
account_number=`aws sts get-caller-identity| grep Account | awk -F"\"" '{print $4}'`

echo "name_prefix            = ${name_prefix}"
echo "number_of_users        = ${number_of_users}"
echo "offset_number_of_users = ${offset_number_of_users}"
echo "last_number_of_users   = ${last_number_of_users}"
echo "aws_region_name        = ${aws_region_name}"
echo "account_number         = ${account_number}"

generate_key_pair_if_necessary ${name_prefix} ${aws_region_name}
pub_key=`cat AMIS-${aws_region_name}.pub`

zip_lambda_function stop_ec2

terraform_init
terraform_plan
terraform_apply

add_passwords_to_users ${prefix_pwd} ${postfix_pwd} ${offset_number_of_users} ${last_number_of_users}

approval_pool_members=$(get_approval_pool_members ${account_number} ${name_prefix} ${offset_number_of_users} ${last_number_of_users})
create_approval_rule_templates ${name_prefix} ${approval_pool_members} ${offset_number_of_users} ${last_number_of_users}

