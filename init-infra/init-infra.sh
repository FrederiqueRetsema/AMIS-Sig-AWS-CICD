# init-infra.sh
# -------------
# Initializes the infrastructure. 
#
# Assumptions: 
# - this script will only be used to create the infrastructure once. When you change
#   anything to the infrastructure, first use the destroy script(s) and then use the install script(s).
#   This script will give errors if you don't.
# - this script will NOT create a certificate. Go to the ../init-cert directory and use init-cert.sh 
#   for that.
# 

# Determine some information from the terraform.tfvars file. Example for prefix:
#
# prefix: grep prefix ../../terraform.tfvars
#           -> will get you
#              nameprefix             = "AMIS"
#         awk -F "\"" will set the seperator to double quote. So in the
#         previous example, $2 will be AMIS. 
#
# In number_of_users, grep -v is needed to not get the offset_number_of_users value, we want just one record.
# In number_of_user and offset_number_of_users, seperator = is used (these numbers are not within quotes)
#         we need to trim spaces (with tr -d '[:space:]) because otherwise ${name_prefix}${offset_number_of_users}
#         will contain a space.
#

name_prefix=`grep name_prefix ../../terraform.tfvars | awk -F"\"" '{print $2}'`
number_of_users=`grep number_of_users ../../terraform.tfvars | grep -v offset | awk -F"=" '{print $2}' | tr -d '[:space:]'`
offset_number_of_users=`grep offset_number_of_users ../../terraform.tfvars | awk -F"=" '{print $2}' | tr -d '[:space:]'`
last_number_of_users=$(( $offset_number_of_users + $number_of_users - 1 ))

echo "name_prefix            = ${name_prefix}"
echo "number_of_users        = ${number_of_users}"
echo "offset_number_of_users = ${offset_number_of_users}"
echo "last_number_of_users   = ${last_number_of_users}"

# Use terraform to deploy the infrastructure

../../terraform init --var-file=../../terraform.tfvars
../../terraform plan --var-file=../../terraform.tfvars --out terraform.tfplans
../../terraform apply "terraform.tfplans"

# Add passwords to the users. DomToren${i}# (f.e. DomToren1#) is an example only, we will use different 
# passwords during the workshop.

for i in $(seq ${offset_number_of_users} ${last_number_of_users})
do
  aws iam create-login-profile --user-name "${name_prefix}$i" --password "DomToren${i}#" --no-password-reset-required
done

# - Create a file with new access keys for the first user, 
# - Create a terraform-cicd.tfvars file
# - Don't leave access information in a file which might be checked in into github (if we miss it), destroy the file
# 
aws iam create-access-key --user-name "${name_prefix}${offset_number_of_users}" > ./created-access-keys.txt
./create-terraform-cicd-tfvars.sh
#rm ./created-access-keys.txt

# 
# Add records to the DynamoDB database
#

python3 addDynamoDBRecords.py ${name_prefix} ${offset_number_of_users} ${number_of_users}



