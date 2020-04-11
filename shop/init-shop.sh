# init-shop.sh
# ------------
# See for assumptions and parameters the README.md file in this directory
# 

# Zip the Lambda functions (Terraform doesn't accept inline specification of a Lambda function)
#
cd lambdas/accept
zip accept.zip accept.py
cd ../..

cd lambdas/decrypt
zip decrypt.zip decrypt.py
cd ../..

cd lambdas/process
zip process.zip process.py
cd ../..

# Use terraform to deploy the shop. 
# 
../../terraform init --var-file=../../terraform-cicd.tfvars
if (test $? -ne 0)
then
  echo Init failed
  exit 1
fi

../../terraform plan --var-file=../../terraform-cicd.tfvars --out terraform.tfplans
if (test $? -ne 0)
then
  echo Plan failed
  exit 1
fi

../../terraform apply "terraform.tfplans"
if (test $? -ne 0)
then
  echo Apply failed
  exit 1
fi
