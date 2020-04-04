# init-shop.sh
# ------------
# See for assumptions and parameters the README.md file in this directory
# 

# Zip accept function (the Terraform function doesn't accept inline specification of a Lambda function)
#
cd lambdas/accept
zip accept.zip accept.py

# Zip process function
#
cd ../..
cd lambdas/process
zip process.zip process.py

# Use terraform to deploy the shop. 
# 
cd ../..
../../terraform init --var-file=../../terraform-cicd.tfvars
../../terraform plan --var-file=../../terraform-cicd.tfvars --out terraform.tfplans
../../terraform apply "terraform.tfplans"
