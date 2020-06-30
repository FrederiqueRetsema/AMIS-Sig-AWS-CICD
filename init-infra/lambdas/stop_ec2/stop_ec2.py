import boto3
import os

region    = os.environ['region']
ec2       = boto3.client('ec2', region_name=region)

def lambda_handler(event, context):
    response = ec2.describe_instances()
    instanceIds = []
    for reservation in response["Reservations"]:
      instances = reservation["Instances"]
      for instance in instances:
          instanceIds += [instance["InstanceId"]]

    print("About to stop the following instances: "+str(instanceIds))
    ec2.stop_instances(InstanceIds=instanceIds)
    print('stopped your instances: ' + str(instanceIds))
