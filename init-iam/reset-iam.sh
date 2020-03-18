../../terraform destroy --var-file=../../terraform.tfvars 
rm *.tfplans
rm *.tfstate
rm *.backup
rm *.txt
rm -fr .terraform
