import json
import boto3
import os
import base64

from botocore.exceptions import ClientError

# This works, but when the message is not formatted correctly, it will give a KeyError:
# try/catch don't seem to work. 
#
# [ERROR] KeyError: 'Records'
# Traceback (most recent call last):
#   File "/var/task/process.py", line 48, in lambda_handler
#     response = get_shop_and_content_base64(event)
#   File "/var/task/process.py", line 10, in get_shop_and_content_base64
#     message = json.loads(event["Records"][0]["Sns"]["Message"])

def get_shop_and_content_base64(event):
  message = json.loads(event["Records"][0]["Sns"]["Message"])
  body = json.loads(message["body"])
  
  print("body = "+str(body))
  
  shop = body["shop"]
  content_base64 = bytearray(body["content_base64"], "utf-8")

  return {"shop": shop, "content_base64": content_base64}

def decrypt(shop, encrypted_content):
  try:
    kms        = boto3.client('kms')
    key_prefix = os.environ['key_prefix']
    key = 'alias/'+key_prefix+shop

    response = kms.decrypt(
      CiphertextBlob = encrypted_content,
      KeyId = key,
      EncryptionAlgorithm="RSAES_OAEP_SHA_256")
    decrypted_content = response["Plaintext"]
    succeeded = True
  except ClientError as e:
    succeeded = False
    decrypted_content = ""
    print("ERROR:" + shop + " - " + str(encrypted_content) + " - " + str(e))

  return {"succeeded": succeeded, "decrypted_content": decrypted_content}

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
  response = get_shop_and_content_base64(event)
  shop = response["shop"]
  content_base64 = response["content_base64"]
  encrypted_content = base64.standard_b64decode(content_base64)

  # Decrypt the content, using the shop ID as part of the key name
  response = decrypt(shop, encrypted_content)
  decrypted_content = response["decrypted_content"]

  # When this succeeded, go ahead and use the information to update DynamoDB... 
  if (response["succeeded"]):
    json_content = json.loads(decrypted_content)
    
    # Temporary code, just to show that the object that we decrypted is valid JSON
    update_dynamodb(shop, json_content["sales"])

  print("Shop: "+shop+", succeeded: "+str(response["succeeded"])+", decrypted_content: "+str(response["decrypted_content"]))

  print("DONE: event:"+str(event)+", context.get_remaining_time_in_millis(): "+str(context.get_remaining_time_in_millis())+", context.memory_limit_in_mb: "+str(context.memory_limit_in_mb)+", context.log_group_name: "+context.log_group_name+", context.log_stream_name: "+context.log_stream_name)


