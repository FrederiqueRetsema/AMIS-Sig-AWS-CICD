# destroy-infra.sh
# ----------------
# Will use terraform to destroy the infrastructure
#
# WARNING:
# --------
# Destroy the shop FIRST, before you destroy the infrastructure!
#
# If you use the vagrant environment, use /home/vagrant/destroy-all.sh
# (which will call this script in the right way)


name_prefix=`grep name_prefix ../../terraform.tfvars | awk -F"\"" '{print $2}' | tr -d '[:space:]'`
aws_region_name=`grep aws_region_name ../../terraform.tfvars | awk -F"\"" '{print $2}' | tr -d '[:space:]'`
pub_key=`cat ${name_prefix}-${aws_region_name}.pub`
../../terraform destroy --var-file=../../terraform.tfvars -auto-approve -var "pub_key=${pub_key}"
if (test $? -eq 1)
then
    echo "Destroy of infra failed"
    exit 1
fi
