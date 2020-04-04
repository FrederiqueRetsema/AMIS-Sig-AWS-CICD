# cleanup-init-infra-dir.sh
# -------------------------
# This script can be used after the (succesful) destroy, to delete unnecessary files and directories.
# In this way, it is more clear which files are relevant for source control - and which ones are not.

rm -f *.tfplans
rm -f *.tfstate
rm -f *.backup
rm -fr .terraform

cd lambdas/accept
rm -f *zip
cd ../..

cd lambdas/process
rm -f *zip
cd ../..
