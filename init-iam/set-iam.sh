../../terraform init --var-file=../../terraform.tfvars
../../terraform plan --var-file=../../terraform.tfvars --out terraform.tfplans
../../terraform apply "terraform.tfplans"

aws iam create-login-profile --user-name AMIS0 --password DomToren0# --no-password-reset-required
aws iam create-login-profile --user-name AMIS1 --password DomToren1# --no-password-reset-required
aws iam create-login-profile --user-name AMIS2 --password DomToren2# --no-password-reset-required
aws iam create-login-profile --user-name AMIS3 --password DomToren3# --no-password-reset-required
aws iam create-login-profile --user-name AMIS4 --password DomToren4# --no-password-reset-required
# aws iam create-login-profile --user-name AMIS5 --password DomToren5# --no-password-reset-required
# aws iam create-login-profile --user-name AMIS6 --password DomToren6# --no-password-reset-required
# aws iam create-login-profile --user-name AMIS7 --password DomToren7# --no-password-reset-required
# aws iam create-login-profile --user-name AMIS8 --password DomToren8# --no-password-reset-required
# aws iam create-login-profile --user-name AMIS9 --password DomToren9# --no-password-reset-required
# aws iam create-login-profile --user-name AMIS10 --password DomToren10# --no-password-reset-required
# aws iam create-login-profile --user-name AMIS11 --password DomToren11# --no-password-reset-required
# aws iam create-login-profile --user-name AMIS12 --password DomToren12# --no-password-reset-required
# aws iam create-login-profile --user-name AMIS13 --password DomToren13# --no-password-reset-required
# aws iam create-login-profile --user-name AMIS14 --password DomToren14# --no-password-reset-required
# aws iam create-login-profile --user-name AMIS15 --password DomToren15# --no-password-reset-required
# aws iam create-login-profile --user-name AMIS16 --password DomToren16# --no-password-reset-required
# aws iam create-login-profile --user-name AMIS17 --password DomToren17# --no-password-reset-required
# aws iam create-login-profile --user-name AMIS18 --password DomToren18# --no-password-reset-required
# aws iam create-login-profile --user-name AMIS19 --password DomToren19# --no-password-reset-required

#
#
# 
aws iam create-access-key --user-name AMIS0 > ./created-access-keys.txt

