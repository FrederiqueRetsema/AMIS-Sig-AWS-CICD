echo aws_access_key = \"`grep AccessKeyId created-access-keys.txt | awk -F ":" '{print $2}' | awk -F "\"" '{print $2}'`\" > ../../terraform-cicd.tfvars
echo aws_secret_key = \"`grep SecretAccessKey created-access-keys.txt | awk -F ":" '{print $2}' | awk -F "\"" '{print $2}'`\" >> ../../terraform-cicd.tfvars
echo domainname = \"retsema.eu\" >> ../../terraform-cicd.tfvars


