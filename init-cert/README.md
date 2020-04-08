# init-cert

These scripts are used to request or destroy the certificate that is used. See other directories for a 
description of the workshop. 

When you want to use these scripts in your own AWS environment, please use the vagrant directory in this
repository: this will save you a lot of configuration. When you use vagrant, you don't need to read the
rest of this information.

## Before initialization

Before using these scripts, download Terraform version 0.12.24 and unzip the downloadfile. Put the
terraform.exe file one level before the gitlab directory is. Relative to this path, this is in ../.. 
(or change the batch scripts). The server where these scripts are used must also have the AWS CLI, 
Python3 and boto3 installed (though this specific directory only uses Terraform).

The scripts use access keys of a user that is able to create and delete a certificate in the 
CertificateManager.

Copy terraforms-template.tfvars from ../init-infra to ../../terraform.tfvars and change the content: add the 
access key and the secret access key of an administrative user to this file. The cert scripts further only
use the domain name. 

## List of parameters in ../../terraform.tfvars

The init-cert scripts use the same terraform.tfvars file as the files in the init-infra directory. See the 
README.md file in init-infra for more information about these parameters.

## Shell scripts

The following shell scripts exist:

### `init-cert.sh`

This script will use terraform-init.tf to create all relevant objects:
- CertificateManagement: a certificate will be created for the domain. Please mind, that creating a certificate can take some minutes. When the certificate isn't checked yet, creating shop items with `init-shop.sh` might fail.
- Route53: to be able to check if the domain that you request a certificate for really belongs to you, AWS asks you to add a CNAME record in the DNS. This is done automatically by this Terraform script (assuming you use Route53)

After using `init-cert.sh`, you are ready to use `init-infra.sh` (in the init-infra directory) to create the other infra objects and, after that, `init-shop.sh` (in the shop directory) to create shop objects.

### `destroy-cert.sh`

When you want to stop, use the `destroy-shop.sh` (in the shop directory) to delete the shop objects.\
When all shop objects are destroyed, you can use destroy-infra.sh to use `terraform destroy` to destroy all infra objects.
When all infra objects are destroyed, you can use destroy-cert.sh to use `terraform destroy` to destroy the certificate and the Route53 objects.

### `clean-cert-dir.sh`

When all objects are destroyed using the destroy-infra.sh script, you might want to delete the specific
Terraform directories and files. This script will NOT delete the tfvars files in the ../.. directory,
you might want to clean this up yourself.

