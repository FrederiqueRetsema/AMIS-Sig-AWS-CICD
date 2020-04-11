# init-infra

These scripts are used to initialize the CI/CD workshop for a workshop within AMIS. See other directories 
for a description of the workshop. 

When you want to initialize an environment yourself and if you are new to the combination of Terraform and 
AWS, it might be easyer to go to the vagrant directory and use vagrant to set up the environment for you. 
You will find more information in the README.md file in the vagrant directory and can ignore the rest of 
the README.md you are reading now.

## Before initialization

Before using these scripts, download Terraform version 0.12.24 and unzip the downloadfile. Put the
terraform.exe file in the same directory as you used the git clone command: the scripts use the relative
directory ../.. for this (you might want to change the batch scripts if this is different in your 
environment).The server where these scripts are used must also have the AWS CLI, Python3 and boto3 installed.

The scripts use an access key of a user that is able to create, change and delete IAM users, groups, policies.
It also needs permission on KMS keys and DynamoDB. If you need help in creating the access key and secret 
access key, then please read ../vagrant/README.md. 

Copy terraforms-template.tfvars to ../../terraform.tfvars and change the content: add the access key and the
secret access key of an administrative user to this file, change other parameters if you want to and run
the `init-infra.sh` script.

__WARNING__: you need a star certificate for your domain name. For example, when you use retsema.eu as domain
name, you need a certificate *.retsema.eu . Terraform can create this for you, but it is not part of the
scripts in this directory.

To help you, you can request this certificate by using the `init-cert.sh` script in the directory ../init-cert

## List of parameters in ../../terraform.tfvars
Please mind, that if you use the init-all.sh script, then many of these defaults are changed automatically.

``` terraform.tfvars
aws_access_key         = "your access key"        (administrator user)
aws_secret_key         = "your secret access key" (administrator user)
aws_region             = "eu-west-1"              (region for the SIG: pipelines and shops are build in this region)
account_number         = "123456789012"           (account number, without dashes. Is used for IAM policies)
number_of_users        = 2                        (max 20 per region)
offset_number_of_users = 1                        (number to add to the first user. 1 means: first user is AMIS1)
nameprefix             = "AMIS"                   (prefix for all objects: users, groups, policies, SNS topics, Lambda functions, etc)
domainname             = "retsema.eu"             (domain name that is used for the SIG, this should be an external domain name that 
                                                   exists on the public internet).
key_prefix             = "KeyI-"                  (when something goes wrong with destroying the environment, then the keys are 
                                                   destroyed but the aliases are not disconnected. When you try to create a new key 
                                                   with the same label (f.e. KeyI-AMIS1) then this will fail, even when the key is 
                                                   marked for deletion. See the faq in ../vagrant/faq.pdf how to fix this)
```

## Changes for AWS CLI

The AWS CLI is used in the scripts. Please install the AWS CLI (yum install aws-cli -y) and use `aws configure` to add AWS access key, secret access key, default region (which should be the SIG region) to your machine.

## Shell scripts

The following shell scripts exist:

### `init-infra.sh`

This script will use terraform-init.tf to create all relevant objects:
- IAM: users, groups, policies, roles. One role and one policy will be used for all users. There are (three) different roles and policies for the accept, the decrypt and the process Lambda function. These are general roles, not on a per-user base.
- KMS: one key per user. The prefix of this key is defined in the ../../terraform.tfvars file.
- DynamoDB: there is one DynamoDB table for all the shops. The DynamoDB table might also be filled differently for (f.e.) Acceptance and Production (though this is not further discussed/implemented).

After using the terraform script to create users, the CLI is used for adding easy-to-remember passwords to the users (Terraform has no way to create an initial password). The AWS CLI will also be used to get the access key of the first user that is created, this will be used as access key and secret access key for use by the shop terraform scripts. The output of this AWS command will be send to a text file in the current directory, that can be read by the `create-terraform-cicd-tfvars.sh` script.

The script `create-terraform-cicd-tfvars.sh` will be run: this will fill the content of ../../terraform-cicd.tfvars file. In this way, when you want to change something in your infrastructure then just delete the environment and start `init-infra.sh`. You will get a new ../../terraform-cicd.tfvars file that will be used by the shop. 

Python is used for adding records to the DynamoDB database. The name_prefix, the number of users ("shops"), the starting number the prefix are all passed by the `init-infra.sh` script. 

After using `init-infra.sh`, you are ready to use `init-shop.sh` (in the ../shop directory) to create shop objects.

### `destroy-infra.sh`

When you want to stop, use the `destroy-shop.sh` (in the shop directory) to delete the shop objects.\
When all shop objects are destroyed, you can use destroy-infra.sh to use `terraform destroy` to destroy all infra objects. \
When you also want to destroy certificate, use `destroy-cert.sh` (in the init-cert directory) to delete the certificate and the check DNS entry.

### `clean-infra-dir.sh`

When all objects are destroyed using the destroy-infra.sh script, you might want to delete the specific
Terraform directories and files. Use this script only when you are certain that there are no objects left in AWS that are created by Terraform. 
The clean script will NOT delete the tfvars files in the ../.. directory, you might want to clean this up yourself.

### `create-terraform-cicd-tfvars.sh`

See above in the description of init-infra.sh

