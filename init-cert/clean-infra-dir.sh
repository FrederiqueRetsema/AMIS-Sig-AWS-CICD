# cleanup-init-cert-dir.sh
# ------------------------
# This script can be used after the (succesful) destroy, to delete unnecessary files and directories.
# In this way, it is more clear which files are relevant for source control - and which ones are not.

# Files:

rm -f *.tfplans
rm -f *.tfstate
rm -f *.backup

# Directories:

rm -fr .terraform
