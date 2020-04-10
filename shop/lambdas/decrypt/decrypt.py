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
#
# Tbd: https://stackoverflow.com/questions/31954507/handle-a-keyerror-while-parsing-json

# check_event_structure
# ---------------------
# This function processes input from SNS. We use a limited amount of data from that, but
# we do expect the event data to have a certain structure. When, for example, a simple
# test is done from within the Lambda gui, then the function will fail with a key error.
# We want a more gracefull way of dealing with this error.
# 
# Check the following structure:
#
# { 
#  "Records": [           <-- exactly 1 record (will not be checked by this fuction, 
#                             second and more records are ignored: SNS will not send 
#                             more than one record: see https://aws.amazon.com/sns/faqs/ 
#                             section Reliability)
#       "Sns" : {
#                  "Message" : "{
#                       ...mind that Message is a string, containing json...
#                                  "body" : "{"shop_id": "[...]", "content_base_64" : "[...]"}"
#                                             ...mind that body is a string, containing json...
# }
#    ]
# }

def check_event_structure(event):
  # Base assumption: correct event structure
  succeeded = True

  # Check for Records:
  if ('Records' in event):
       
    # Check if there is just one element in records
    if (len(event["Records"]) == 1):
      
      # Check if the element contains "Sns"
      if ('Sns' in event["Records"][0]):
              
        # Check if "Sns" contains "Message"
        if ('Message' in event["Records"][0]["Sns"]):
                
          # Check if "Message" contains "body"
          if 'body' in event["Records"][0]["Sns"]["Message"]:
                  
            # Check if the body is valid json:
            try:
              body = json.loads(event["Records"][0]["Sns"]["Message"])["body"]
              print("body: "+str(body))
                  
              # Check if the element "shop_id" is present in the "body":
              if ('shop_id' in body):
                      
                # Check if the element "content_base64" is present in the "body":
                if ('content_base64' in body):
                        
                  # Great: this is a valid message. Don't do anything
                  print("Valid event structure")
                      
                else:
                  print("ERROR in event structure: no content_base_64 in body")
                  succeeded = False

              else:
                print("ERROR in event structure: no shop_id in body")
                succeeded = False
                  
            except ClientError as e:
              print("ERROR in event structure: no valid json in body, " +str(e))
              succeeded = False
          else: 
            print("ERROR in event structure: no body in Message")
            succeeded = False
            
        else:
          print("ERROR in event structure: no Message in Sns")
          succeeded = False
                
      else:
        print("ERROR in event structure: no Sns in element")
        succeeded = False
              
    else:
      print("ERROR in event structure: not at exactly one element in list Records")
      succeeded = False
        
  else:
    print("ERROR in event structure: no element Records in event")
    succeeded = False
    
  return {"succeeded": succeeded}

# get_shop_id_and_content_base64(event)
# ----------------------------------
# This function extracts the fields that we are interested in: shop_id and content_base64. 
# All other fields are ignored.
#

def get_shop_id_and_content_base64(event):

  message = json.loads(event["Records"][0]["Sns"]["Message"])
  body = json.loads(message["body"])
  
  shop_id = body["shop_id"]
  content_base64 = bytearray(body["content_base64"], "utf-8")

  return {"shop_id": shop_id, "content_base64": content_base64}

# decrypt
# -------
# 

def decrypt(shop_id, encrypted_content):
  try:
    kms        = boto3.client('kms')
    key_prefix = os.environ['key_prefix']
    key        = 'alias/' + key_prefix + shop_id

    response = kms.decrypt(
      CiphertextBlob = encrypted_content,
      KeyId = key,
      EncryptionAlgorithm="RSAES_OAEP_SHA_256")

    decrypted_content = response["Plaintext"].decode("utf-8")

    succeeded = True

  except ClientError as e:
    print("ERROR:" + shop_id + " - " + str(encrypted_content) + " - " + str(e))

    succeeded = False
    decrypted_content = ""

  return {"succeeded": succeeded, "decrypted_content": decrypted_content}

def send_to_process_sns_topic(shop_id, decrypted_content):

  try: 

    # Initialize the SNS module and get the topic arn. 
    # These are placed in the environment variables of the accept function by the Terraform script
    #

    sns = boto3.client('sns')
    sns_process_topic_arn = os.environ['to_process_topic_arn']

    # Publish the shop id and the decrypted content to the SNS topic
    #
    data = { "shop_id": shop_id, "decrypted_content": str(json.dumps(decrypted_content))}

    sns.publish(
      TopicArn = sns_process_topic_arn,
      Message = json.dumps(data)
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
  shop_id           = ""

  # There is a lot of information in the event parameter, but we are only interested in the shop id and content_base64 values
  # (Other lambda functions that are connected to the same SNS topic might use more parameters)
  #
  # But first, check that the elements that we DO need, are there
  #
  response          = check_event_structure(event)
  succeeded         = response["succeeded"]
  
  if (succeeded):
    
    # Get the shop id and the encrypted data from the event data
    #
    
    response          = get_shop_id_and_content_base64(event)
    shop_id           = response["shop_id"]
    content_base64    = response["content_base64"]
  
    encrypted_content = base64.standard_b64decode(content_base64)

    # Decrypt the content, using the shop id as part of the key name
    #
    response          = decrypt(shop_id, encrypted_content)
    decrypted_content = response["decrypted_content"]

    # When this succeeded, send the content to the SNS topic to process the data.
    #
    if (response["succeeded"]):

      response = send_to_process_sns_topic(shop_id, decrypted_content)

  print("DONE: shop_id: " + shop_id + \
            ", succeeded: " + str(response["succeeded"]) + \
            ", event: " + json.dumps(event) + \
            ", decrypted_content: " + json.dumps(decrypted_content) + \
            ", context.get_remaining_time_in_millis(): " + str(context.get_remaining_time_in_millis()) + \
            ", context.memory_limit_in_mb: " + str(context.memory_limit_in_mb))

  # This is a function which is placed after an SNS topic. It doesn't make sense to return content
  #
  return


