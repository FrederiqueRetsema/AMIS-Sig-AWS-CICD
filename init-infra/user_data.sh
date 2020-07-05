#! /bin/bash
yum update -y
yum install git python3 -y
pip3 install git-remote-codecommit

cd ~ec2-user
cat > ./run_as_ec2-user.sh <<EOF
curl https://releases.hashicorp.com/terraform/0.12.26/terraform_0.12.26_linux_amd64.zip --output terraform.zip
unzip terraform.zip
rm -f terraform.zip
chmod 755 terraform
mkdir start
cd start
curl https://raw.githubusercontent.com/FrederiqueRetsema/AMIS-Sig-AWS-CICD/master/start/terraform_sig.tf --output terraform_sig.tf
mkdir lambdas
cd lambdas
curl https://raw.githubusercontent.com/FrederiqueRetsema/AMIS-Sig-AWS-CICD/master/start/lambdas/sig.py --output sig.py
EOF
chmod 755 run_as_ec2-user.sh
sudo -u ec2-user ./run_as_ec2-user.sh
rm -f run_as_ec2-user.sh

