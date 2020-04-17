# addDynamoDBRecords.py
# ---------------------
#
# It would be better to do this in the terraform file, but there is an error in terraform that adding new records will give
# an error. When this is fixed, this script will be deleted and will become part of the terraform_infra.tf config file.
#
# This script is called by init-infra.sh. Advice: don't start it manually, use init-infra.sh for that. 
#

import sys
import boto3

# get_parameters
# --------------
# Get the parameters and give an error if there are no three parameters
# 

def get_parameters():

  if (len(sys.argv) != 4):
      print ("Add two arguments, f.e. ./addDynamoDBRecords.py AMIS 1 2")
      print ("This will add the records for 2 shops (AMIS1 and AMIS2) to the database")
      sys.exit(1)

  name_prefix            = sys.argv[1]
  offset_number_of_users = int(sys.argv[2])
  number_of_users        = int(sys.argv[3])

  return {"name_prefix": name_prefix, "offset_number_of_users": offset_number_of_users, "number_of_users": number_of_users}

# add_records
# -----------
# Add three records for each shop to the database
#

def add_records(prefix, offset, number_of_users):

  for userNumber in range(number_of_users):
    dynamodb = boto3.client("dynamodb")
    dynamodb.put_item(
      TableName= name_prefix + '-shops',
      Item={
          'shop_id'           : {'S': name_prefix + str(userNumber+offset)},
          'record_type'       : {'S': 's-00098'},
          'stock'             : {'N': '100000'},
          'gross_turnover'    : {'N': '0'},
          'gross_number'      : {'N': '0'},
          'item_description'  : {'S': '250 g Butter'},
          'selling_price'     : {'N': '2.45'}})

    
    dynamodb.put_item(
      TableName = name_prefix + '-shops',
      Item={
          'shop_id'           : {'S': name_prefix + str(userNumber+offset)},
          'record_type'       : {'S': 's-12345'},
          'stock'             : {'N': '100000'},
          'gross_turnover'    : {'N': '0'},
          'gross_number'      : {'N': '0'},
          'item_description'  : {'S': '1 kg Chees'},
          'selling_price'     : {'N': '12.15'}})
    
    dynamodb.put_item(
      TableName = name_prefix + '-shops',
      Item={
          'shop_id'           : {'S': name_prefix + str(userNumber+offset)},
          'record_type'       : {'S': 's-91279'},
          'stock'             : {'N': '100000'},
          'gross_turnover'    : {'N': '0'},
          'gross_number'      : {'N': '0'},
          'item_description'  : {'S': '10 Eggs'},
          'selling_price'     : {'N': '1.99'}})

  return

#
# Main program
#

# Get parameters

response        = get_parameters()
name_prefix     = response["name_prefix"]
offset          = response["offset_number_of_users"]
number_of_users = response["number_of_users"]

# Add records

add_records(name_prefix, offset, number_of_users)

