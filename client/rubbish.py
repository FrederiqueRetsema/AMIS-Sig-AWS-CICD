#!/usr/bin/python3

import sys
import boto3
import requests
import json
import base64

# Constants used in this script

NUMBER_OF_REQUESTS = 1

# get_parameters: 
# - check if there is one parameters and stop if there is not
# - return the url

def get_parameters():

  if (len(sys.argv) != 2):
      print ("Add an argument, f.e. https://amis1.retsema.eu/shop")
      sys.exit(1)

  url       = sys.argv[1]

  return {"url": url}

def create_data():

  data = {"nothing": "", "anything": "Hi there!"}

  return {"data": data}

# send_data:
# - send it x times to the url

def send_data(url, data):

  for request_number in range(NUMBER_OF_REQUESTS):
    print ("request_number = "+str(request_number+1))
    reply = requests.post(url, json.dumps(data))

  return {"reply": reply}

# Main program:
# - get parameter
# - create data
# - send the data

response = get_parameters()
url       = response["url"]

print ("URL            = ", url)

response       = create_data()
data           = response["data"]

print ("Data           = ", data)

response       = send_data(url, data)
reply          = response["reply"]

print ("Status code    = "+str(reply.status_code))
print ("Content        = "+str(reply.content))
