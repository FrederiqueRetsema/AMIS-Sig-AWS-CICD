#! /bin/bash
yum install git python3 -y
pip3 install git-remote-codecommit

cd ~ec2-user
curl https://releases.hashicorp.com/terraform/0.12.26/terraform_0.12.26_linux_amd64.zip --output terraform.zip
unzip terraform.zip
rm -f terraform.zip
chmod 755 terraform
