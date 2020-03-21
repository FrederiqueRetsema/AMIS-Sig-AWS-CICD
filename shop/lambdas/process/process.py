import json
import boto3
import os

def lambda_handler(event, context):

  from botocore.exceptions import ClientError
  try: 
    print("TRY: event:"+str(event))
    sns = boto3.client('sns')
    sns_topic_arn = os.environ['to_process_topic_arn']

    sns.publish(
      TopicArn = sns_topic_arn,
      Message = str(event)
    )
    statusCode = 200
    returnMessage = "OK"
  except ClientError as e:
    print("ERROR: "+str(e))
    statusCode = 500
    returnMessage = "NotOK: retry later, admins: see cloudwatch logs for error"
  print("DONE: statusCode: "+str(statusCode)+", returnMessage: \""+returnMessage+"\", event:"+str(event)+", context.get_remaining_time_in_millis(): "+str(context.get_remaining_time_in_millis())+", context.memory_limit_in_mb: "+str(context.memory_limit_in_mb)+", context.log_group_name: "+context.log_group_name+", context.log_stream_name: "+context.log_stream_name)

  return {
          'statusCode': statusCode,
          'body': json.dumps(returnMessage)
  }



