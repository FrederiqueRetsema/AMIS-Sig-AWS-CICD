#!/usr/bin/python3

import sys
import boto3
import requests
import json
import base64

if (len(sys.argv) != 3):
    print ("Add two arguments, f.e. ./encrypt.py AMIS1 https://fdzulpm7ji.execute-api.eu-west-1.amazonaws.com/prod/shop")
    sys.exit(1)

shop = sys.argv[1]
keyAlias = 'alias/KeyE-'+shop
url = sys.argv[2]

print ("Shop = ", shop)
print ("Key alias = ", keyAlias)
print ("URL = ", url)

kms = boto3.client('kms')

sales = open("sales.txt", "r")
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

data ={"shop": shop, "content_base64": content_base64}
print(data)

for i in range(100):
  print(i)
  reply = requests.post(url, json.dumps(data))
print (str(reply))
print ("Reply content: "+str(reply.content))

