# init-iam
These scripts can be used to initialize the CI/CD workshop for AMIS. See other directories for a description of the workshop. 

## Before initialization
Before using these scripts, download Terraform version 0.12.23 and unzip the downloadfile. Put the terraform.exe file
in the root of the directory that this directory is in (or change the batch scripts).

We also need access keys of a user that is able to create, change and delete IAM users, groups, policies. It also needs 
permission to create and delete KMS keys. Copy terraforms-template.tfvars to \terraform.tfvars and change the content:
add the access key and the secret access key.

## Initialization

To initialize the environment, run set-iam.bat. This will create 5 users (AMIS0 - AMIS4) and 5 KMS keys. The usera
will be put in a group AMIS-Sig-CICD. The group will be connected to a (newly created) policy, called AMIS_CICD_policy.

After the creation, all passwords will be set to RepelSteeltje1 for AMIS1, RepelSteeltje2! for AMIS2 etc. 

One set of access keys will be created for the workshop. These keys have less privileges, these will be used for all 
AMIS users, both for console access and for key access. To be able to use these keys, make a copy of terraforms-template.tfvars
and set the access key and secret access key to the values in the outputfile created-access-keys.txt