# addDynamoDBRecords.py
# ---------------------
#
# It would be better to do this in the terraform file, but there is an error in terraform that adding new records will give
# an error. When terraform fixes this, this script will be deleted and will become part of the terraform_iam.tf config file.
#

import boto3

prefix          = "AMIS"
number_of_users = 5

for userNumber in range(number_of_users):
  dynamodb = boto3.client("dynamodb")
  dynamodb.put_item(
    TableName='AMIS-stores',
    Item={
        'storeID'          : {'S': prefix+str(userNumber)},
        'recordType'       : {'S': 's-00098'},
        'stock'            : {'N': '100000'},
        'grossTurnover'    : {'N': '0'},
        'grossNumber'      : {'N': '0'},
        'itemDescription'  : {'S': '250g Butter'},
        'sellingPrice'     : {'N': '2.45'}})

    
  dynamodb.put_item(
    TableName='AMIS-stores',
    Item={
        'storeID'          : {'S': prefix+str(userNumber)},
        'recordType'       : {'S': 's-12345'},
        'stock'            : {'N': '100000'},
        'grossTurnover'    : {'N': '0'},
        'grossNumber'      : {'N': '0'},
        'itemDescription'  : {'S': '1 kg Chees'},
        'sellingPrice'     : {'N': '12.15'}})
    
  dynamodb.put_item(
    TableName='AMIS-stores',
    Item={
        'storeID'          : {'S': prefix+str(userNumber)},
        'recordType'       : {'S': 's-91279'},
        'stock'            : {'N': '100000'},
        'grossTurnover'    : {'N': '0'},
        'grossNumber'      : {'N': '0'},
        'itemDescription'  : {'S': '10 Eggs'},
        'sellingPrice'     : {'N': '1.99'}})

