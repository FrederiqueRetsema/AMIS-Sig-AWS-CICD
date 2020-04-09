import json
import boto3
import os
import base64

from botocore.exceptions import ClientError

def get_shop_and_decrypted_content(event):
  message = json.loads(event["Records"][0]["Sns"]["Message"])
  print(message)

  shop = message["shop"]
  decrypted_content = json.loads(message["decrypted_content"])

  return {"shop": shop, "decrypted_content": decrypted_content}

def update_dynamodb(shop, sales):
  try:
    
    for sales_item in sales:
      
      # Construct recordtype by add leading zeroes if necessary
      item_no = int(sales_item["item_no"])
      record_type = "s-{:05d}".format(item_no)
      gross_number = sales_item["gross_number"]
      gross_turnover = sales_item["gross_turnover"]
    
      print("store_id: "+shop+" - record_type: "+record_type+" - gross_number: "+str(gross_number)+" - gross_turnover: "+str(gross_turnover))
     
      dynamodb = boto3.client('dynamodb')
      response = dynamodb.update_item (
          TableName = "AMIS-stores",
          Key = {
            'store_id': {"S":shop},
            'record_type' : {"S":record_type}
          },
          UpdateExpression = "set gross_number = gross_number + :gross_number, gross_turnover = gross_turnover + :gross_turnover, stock = stock - :gross_number",
          ExpressionAttributeValues = {
              ':gross_number'  : {"N":gross_number},
              ':gross_turnover': {"N":gross_turnover}
            },
          ReturnValues = "UPDATED_NEW"
        ) 
    
    succeeded = True
    
  except ClientError as e:
    succeeded = False
    print("ERROR:" + shop + " - " + str(e))

  return {"succeeded": succeeded}

def lambda_handler(event, context):
  print(event)

  decrypted_content = ""

  response          = get_shop_and_decrypted_content(event)
  shop              = response["shop"]
  decrypted_content = json.loads(response["decrypted_content"])

  print("decrypted_content:")
  print(decrypted_content)

  # Update the DynamoDB table
  response  = update_dynamodb(shop, decrypted_content["sales"])
  succeeded = response["succeeded"]

  print("DONE: event: "+str(event)+", shop: "+shop+", succeeded: "+str(response["succeeded"])+", context.get_remaining_time_in_millis(): "+str(context.get_remaining_time_in_millis())+", context.memory_limit_in_mb: "+str(context.memory_limit_in_mb))



