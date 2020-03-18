\terraform.exe destroy --var-file=\terraform.tfvars 
del *.tfplans
del *.tfstate
del *.backup
del *.txt
del /q /f .terraform\plugins\windows_amd64
del /q /f .terraform\plugins
del /q /f .terraform
rmdir .terraform\plugins\windows_amd64
rmdir .terraform\plugins
rmdir .terraform
