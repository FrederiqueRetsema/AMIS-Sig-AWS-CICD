#/usr/bin/bash
#
# init-all.sh
# -----------
# 

SIG_REPO_NAME="AMIS-Sig-AWS-CICD"

# configure_aws_cli_if_needed
# ---------------------------

function configure_aws_cli_if_needed {

  if (! test -d ~/.aws)
  then

    echo "Access key/secret access key: Copy/paste your access key and secret access key to the next two questions."
    echo "                              If you don't have (secret) access keys yet, read the README.md file in the vagrant directory"
    echo "Default region              : When you don't know what region to use, use eu-central-1 (Frankfurt)"
    echo "Default output format       : Just press enter"
    echo "" 

    aws configure
    if (test $? -ne 0)
    then
      echo "AWS CLI failed (configure)"
      exit 1
    fi

  fi

}

# download_sig_repo_if_needed
# ----------------------------

function download_sig_repo_if_needed {

  if (! test -d ~/${SIG_REPO_NAME})
  then

    git clone https://github.com/FrederiqueRetsema/${SIG_REPO_NAME}
    if (test $? -ne 0)
    then
      echo "GIT failed (clone)"
      exit 1
    fi

  fi

}

# configure_tfvars_if_needed
# --------------------------
# don't use 's/your_secret_key/'$aws_secret_key' : the secret key might contain slash-es (/) that will confuse sed

function configure_tfvars_if_needed {

  if (! test -f ~/terraform.tfvars)
  then

    cp ~/${SIG_REPO_NAME}/init-infra/terraform-template.tfvars ~/terraform.tfvars

    # Credentials file is in the format aws_access_key_id = key (including spaces)

    aws_access_key=`grep aws_access_key_id ~/.aws/credentials | awk -F" " '{print $3}'`
    aws_secret_key=`grep aws_secret_access_key ~/.aws/credentials | awk -F" " '{print $3}'`

    sed -i '/aws_access_key/c aws_access_key            = "'${aws_access_key}'"' ~/terraform.tfvars
    sed -i '/aws_secret_key/c aws_secret_key            = "'${aws_secret_key}'"' ~/terraform.tfvars

    # region is in the format region = eu-west-1 (including spaces)
 
    region=`grep region ~/.aws/config | awk -F " " '{print $3}'`
    sed -i '/aws_region_name/c aws_region_name            = "'${region}'"' ~/terraform.tfvars

    # aws sts get-caller-identity returns json. json is in the format "key" : "value". 

    accountid=`aws sts get-caller-identity| grep Account | awk -F"\"" '{print $4}'`
    sed -i 's/your_account_number/'$accountid'/' ~/terraform.tfvars

  fi

}

# info_domain_name
# ----------------

function info_domain_name {

  echo "This SIG is impossible without using a public DNS zone in Route53."
  echo "What is the name of your public DNS zone in Route53 which can be used for the SIG? (F.e. cloudhotel.org)"

}

# ask_domain_name 
# ---------------

function ask_domain_name {

  read domain_name
  echo $domain_name

}

# configure_domain
# ----------------

function configure_domain {

  domain_name=$1

  sed -i '/domain_name/c domain_name                = "'$domain_name'"' ~/terraform.tfvars

}

# info_number_of_regions
# ----------------------

function info_number_of_regions {

  echo "Give the number of regions (max = 5): per region you can use at most 5 users" 
  echo "(this might be old information -> have to check this when we can run multiple"
  echo "pipelines at the same time)"

}

# ask_number_of_regions
# ---------------------

function ask_number_of_regions {

  read number_of_regions
  echo $number_of_regions

}

# info_number_of_users_per_region
# -------------------------------

function info_number_of_users_per_region {

  echo "Give the number of users per region (max = 5)" 

}

# ask_number_of_users_per_region
# ------------------------------

function ask_number_of_users_per_region {

  read number_of_users
  echo $number_of_users

}

# configure_number_of_users
# -------------------------

function configure_number_of_users {

  number_of_users=$1
  sed -i "/^number_of_users/c number_of_users        = ${number_of_users}" ~/terraform.tfvars

}

# get_name_prefix
# ---------------
# name_prefix in the tfvars file is in the format name_prefix = "this-is-the-nameprefix".

function get_name_prefix {

    name_prefix=`grep name_prefix ~/terraform.tfvars | awk -F"\"" '{print $2}'`
    echo $name_prefix

}

# info_prefix_pwd
# ---------------

function info_prefix_pwd {

  name_prefix=$1

  echo "The default password consists of a prefix, the number of the user and a postfix. For example: when the default password for user ${name_prefix}1 = Amsterdam1!"
  echo "then the prefix for the password is Amsterdam, the number is always equal to the number in the username (in this example: 1) and the postfix is !"
  echo ""
  echo "What is the prefix for the password?"

}

# ask_prefix_pwd
# --------------

function ask_prefix_pwd {

  read prefix_pwd
  echo $prefix_pwd

}

# info_postfix_pwd
# ----------------

function info_postfix_pwd {

  echo ""
  echo "What is the postfix for the password?"

}

# ask_postfix_pwd
# ---------------

function ask_postfix_pwd {

  read postfix_pwd
  echo $postfix_pwd

}


# configure_offset_number_of_users
# --------------------------------

function configure_offset_number_of_users {

  offset_number_of_users=$1
  sed -i "/^offset_number_of_users/c offset_number_of_users = ${offset_number_of_users}" ~/terraform.tfvars

}

# create_and_fill_region_dir_if_necessary
# ---------------------------------------

function create_and_fill_region_dir_if_necessary {

  aws_region_name=$1
  if (! test -d ~/${aws_region_name})
  then 
    mkdir ~/${aws_region_name}
  fi
  cd ~/${aws_region_name}

  if (! test -d ~/${aws_region_name}/${SIG_REPO_NAME})
  then
    cp -fr ~/${SIG_REPO_NAME} .
    cp ~/terraform .
  fi

}

# create_and_change_region_terraform_tfvars
# -----------------------------------------

function create_and_change_region_terraform_tfvars {

  aws_region_name=$1
  aws_region_abbr=$2

  cp ~/terraform.tfvars .

  sed -i '/aws_region_name/c aws_region_name        = "'${aws_region_name}'"' ./terraform.tfvars
  sed -i '/aws_region_abbr/c aws_region_abbr        = "'${aws_region_abbr}'"' ./terraform.tfvars

}

# change_default_region_cli
# -------------------------

function change_default_region_cli {

  aws_region_name=$1
  sed -i "/region/c region = ${aws_region_name}" ~/.aws/config

}

# create_certificate_if_necessary
# -------------------------------

function create_certificate_if_necessary {

  aws_region_name=$1
  domain_name=$2

  certificate=`aws acm list-certificates | grep "*.${domain_name}"`

  if (test "${certificate}" == "")
  then
    echo "This domain doesn't have a star certificate yet, let's create one..."

    cd ~/${aws_region_name}/${SIG_REPO_NAME}/init-cert
    ./init-cert.sh
    if (test $? -ne 0)
    then
      echo Creating certificate in region ${aws_region_name} failed
      exit 1
    fi

  else
    echo "This domain already has a star certificate"
  fi

}

# enroll_init_infra
# -----------------

function enroll_init_infra {

  aws_region_name=$1
  prefix_pwd=$2
  postfix_pwd=$3

  cd ~/${aws_region_name}/${SIG_REPO_NAME}/init-infra
  ./init-infra.sh $prefix_pwd $postfix_pwd
  if (test $? -ne 0)
  then
    echo Creating infrastructure in region $aws_region_name failed
    exit 1
  fi

}

# 
# Main program
# ============
#

configure_aws_cli_if_needed
download_sig_repo_if_needed
configure_tfvars_if_needed

info_domain_name
domain_name=$(ask_domain_name)
configure_domain ${domain_name}

name_prefix=$(get_name_prefix)
info_prefix_pwd $name_prefix
prefix_pwd=$(ask_prefix_pwd)
info_postfix_pwd
postfix_pwd=$(ask_postfix_pwd)

info_number_of_regions
number_of_regions=$(ask_number_of_regions)

info_number_of_users_per_region
number_of_users=$(ask_number_of_users_per_region)
configure_number_of_users $number_of_users

for region_no in $(seq 1 ${number_of_regions})
do

  case ${region_no} in
    1)
      aws_region_name=eu-central-1
      aws_region_abbr=euc1
      ;;
    2)
      aws_region_name=eu-west-2
      aws_region_abbr=euw2
      ;;
    3)
      aws_region_name=eu-west-3
      aws_region_abbr=euw3
      ;;
    4)
      aws_region_name=eu-north-1
      aws_region_abbr=eun1
      ;;
    *)
      echo "Region number not <= 4, stop"
      break
      ;;
   esac

  let offset_number_of_users=(${region_no}-1)*${number_of_users}+1
  configure_offset_number_of_users $offset_number_of_users

  echo Region: $region_no - $aws_region_name
  echo Offset: ${offset_number_of_users}

  create_and_fill_region_dir_if_necessary $aws_region_name
  create_and_change_region_terraform_tfvars $aws_region_name $aws_region_abbr
  change_default_region_cli $aws_region_name

  create_certificate_if_necessary $aws_region_name $domain_name
  enroll_init_infra $aws_region_name $prefix_pwd $postfix_pwd

done
