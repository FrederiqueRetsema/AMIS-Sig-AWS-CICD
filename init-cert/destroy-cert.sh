# destroy-cert.sh
# ---------------
# Used to destroy the terraform environment. 

# WARNING: 
# --------
# Be aware, that using init-cert.sh and destroy-cert.sh a lot, might lead into
# errors in AWS: you are allowed to request 20 certificates per year. 

../../terraform destroy --var-file=../../terraform.tfvars 

