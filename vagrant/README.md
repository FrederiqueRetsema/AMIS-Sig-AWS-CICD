# vagrant

This directory contains the Vagrant file, which can be used to install the environment that the sig was about yourself.

## Create the environment

Instructions:
1) Install vagrant (see https://vagrantup.com/downloads.html) and virtual box (see https://virtualbox.org/wiki/Downloads) on your machine
2) Take care that "hypervisorlaunchtype" in bcdedit is switched to "off". You can check this with `bcdedit` (without parameters) in an administrator cmd session, you can switch this from Hyper-V to VirtualBox by the command `bcdedit /set hypervisorlaunchtype off`. When you want to use Hyper-V again, you can switch back with `bcdedit /set hypervisorlaunchtype auto`. In both cases, you need a restart of the computer after this change.
3) Start cmd, go to the directory with the Vagrant file. If you haven't done so before, then first install the vbguest plugin with `vagrant plugin install vagrant-vbguest` and then (always) type `vagrant up`. This will download and install the OS, use yum update to install updates and download and install the relevant software packages.
4) When `vagrant up` is ready then use `vagrant ssh` to ssh into the virtual machine. You don't have to enter a password here. When you want to use the VirtualBox environment to log on, you can do so by using user `vagrant` with password `vagrant`.
5) In the home directory of vagrant is a file `init-all.sh`. Start this file (`./init-all.sh`). It will ask you to provide an access key and a secret access key, a default region, etc. If you don't know how to get these, this is explained below.

When all questions are asked, the environment will build itself. This is done by deploying multiple terraform scripts in the directories under AMIS-Sig-AWS-CICD. Each directory contains init-xxx.sh and destroy-xxx.sh scripts. You can use these as you please. Please be aware that if you use the script clean-xxx-dir.sh while there are still objects in AWS, these objects WILL NOT be destroyed when you use the destroy-xxx.sh scripts. If you never worked with terraform before, then don't use the clean scripts - you will not need them.

`init-all.sh` will use the following order to install: \
- init-cert -> to request a star certificate (if necessary) for your domain \
- init-infra -> to create IAM (users, groups, permissions etc), DynamoDB (database table), s3 bucket per region, EC2 virtual machines (one per user), etc 

The init-cert and init-infra will start once per region. When you use 4 regions and use 5 users per region, you will have AMIS1-AMIS5 in eu-central-1 (Frankfurt), AMIS6-AMIS10 in eu-west-2 (London), AMIS11-AMIS15 in eu-west-3 (Paris), AMIS16-AMIS20 in eu-north-1 (Stockholm). AMIS0 is a special case: this user will not be added by the scripts, but it is added to the CodeCommit template. The assumption is, that you will create the AMIS0 user by hand and give it administrator permissions. You can use this for approval of pull requests within CodeCommit.

## Destroy the environment

To destroy the environment in AWS and the vagrant file itself:
1) Use `destroy-all.sh` in the home directory of vagrant to destroy all the environments in AWS. You will be asked several times if you want to destroy objects. Type "yes" (and enter) on all questions (maybe except for the last one, because you might need the star certificate for later - see the paragraph "warning for AWS limits on certificates" below).
2) Use "exit" to go back to the cmd shell on your PC
3) Use `vagrant halt` to stop the VM. If you want to continue later, you can use `vagrant up` to start the VM again and `vagrant ssh` to enter the VM. The init-all.sh file will see what objects or directories are missing and will roll out the environment to AWS again, without asking you questions that it already has the answer for.
4) Use  `vagrant destroy` to destroy the VM. Please use this with care: when you destroyed the VM when there were still objects in AWS, you might have to delete these by hand.

## Creating access keys and secret access keys

In this example, I will create a new user, with administrator rights. This user cannot log on to the console, it can only be used by the AWS CLI (Command Line Interface) or the AWS SDK (Service Development Kit, f.e. boto3 for Python).

1) Create an AWS account (go to https://aws.amazon.com and go to the bottom of the screen. Under "Resources for AWS", click on the link "Getting Started". You can sign up for a free tier account. You have to provide a credit count number. When I prepared this SIG, I created lots of objects, destroyed lots of objects, had the environment running for hours and the total amount of money was still less than 10 dollars. The only thing you have to remember is always to destroy your environment when you don't use it and recreate it when you decide later to continue.
2) Logon to AWS. Click in the top menu on Services, type IAM in the text box. IAM stands for Identity and Access Management. Click on IAM under the text box.\
![alt text](https://frpublic.s3-eu-west-1.amazonaws.com/AMIS/blog+images/AWS+IAM+new+keys/2+IAM+service.png)
3) In IAM, click in the left menu on users\
![alt text](https://frpublic.s3-eu-west-1.amazonaws.com/AMIS/blog+images/AWS+IAM+new+keys/3+Users.png)
4) In the top menu, click on "Add user"\
![alt text](https://frpublic.s3-eu-west-1.amazonaws.com/AMIS/blog+images/AWS+IAM+new+keys/4+Add+user.png)
5) Give the user a name and click on the checkbox before "Programmatic access". Click on the button "Next: permissions" on the bottom of the screen\
![alt text](https://frpublic.s3-eu-west-1.amazonaws.com/AMIS/blog+images/AWS+IAM+new+keys/5+Name+and+programmatic+access.png)
6) In the next screen, click on "Attach existing policies directly", and then on the checkbox before "AdministratorAccess". Click then on the button "Next: Tags"\
![alt text](https://frpublic.s3-eu-west-1.amazonaws.com/AMIS/blog+images/AWS+IAM+new+keys/6+Attach+existing+policies+directly.png)
7) In the next screen, you don't need to add tags. Press on "Next: Review"\
![alt text](https://frpublic.s3-eu-west-1.amazonaws.com/AMIS/blog+images/AWS+IAM+new+keys/7+Tags.png)
8) In the review screen, press on "Create user"\
![alt text](https://frpublic.s3-eu-west-1.amazonaws.com/AMIS/blog+images/AWS+IAM+new+keys/8+Create+user.png)
9) In the next screen, you see the Access key ID. Press on Show to see the Secret Access Key. Copy and paste these to your PC. You can also click on Download .csv to get this information. Please mind, that it is impossible to get the Secret access key from AWS the moment you leave this screen. Is it possible to delete the current key and create a new access key, if you want to. Press "Close" when you are done on this screen.\
![alt text](https://frpublic.s3-eu-west-1.amazonaws.com/AMIS/blog+images/AWS+IAM+new+keys/9+Get+keys.png)

## Warning for AWS limits on certificates

When I created this environment, I ran into trouble because I requested a certificate several times, and when I destroyed the environment I also destroyed my certificate. I then ran into the AWS limit on the maximum number of certificates per region per year, which turned out to be 20. This is not that much when you are testing. I therefore re-designed the solution, to create the certificate in a seperate step when you compare it to the rest of the infrastructural objects of this example. 

Advice: if you use a certificate only for this shop example, then create the certificate the first time you use this environment. I will write several blogs, and you can destroy/install the shop environment (first "yes") and the infra environment (second "yes") and then leave the certificate as it is. In the next init-all.sh, the existing certificate will be recognised and not be requested again. You will then not walk into troubles when you follow this series of blogs.

After the last blog, you might want to destroy the certificate. 

## What to do when I cannot destroy the environment via Terraform?

A full description of the objects that are created by the Terraform scripts can be found in the faq. You can use the GUI to go to the relevant services and delete the objects by hand.

## Questions

I made a FAQ to answer frequently asked questions (and their answers). You can find it in the same directory as this README.md (and vagrant) file.

