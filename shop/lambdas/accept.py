import json
import boto3
import os

def lambda_handler(event, context):

  sns = boto3.client('sns')
  sns_topic_arn = os.environ['to_process_topic_arn']

  sns.publish(
    TopicArn = sns_topic_arn,
    Message = str(event)
  )
  return {
          'statusCode': 200,
          'body': json.dumps("OK")
  }



