#!/usr/bin/python3

import sys
import boto3

if (len(sys.argv) != 2):
    print ("Add an argument, f.e. ./encrypt.py AMIS1")
    sys.exit(1)

keyAlias = 'alias/Key'+sys.argv[1]
print ("Key alias = ", keyAlias)

kms = boto3.client('kms')

sales = open("sales.txt", "r")
content = sales.read()
sales.close()

encryptedFile = kms.encrypt(KeyId=keyAlias, Plaintext=content, EncryptionAlgorithm='RSAES_OAEP_SHA_256')


