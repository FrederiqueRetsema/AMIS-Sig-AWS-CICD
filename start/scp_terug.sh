export IP_ADDRESS=54.89.134.255
export PEM_FILE=~/Downloads/lafra4.pem
scp -i ${PEM_FILE} ec2-user@${IP_ADDRESS}:/home/ec2-user/la_init.tf .
scp -i ${PEM_FILE} ec2-user@${IP_ADDRESS}:/home/ec2-user/start/init.sh ./init.sh
scp -i ${PEM_FILE} ec2-user@${IP_ADDRESS}:/home/ec2-user/start/terraform_sig.tf ./terraform_sig.tf
aws s3 cp ./la_init.tf s3://frpublic/AMIS/sig
aws s3 cp ./init.sh s3://frpublic/AMIS/sig/start/init.sh
aws s3 cp ./terraform_sig.tf s3://frpublic/AMIS/sig/start/terraform_sig.tf


