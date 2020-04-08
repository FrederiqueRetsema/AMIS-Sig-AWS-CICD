# init-infra

These scripts are used to initialize the CI/CD workshop for AMIS. See other directories for a description of
the workshop. When you want to initialize an environment yourself and if you are new to the combination of
Terraform and AWS, it might be easyer to go to the vagrant directory and use vagrant to set up the
environment for you. You will find more information in the README.md file in the vagrant directory and can
ignore the rest of the README.md you are reading now.

## Before initialization

Before using these scripts, download Terraform version 0.12.24 and unzip the downloadfile. Put the
terraform.exe file in the same directory as you used the git clone command: the scripts use the relative
directory ../.. for this (you might want to change the batch scripts if this is different in your 
environment).The server where these scripts are used must also have the AWS CLI, Python3 and boto3 installed.

The scripts use access keys of a user that is able to create, change and delete IAM users, groups, policies.
It also needs permission on KMS keys, DynamoDB, Route53, Systems Manager etc.

Copy terraforms-template.tfvars to ../../terraform.tfvars and change the content: add the access key and the
secret access key of an administrative user to this file, change other parameters if you want to and run
the init-infra.sh script.

__WARNING__: you need a star certificate for your domain name. For example, when you use retsema.eu as domain
name, you need a certificate *.retsema.eu . Terraform can create this for you, but it is not part of this
init: when you use init-infra.sh and destroy-infra.sh a lot, then you will reach the AWS limit for the max 
number of certificates per year, which is by default 20.

To help you, you can request this certificate by using the `init-cert.sh` script in the directory ../init-cert
This will, however, not be part of the automated scripts in this directory, to prevent you to reach the AWS 
service limit.

## List of parameters in ../../terraform.tfvars

``` terraform.tfvars
aws_access_key         = "your access key"        (administrator user)
aws_secret_key         = "your secret access key" (administrator user)
number_of_users        = 2                        (max 20 per region)
offset_number_of_users = 0                        (number to add to the first user. 0 means: first user is AMIS0)
aws_region_sig         = "eu-west-1"              (region for the SIG: pipelines and shops are build in this region)
aws_region_ec2         = "eu-west-2"              (region for the virtual machines)
nameprefix             = "AMIS"                   (prefix for all objects: users, groups, policies, SNS topics, Lambda functions, etc)
domainname             = "retsema.eu"             (domain name that is used for the SIG, this should be an internal domain name that 
                                                   doesn't exist on the public internet).
keyprefix              = "KeyG-"                  (when something goes wrong with destroying the environment, then the keys are 
                                                   destroyed but the aliases are not disconnected. When you try to create a new key 
                                                   with the same label (f.e. KeyG-AMIS1) then this will fail, even when the key is 
                                                   marked for deletion. Please change this name on four places: 
                                                   ../../terraform.tfvars, ../shop/terraform-shop.py, ../client/encrypt_and_send.py, 
                                                   ../client/100x.py)
```

## Changes for AWS CLI

The AWS CLI is used in the scripts. Please install the AWS CLI (yum install aws-cli -y) and use `aws configure` to add AWS access key, secret access key, default region (which should be the SIG region) to your machine.

## Shell scripts

The following shell scripts exist:

### `init-infra.sh`

This script will use terraform-init.tf to create all relevant objects:
- IAM: users, groups, policies, roles. One role and one policy will be used for all users. There are (three) different roles and policies for the accept, the decrypt and the process Lambda function. These are general roles, not on a per-user base.
- KMS: one key per user. The prefix of this key is defined in the terraform-infra.tf file. When you destroyed keys from the GUI, AWS will wait for 31 days before deleting the key. The GUI will not permit you to delete the name of the key (and when Terraform creates a new key, then this key name must be different than the key that is already pending a destroy).
- DynamoDB: there is one DynamoDB table for all the shops. The DynamoDB table might also be filled differently for Acceptance and Production (though this is not further discussed/implemented).

After using the terraform script to create users, the CLI is used for adding easy-to-remember passwords to the users (Terraform has no way to create an initial password).
Python is used for adding records to the DynamoDB database. On this moment, Terraform will create an error if you add records to a table with a secundary index.

The script `create-terraform-cicd-tfvars.sh` script will be run: this will add the access key and secret access key from AMIS0 to a (newly created) script ../../terraform-cicd.tfvars file. This tfvars file (with less privileges than the account you use for creating the infra) will be used to create the shop environment.

After using `init-infra.sh`, you are ready to use `init-shop.sh` (in the shop directory) to create shop objects.

### `destroy-infra.sh`

When you want to stop, use the `destroy-shop.sh` (in the shop directory) to delete the shop objects.\
When all shop objects are destroyed, you can use destroy-infra.sh to use `terraform destroy` to destroy all infra objects.

### `clean-infra-dir.sh`

When all objects are destroyed using the destroy-infra.sh script, you might want to delete the specific
Terraform directories and files. This script will NOT delete the tfvars files in the ../.. directory,
you might want to clean this up yourself.

### `create-terraform-cicd-tfvars.sh`

See above in the description of init-infra.sh

