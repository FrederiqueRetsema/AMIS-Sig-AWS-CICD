#!/usr/bin/python3

import sys
import boto3
import requests
import json
import base64

# Constants used in this script

FILENAME           = "./sales.txt"
NUMBER_OF_REQUESTS = 1
KEY_PREFIX         = "alias/KeyE-"

# get_parameters: 
# - check if there are two parameters and stop if there are not
# - return the shop, the derived key name and the url

def get_parameters():

  if (len(sys.argv) != 3):
      print ("Add two arguments, f.e. ./encrypt.py AMIS1 https://amis1.retsema.eu/shop")
      sys.exit(1)

  shop     = sys.argv[1]
  keyAlias = KEY_PREFIX + shop
  url      = sys.argv[2]

  return {"shop": shop, "keyAlias": keyAlias, "url": url}

def encrypt_sales(keyAlias):

  kms = boto3.client('kms')

  sales = open(FILENAME, "r")
  file_content = sales.read()
  sales.close()

  encrypted_file = kms.encrypt(KeyId=keyAlias, Plaintext=file_content, EncryptionAlgorithm='RSAES_OAEP_SHA_256')

  # To be able to send the encrypted text in JSON format to the other side, encode it with base64 and utf-8
  #
  encrypted_content = encrypted_file["CiphertextBlob"]
  content_base64 = base64.standard_b64encode(encrypted_content).decode("utf-8")

  #
  #To check if the decrypted CiphertextBlob is the same as here, uncomment next line
  #
  #print("Encrypted content (first 20 characters): "+str(encrypted_content[0:20]))

  return {"content_base64": content_base64}

def send_request(url, shop, content_base64):

  data ={"shop": shop, "content_base64": content_base64}
  print(data)

  for r in range(NUMBER_OF_REQUESTS):
    print(r+1)
    reply = requests.post(url, json.dumps(data))

  return {"reply": reply}

response = get_parameters()
shop = response["shop"]
keyAlias = response["keyAlias"]
url = response["url"]

print ("Shop      = ", shop)
print ("Key alias = ", keyAlias)
print ("URL       = ", url)

response=encrypt_sales(keyAlias)
content_base64 = response["content_base64"]

response=send_request(url, shop, content_base64)
reply=response["reply"]

print (str(reply))
print ("Reply content: "+str(reply.content))
