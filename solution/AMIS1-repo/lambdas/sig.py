import json
import os

def lambda_handler(event, context):

    sig_version = os.environ['sig_version']

    name = "stranger"
    if (("body" in event) & (event["body"] != None)):
        print(event["body"])
        body = json.loads(event["body"])
        if ("name" in body):
          name = body["name"]

    print("DEBUG: event: "+json.dumps(event)+", name: "+name+", sig_version: "+sig_version)

    return {
        'statusCode': 200,
        'body': json.dumps('Hello '+name+' from Lambda version '+sig_version+'!')
    }



