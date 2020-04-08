# create-terraform-cicd-tfvars.sh
# -------------------------------
# Create a ../../terraform-cicd.tfvars file with the correct content. 

# It will add the access key and the secret access key from the first
# user that is created by running the terraform scripts. (This is
# defined in the init-shop.sh shell, we get the created-access-keys.txt
# file from that script).
#
# It will assume that the first user is the default user that is to 
# be used by the init-shop.sh install script.
#
# The name_prefix, key_prefix, region_sig, offset_number_of_users, 
# and the domainname will be retrieved from the ../../terraform.tfvars 
# file.
#
# It also assumes that amis.nl is the correct domain to use. 
# when you use the vagrant install files, the amis.nl value will
# be overwritten by the value you give there.
#
# This script is called by init-infra.sh, you shouldn't use it manually.

# =======================================================================
# Technical comments:
#
# Strings, f.e. name_prefix: 
#         grep name_prefix ../../terraform.tfvars
#           -> will get you
#                  nameprefix             = "AMIS"
#         awk -F "\"" will set the seperator to double quote. So in the
#              previous example, $2 will be 
#                  AMIS. 
#
# Numbers, like offset_number_of_users: likewise, but here the seperator 
#         is the = character (numerical values don't have a double quote), 
#         and the tr command is needed to trim off spaces because otherwise
#         the user_prefix will contain spaces (f.e. AMIS 1 instead of AMIS1)
#         
name_prefix=`grep name_prefix ../../terraform.tfvars | awk -F"\"" '{print $2}'`
key_prefix=`grep key_prefix ../../terraform.tfvars | awk -F"\"" '{print $2}'`
region_sig=`grep region_sig ../../terraform.tfvars | awk -F"\"" '{print $2}'`
domainname=`grep domainname ../../terraform.tfvars | awk -F"\"" '{print $2}'`
offset_number_of_users=`grep offset_number_of_users ../../terraform.tfvars | awk -F"=" '{print $2}'|tr -d '[:space:]'`

# The output in the created-access-keys.txt is json. Therefore the seperation character is a colon.
# We don't need double quotes ("), by using seperator \" we will get the text that we -are- interested in in $2.

echo aws_access_key = \"`grep AccessKeyId created-access-keys.txt | awk -F ":" '{print $2}' | awk -F "\"" '{print $2}'`\" > ../../terraform-cicd.tfvars
echo aws_secret_key = \"`grep SecretAccessKey created-access-keys.txt | awk -F ":" '{print $2}' | awk -F "\"" '{print $2}'`\" >> ../../terraform-cicd.tfvars

# We will take the first user that is created (that should always exist with valid parameters).
# The first user is ${name_prefix}${offset_number_of_users}, this is by default AMIS1
echo user_prefix    = \"${name_prefix}${offset_number_of_users}\" >> ../../terraform-cicd.tfvars

# These strings are the same as in the ../../terraform.tfvars file
echo key_prefix     = \"${key_prefix}\" >> ../../terraform-cicd.tfvars
echo region_sig     = \"${region_sig}\" >> ../../terraform-cicd.tfvars
echo domainname     = \"${domainname}\" >> ../../terraform-cicd.tfvars

