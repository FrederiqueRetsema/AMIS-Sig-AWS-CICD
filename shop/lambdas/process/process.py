import json
import boto3
import os
import base64

from botocore.exceptions import ClientError

def get_shop_and_decrypted_content(event):
  message = json.loads(event["Records"][0]["Sns"]["Message"])
  body = json.loads(message["body"])
  
  print("body = "+str(body))
  
  shop = body["shop"]
  decrypted_content = bytearray(body["decrypted_content"], "utf-8")

  return {"shop": shop, "decrypted_content": decrypted_content}

def update_dynamodb(shop, sales):
  try:
    
    for sales_item in sales:
      
      # Construct recordtype by add leading zeroes if necessary
      itemNo = int(sales_item["itemNo"])
      recordType = "s-{:05d}".format(itemNo)
      grossNumber = sales_item["grossNumber"]
      grossTurnover = sales_item["grossTurnover"]
    
      print("storeId: "+shop+" - recordType: "+recordType+" - grossNumber: "+str(grossNumber)+" - grossTurnover: "+str(grossTurnover))
     
      dynamodb = boto3.client('dynamodb')
      response = dynamodb.update_item (
          TableName = "AMIS-stores",
          Key = {
            'storeID': {"S":shop},
            'recordType' : {"S":recordType}
          },
          UpdateExpression = "set grossNumber = grossNumber + :grossNumber, grossTurnover = grossTurnover + :grossTurnover, stock = stock - :grossNumber",
          ExpressionAttributeValues = {
              ':grossNumber'  : {"N":grossNumber},
              ':grossTurnover': {"N":grossTurnover}
            },
          ReturnValues = "UPDATED_NEW"
        ) 
    
    succeeded = True
    
  except ClientError as e:
    succeeded = False
    print("ERROR:" + shop + " - " + str(e))

  return {"succeeded": succeeded}

def lambda_handler(event, context):

  decrypted_content = ""

  # There is a lot of information in the event parameter, but we are only interested in the shop and content_base64 values
  # (Other lambda functions that are connected to the same SNS topic might use more parameters)
  response          = get_shop_and_decrypted_content(event)
  shop              = response["shop"]
  decrypted_content = response["content_base64"]

  # Update the DynamoDB table
  response  = update_dynamodb(shop, decrypted_content["sales"])
  succeeded = response["succeeded"]

  print("DONE: event: "+str(event)+", shop: "+shop+", succeeded: "+str(response["succeeded"])+", context.get_remaining_time_in_millis(): "+str(context.get_remaining_time_in_millis())+", context.memory_limit_in_mb: "+str(context.memory_limit_in_mb))


