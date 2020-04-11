# init-shop

These scripts are used to initialize the settings per shop. See other directories for a description of 
the workshop and the initialisation scripts.

Advise: use Vagrant and the `init-all.sh` script in the vagrant environment to deploy the objects. It
saves you a lot of trouble! You don't have to read the rest of this file if you use vagrant. See
../vagrant/README.md for more information.

More information about this shop example can be found on the AMIS blog: https://technology.amis.nl
You will find the text of that blog also in a pdf file in the root of this depository.

## Before initialization

Before using these scripts, download Terraform version 0.12.24 and unzip the downloadfile. Put the 
terraform.exe file in the root of the directory that this directory is in (or change the batch scripts).
The server where these scripts are used must also have the AWS CLI, Python3 and boto3 installed. 

The scripts use access keys of a user that is able to create, change and delete Lambda functions, 
API gateways and SNS topics. The user should also be allowed to read and write DNS entries in the
domain that you pass as a parameter, and have read access to the certificate for your domain in the
Certificate Manager.

Copy terraforms-template.tfvars to \terraform.tfvars and change the content: add the access key and the 
secret access key of an administrative user to this file, change other parameters if you want to and run 
the `init-infra.sh` script in the ../init-infra directory. When the ../../terraform-cicd.tfvars file is 
created, you might want to change the contents of that file to fit your needs.

## List of parameters in ../../terraform-cicd.tfvars with their defaults

Please note that when you use vagrant, many defaults will change when you pass other values to the questions
in that script. The content of the file can be overwritten by the scripts in the ../init-infra directory.

```
aws_access_key         = "access key"        (for permissions see above)
aws_secret_key         = "secret access key" (see above)
aws_region             = "eu-west-1"         (the region that you want to use for the workshop)

domainname             = "retsema.eu"        (domain name that is used for the SIG, this should be an internal \
                                              domain name that doesn't exist on the public internet).

name_prefix            = "AMIS"              (prefix for the DynamoDB table - will be used by all users in this region)
user_prefix            = "AMIS1"             (prefix for all objects: Lambda functions, API gateway, SNS topics etc)
key_prefix             = "KeyI-"             (will be used by the Lambda decrypt function)
```

## Changes for AWS CLI

The CLI is used for other parts of the deployment. The shop itself doesn't use the AWS CLI.

## Shell scripts

The following shell scripts exist:

### init-infra.sh

This script will use terraform-init.tf to create all relevant objects:
- CertificateManagement: a certificate will be used for the domain. Please mind, that creating a certificate can take some minutes. When the process hasn't finished yet, creating shop items with init-shop.sh might fail.
- Route53: a DNS record with the shop_id will be added to the domain
- API gateway: a new API gateway will be added to AWS
- Lambda functions: three Lambda functions will be added to AWS
- SNS topics: two SNS topics will be added to AWS

### destroy-infra.sh

When you want to stop, use the `destroy-shop.sh` (in this directory) to delete the shop objects that have been created by `init-shop.sh` \ 
After that, use the `destroy-infra.sh` script (in the directory ../init-infra) to destroy the infra objects \
If you want to destroy the certificate (that has been created by Terraform), then you can use the `destroy-cert.sh` script in the ../init-cert directory to do so.

### clean-infra-dir.sh

When all objects are destroyed using the destroy-infra.sh script, you might want to delete the specific
Terraform directories and files. This script will NOT delete the tfvars files in the ../.. directory,
you might want to clean this up yourself.

