# Create zip
cd lambdas
zip sig.zip sig.py
cd ..

# Use terraform to deploy
../terraform init
../terraform plan -out terraform.tfplans
../terraform apply terraform.tfplans

