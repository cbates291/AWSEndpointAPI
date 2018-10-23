# AWSEndpointAPI Project

# Purpose
Using Terraform, Deploy Infrastructure to take JSON input via API to AWS and store in a Queue for processing

## Notes
 - You will need to have the AWS command line and terraform installed and configured to your environment before using this.
 - vars.tf will need to be updated with the account ID for your AWS account.
 - You will need to manually create only the SQS Queue you want to store the JSON data in. Once you create it, you will want to update lambda.py. 
    - You will want to update the route_dict dictionary with the correct values for sqsQueue and key. The sqsQueue needs to be the name of your key and the key is a value you can create or generate and is simply used to validate the API request from wherever you are sending the data from. For example, there is a stripe account that can send logs to a location, you simply enter to send those logs to the URL of the Gateway API that is created. In the case right now the dictionary is setup so that if you send to https://awsurl.gateway.com/stripe?RandomKey, it would validate against the dictionary because the /stripe and the RandomKey match up. This is how you perform validation and send to different queues.
    - Once you update your lambda.py file make sure to re-compress the lambda.py file again so that it can be uploaded when you run terraform.
