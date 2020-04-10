# init-shop
These scripts are used to initialize the settings per shop. See other directories for a description of 
the workshop and the initialisation scripts.

## Before initialization
Before using these scripts, download Terraform version 0.12.24 and unzip the downloadfile. Put the 
terraform.exe file in the root of the directory that this directory is in (or change the batch scripts).
The server where these scripts are used must also have the AWS CLI, Python3 and boto3 installed. 

The scripts use access keys of a user that is able to create, change and delete IAM users, groups, policies. 
It also needs permission on KMS keys, DynamoDB, Route53, CertificateManager, Systems Manager etc. 

Copy terraforms-template.tfvars to \terraform.tfvars and change the content: add the access key and the 
secret access key of an administrative user to this file, change other parameters if you want to and run 
the init-infra.sh script.

## List of parameters in ../../terraform.tfvars with their defaults
Please note that when you use vagrant, many defaults will change when you pass other values to the questions
in that script.

```
aws_access_key         = "your access key (administrator user)"
aws_secret_key         = "your secret access key (administrator user)"
number_of_users        = 2                 (max 20 per region)
offset_number_of_users = 0                 (number to add to the first user. 0 means: first user is AMIS0)
aws_region             = "eu-west-1"       (region for the SIG: pipelines and shops are build in this region)
nameprefix             = "AMIS"            (prefix for all objects: users, groups, policies, SNS topics, Lambda functions, etc)
domainname             = "retsema.eu"      (domain name that is used for the SIG, this should be an internal \
                                            domain name that doesn't exist on the public internet).
```

## Changes for AWS CLI
The AWS CLI is used in the scripts. Please install the AWS CLI (yum install aws-cli -y) and use `aws configure ` to add AWS access key, secret access key, default region (which should be the SIG region) to your machine.

## Shell scripts

The following shell scripts exist:

### init-infra.sh

This script will use terraform-init.tf to create all relevant objects:
- IAM: users, groups, policies, roles. In general, one role will be used for all users. 
- KMS: one key per user. The prefix of this key is defined in the terraform-infra.tf file. When you destroyed keys from the GUI, AWS will wait for 31 days before deleting the key. The GUI will not permit you to delete the name of the key (and when Terraform creates a new key, then this key name must be different than the key that is already pending a destroy).
- DynamoDB: there is one DynamoDB table for all the shops. The DynamoDB table might also be filled differently for Acceptance and Production (though this is not further discussed/implemented). 
- Route53: new hosted zone (domain) for internal usage. Is used within the shop example to be rid of the random http addresses like https://wmfmq9t91a.execute-api.eu-west-1.amazonaws.com/prod/shop. To be able to use better names like amis0.retsema.eu/shop, we need a certificate. To be able to create a certificate, the DNS is checked to see if you own the domain. For that purpose, a CNAME entry is added to the domain. 
- CertificateManagement: a certificate will be created for the domain. Please mind, that creating a certificate can take some minutes. When the process hasn't finished yet, creating shop items with init-shop.sh might fail.

After using the terraform script to create users, the CLI is used for adding easy-to-remember passwords to the users (Terraform has no way to create an initial password). 
Python is used for adding records to the DynamoDB database. On this moment, Terraform will create an error if you add records to a table with a secundary index.

The script `create-terraform-cicd-tfvars.sh` script will be run: this will add the access key and secret access key from AMIS0 to a (newly created) script ../../terraform-cicd.tfvars file. This tfvars file (with less privileges than the account you use for creating the infra) will be used to create the shop environment. 

After using init-infra.sh, you are ready to use init-shop.sh (in the shop directory) to create shop objects.

### destroy-infra.sh

When you want to stop, use the destroy-shop.sh (in the shop directory) to delete the shop objects. \ 
When all shop objects are destroyed, you can use destroy-infra.sh to use `terraform destroy` to destroy all infra objects.

### clean-infra-dir.sh

When all objects are destroyed using the destroy-infra.sh script, you might want to delete the specific
Terraform directories and files. This script will NOT delete the tfvars files in the ../.. directory,
you might want to clean this up yourself.

### create-terraform-cicd-tfvars.sh 

See above in the description of init-infra.sh

