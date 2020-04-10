import json
import boto3
import os
import base64

from botocore.exceptions import ClientError

def get_shop_id_and_decrypted_content(event):
  message = json.loads(event["Records"][0]["Sns"]["Message"])
  print(message)

  shop_id = message["shop_id"]
  decrypted_content = json.loads(message["decrypted_content"])

  return {"shop_id": shop_id, "decrypted_content": decrypted_content}

def update_dynamodb(shop_id, sales):
  try:
    
    for sales_item in sales:
      
      # Construct recordtype by add leading zeroes if necessary
      item_no = int(sales_item["item_no"])
      record_type = "s-{:05d}".format(item_no)
      gross_number = sales_item["gross_number"]
      gross_turnover = sales_item["gross_turnover"]
    
      print("shop_id: " + shop_id + " - record_type: " + record_type + " - gross_number: " + str(gross_number) + " - gross_turnover: " + str(gross_turnover))
     
      dynamodb = boto3.client('dynamodb')
      response = dynamodb.update_item (
          TableName = "AMIS-shops",
          Key = {
            'shop_id': {"S":shop_id},
            'record_type' : {"S":record_type}
          },
          UpdateExpression = "set gross_number = gross_number + :gross_number, gross_turnover = gross_turnover + :gross_turnover, stock = stock - :gross_number",
          ExpressionAttributeValues = {
              ':gross_number'  : {"N":gross_number},
              ':gross_turnover': {"N":gross_turnover}
            },
          ReturnValues = "UPDATED_NEW"
        ) 
    print("Response: " + json.dumps(response))
    
    succeeded = True
    
  except ClientError as e:
    succeeded = False
    print("ERROR:" + shop_id + " - " + str(e))

  return {"succeeded": succeeded}

def lambda_handler(event, context):
  print(event)

  decrypted_content = ""

  response          = get_shop_id_and_decrypted_content(event)
  shop_id           = response["shop_id"]
  decrypted_content = json.loads(response["decrypted_content"])

  print("decrypted_content:")
  print(decrypted_content)

  # Update the DynamoDB table
  response  = update_dynamodb(shop_id, decrypted_content["sales"])
  succeeded = response["succeeded"]

  print("DONE: event: " + json.dumps(event) + \
            ", shop_id: " + shop_id + \
            ", succeeded: " + json.dumps(response["succeeded"]) + \
            ", context.get_remaining_time_in_millis(): " + str(context.get_remaining_time_in_millis()) + \
            ", context.memory_limit_in_mb: " + str(context.memory_limit_in_mb))

