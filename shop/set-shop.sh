cd lambdas
zip accept.zip accept.py
cd ..
../../terraform init --var-file=../../terraform-cicd.tfvars
../../terraform plan --var-file=../../terraform-cicd.tfvars --out terraform.tfplans
../../terraform apply "terraform.tfplans"


