#/usr/bin/bash
#
# destroy-all.sh
# --------------
# 

SIG_REPO_NAME="AMIS-Sig-AWS-CICD"

# ask_yes_no_question
# -------------------
# Ask the user a yes/no question and convert the answer to uppercase
 
function ask_yes_no_question {

  read answer
  answer=`echo ${answer} | tr '[:lower:]' '[:upper:]'`

  echo $answer
}

# get_domain_name
# ---------------

function get_domain_name {

  domain_name=`grep domainname ~/terraform.tfvars | awk -F" " '{print $3}' | awk -F"\"" '{print $2}'`
  echo $domain_name

}

# destroy_infra
# -------------

function destroy_infra {

  region=$1

  cd ~/${region_name}/${SIG_REPO_NAME}/init-infra
  ./destroy-infra.sh
  if (test $? -ne 0)
  then
    echo Destroy of infrastructure failed
    exit 1
  fi

}

# destroy_certificate_if_needed
# -----------------------------

function destroy_certificate_if_needed {

    region_name=$1
    domain_name=$2

    certificate=`aws acm list-certificates | grep "*.${domain_name}"`

    if (test "${certificate}" == "")
    then
        echo "Certificate is already deleted"
    else

        echo "======================================================================================================================================"
        echo "Did you install the certificate via this script (/home/vagrant/destroy-all.sh) AND do you want to delete the certificate?"
        echo "(please mind that you shouldn't do this too often because of the AWS limits on the number of certificates you are allowed to request per year - this defaults to 20)"
        echo ""
        echo "Only yes will destroy the certificate"

        # Read the anser and convert it to upper case
        #

        read answer
        answer=`echo $answer | tr '[:lower:]' '[:upper:]'`

        # Only YES will lead to destruction 
        #
        if (test "${answer^^}" == "YES")
        then
            cd ~/${region_name}/${SIG_REPO_NAME}/init-cert
            ./destroy-cert.sh
            if (test $? -ne 0)
            then
              echo Destroy of certificate failed
              exit 1
            fi

        else
            echo "Didn't destroy the certificate"
        fi
  fi

}

#
# Main program
# ============
#

domain_name=$(get_domain_name)

for region_no in {1..5}
do

  case ${region_no} in
    1)
       region_name=eu-central-1
       ;;
    2)
       region_name=eu-west-2
       ;;
    3)
       region_name=eu-west-3
       ;;
    4)
       region_name=eu-north-1
       ;;
  esac

  if (test -d ~/${region_name})
  then

    destroy_infra ${region_name}
    destroy_certificate_if_needed ${region_name} ${domain_name}

  fi

done

echo "Done"
