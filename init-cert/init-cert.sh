# init-cert.sh
# ------------
# Used to initialise the certificate

# WARNING: Be aware, that using init-cert.sh and destroy-cert.sh a lot, might lead into
# errors in AWS: you are allowed to request 20 certificates per year. 

../../terraform init --var-file=../../terraform.tfvars
../../terraform plan --var-file=../../terraform.tfvars --out terraform.tfplans
../../terraform apply "terraform.tfplans"

