import boto3  
import json
import pprint

# This dictionary is where we declare all the acceptable routes
route_dict = {
    "/stripe": {
        "key": "RandomKey",
        "sqsQueue": "QueueName"
    },
    "/calendly": {
        "key": "RandomKey",
        "sqsQueue": "QueueName"
    }
}

def lambda_handler(event, context):

    sqs = boto3.resource('sqs')

    event_dump = json.dumps(event)
    event_dict = json.loads(event_dump)

    incomingPath = event_dict["path"]
    incomingKey = event_dict["queryStringParameters"]["key"]

    if incomingPath in route_dict:
        if incomingKey == route_dict["{}".format(incomingPath)]["key"]:
            queue = sqs.get_queue_by_name(QueueName=route_dict["{}".format(incomingPath)]["sqsQueue"])
            response = queue.send_message(MessageBody=event_dict['body'])
            success = {}
            success["statusCode"] = "200" 
            success["body"] = "Message Received" 
            success["isBase64Encoded"] = "false" 
            return success
        else:
            failure = {}
            failure["statusCode"] = "401" 
            failure["body"] = "Invalid Key Parameter" 
            failure["isBase64Encoded"] = "false" 
            return failure
    else:
        failure = {}
        failure["statusCode"] = "500" 
        failure["body"] = "Invalid Route. Contact the Administrator." 
        failure["isBase64Encoded"] = "false" 
        return failure
