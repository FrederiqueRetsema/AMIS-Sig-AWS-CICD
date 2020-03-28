cd lambdas/accept
zip accept.zip accept.py
cd ../..
cd lambdas/process
zip process.zip process.py
cd ../..
../../terraform init --var-file=../../terraform-cicd.tfvars
../../terraform plan --var-file=../../terraform-cicd.tfvars --out terraform.tfplans
../../terraform apply "terraform.tfplans"


