#!/usr/bin/python3

import sys
import boto3
import requests

if (len(sys.argv) != 3):
    print ("Add two arguments, f.e. ./encrypt.py AMIS1 https://whatever.aws.amazon.com/whatever")
    sys.exit(1)

keyAlias = 'alias/Key'+sys.argv[1]
url = sys.argv[2]

print ("Key alias = ", keyAlias)
print ("URL = ", url)

kms = boto3.client('kms')

sales = open("sales.txt", "r")
content = sales.read()
sales.close()

encryptedFile = kms.encrypt(KeyId=keyAlias, Plaintext=content, EncryptionAlgorithm='RSAES_OAEP_SHA_256')


