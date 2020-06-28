# destroy-infra.sh
# ----------------
# Will use terraform to destroy the infrastructure
#
# If you use the vagrant environment, use /home/vagrant/destroy-all.sh
# (which will call this script in the right way)


name_prefix=`grep name_prefix ../../terraform.tfvars | awk -F"\"" '{print $2}' | tr -d '[:space:]'`
aws_region_name=`grep aws_region_name ../../terraform.tfvars | awk -F"\"" '{print $2}' | tr -d '[:space:]'`
pub_key=`cat ${name_prefix}-${aws_region_name}.pub`
name_prefix=`grep name_prefix ../../terraform.tfvars | awk -F"\"" '{print $2}'`
number_of_users=`grep number_of_users ../../terraform.tfvars | grep -v offset | awk -F"=" '{print $2}' | tr -d '[:space:]'`
offset_number_of_users=`grep offset_number_of_users ../../terraform.tfvars | awk -F"=" '{print $2}' | tr -d '[:space:]'`
last_number_of_users=$(( $offset_number_of_users + $number_of_users - 1 ))


../../terraform destroy --var-file=../../terraform.tfvars -auto-approve -var "pub_key=${pub_key}"
if (test $? -eq 1)
then
    echo "Destroy of infra failed"
    exit 1
fi


for i in $(seq ${offset_number_of_users} ${last_number_of_users})
do
    aws codecommit delete-approval-rule-template --approval-rule-template-name "rule template ${name_prefix}${i}-repo" 

done
