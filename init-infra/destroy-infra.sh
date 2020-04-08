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

../../terraform destroy --var-file=../../terraform.tfvars 
