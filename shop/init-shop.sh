# init-shop.sh
# ------------
# See for assumptions and parameters the README.md file in this directory
# 

# Zip accept function (the Terraform function doesn't accept inline specification of a Lambda function)
#
cd lambdas/accept
zip accept.zip accept.py
cd ../..

# Zip decrypt function
#
cd lambdas/decrypt
zip decrypt.zip decrypt.py
cd ../..

# Zip process function
#
cd lambdas/process
zip process.zip process.py
cd ../..

# Use terraform to deploy the shop. 
# 
../../terraform init --var-file=../../terraform-cicd.tfvars
../../terraform plan --var-file=../../terraform-cicd.tfvars --out terraform.tfplans
../../terraform apply "terraform.tfplans"
