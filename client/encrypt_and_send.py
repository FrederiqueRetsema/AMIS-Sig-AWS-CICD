#!/usr/bin/python3

import sys
import boto3
import requests

if (len(sys.argv) != 3):
    print ("Add two arguments, f.e. ./encrypt.py AMIS1 https://fdzulpm7ji.execute-api.eu-west-1.amazonaws.com/prod/shop")
    sys.exit(1)

shop = sys.argv[1]
keyAlias = 'alias/KeyC-'+shop
url = sys.argv[2]

print ("Shop = ", shop)
print ("Key alias = ", keyAlias)
print ("URL = ", url)

kms = boto3.client('kms')

sales = open("sales.txt", "r")
content = sales.read()
sales.close()

encryptedFile = kms.encrypt(KeyId=keyAlias, Plaintext=content, EncryptionAlgorithm='RSAES_OAEP_SHA_256')

data = "{ \"shop\" = \""+ shop+ "\","+ \
         "\"content\" = \""+ str(encryptedFile["CiphertextBlob"]) + "\" }"
print ("Data = "+str(data))
reply = requests.post(url, data)
print (str(reply))
print ("Reply content: "+str(reply.content))

