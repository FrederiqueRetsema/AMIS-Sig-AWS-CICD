# addDynamoDBRecords.py
# ---------------------
#
# It would be better to do this in the terraform file, but there is an error in terraform that adding new records will give
# an error. When terraform fixes this, this script will be deleted and will become part of the terraform_iam.tf config file.
#

import sys
import boto3

# get_parameters
# --------------
# Get the parameters and give an error if there are no three parameters
# 

def get_parameters():

  if (len(sys.argv) != 4):
      print ("Add two arguments, f.e. ./addDynamoDBRecords.py AMIS 0 2")
      print ("This will add the records for 2 users (AMIS0 and AMIS1) to the database")
      sys.exit(1)

  prefix                 = sys.argv[1]
  offset_number_of_users = int(sys.argv[2])
  number_of_users        = int(sys.argv[3])

  return {"prefix": prefix, "offset_number_of_users": offset_number_of_users, "number_of_users": number_of_users}

# add_records
# -----------
# Add three records for each user to the database
#

def add_records(prefix, offset, number_of_users):

  for userNumber in range(number_of_users):
    dynamodb = boto3.client("dynamodb")
    dynamodb.put_item(
      TableName='AMIS-stores',
      Item={
          'storeID'          : {'S': prefix+str(userNumber+offset)},
          'recordType'       : {'S': 's-00098'},
          'stock'            : {'N': '100000'},
          'grossTurnover'    : {'N': '0'},
          'grossNumber'      : {'N': '0'},
          'itemDescription'  : {'S': '250g Butter'},
          'sellingPrice'     : {'N': '2.45'}})

    
    dynamodb.put_item(
      TableName='AMIS-stores',
      Item={
          'storeID'          : {'S': prefix+str(userNumber+offset)},
          'recordType'       : {'S': 's-12345'},
          'stock'            : {'N': '100000'},
          'grossTurnover'    : {'N': '0'},
          'grossNumber'      : {'N': '0'},
          'itemDescription'  : {'S': '1 kg Chees'},
          'sellingPrice'     : {'N': '12.15'}})
    
    dynamodb.put_item(
      TableName='AMIS-stores',
      Item={
          'storeID'          : {'S': prefix+str(userNumber+offset)},
          'recordType'       : {'S': 's-91279'},
          'stock'            : {'N': '100000'},
          'grossTurnover'    : {'N': '0'},
          'grossNumber'      : {'N': '0'},
          'itemDescription'  : {'S': '10 Eggs'},
          'sellingPrice'     : {'N': '1.99'}})

  return

#
# Main program
#

# Get parameters

response        = get_parameters()
prefix          = response["prefix"]
offset          = response["offset_number_of_users"]
number_of_users = response["number_of_users"]

# Add records

add_records(prefix, offset, number_of_users)

