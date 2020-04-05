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

def send_to_process_sns_topic(shop, decrypted_content):

  try: 

    # Log content of the data that we received from the API Gateway
    # The output is send to CloudWatch
    #

    print("TRY: event:"+str(event))

    # Initialize the SNS module and get the topic arn. 
    # These are placed in the environment variables of the accept function by the Terraform script
    #

    sns = boto3.client('sns')
    sns_process_topic_arn = os.environ['to_process_topic_arn']

    # Publish the shop and the decrypted content to the SNS topic
    #

    sns.publish(
      TopicArn = sns_process_topic_arn,
      Message = json.dumps(event)
    )

    succeeded = True

  except ClientError as e:

    # Exception handling: send the error to CloudWatch
    #

    print("ERROR: "+str(e))

    succeeded = False

  return { "succeeded": succeeded }


def lambda_handler(event, context):

  decrypted_content = ""

  # There is a lot of information in the event parameter, but we are only interested in the shop and content_base64 values
  # (Other lambda functions that are connected to the same SNS topic might use more parameters)
  #
  response          = get_shop_and_content_base64(event)
  shop              = response["shop"]
  content_base64    = response["content_base64"]
  encrypted_content = base64.standard_b64decode(content_base64)

  # Decrypt the content, using the shop ID as part of the key name
  #
  response          = decrypt(shop, encrypted_content)
  decrypted_content = response["decrypted_content"]

  # When this succeeded, send the content to the SNS topic to process the data.
  #
  if (response["succeeded"]):
    
    # Temporary code, just to show that the object that we decrypted is valid JSON
    response = send_to_process_sns_topic(shop, json.loads(decrypted_content))

  print("DONE: Shop: "+shop+", succeeded: "+str(response["succeeded"])+", event: "+str(event)+", decrypted_content: "+str(decrypted_content)+", context.get_remaining_time_in_millis(): "+str(context.get_remaining_time_in_millis())+", context.memory_limit_in_mb: "+str(context.memory_limit_in_mb))

  # This is a function which is placed after an SNS topic. It doesn't make sense to return content
  #
  return
