provider "aws" {
  region = "${var.aws_region}"
}

# API Gateway
resource "aws_api_gateway_rest_api" "EndpointAPI" {
  name        = "EndpointAPI"
  description = "Take JSON data and send to Lambda to parse into a SQS queue"
}

resource "aws_api_gateway_resource" "EndpointAPIResource" {
  rest_api_id = "${aws_api_gateway_rest_api.EndpointAPI.id}"
  parent_id   = "${aws_api_gateway_rest_api.EndpointAPI.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "EndpointAPIMethod" {
  rest_api_id   = "${aws_api_gateway_rest_api.EndpointAPI.id}"
  resource_id   = "${aws_api_gateway_resource.EndpointAPIResource.id}"
  http_method   = "POST"
  authorization = "NONE"

  request_parameters = {
    "method.request.querystring.key" = true
  }
}

resource "aws_api_gateway_integration" "EndpointAPILambdaIntegration" {
  rest_api_id             = "${aws_api_gateway_rest_api.EndpointAPI.id}"
  resource_id             = "${aws_api_gateway_resource.EndpointAPIResource.id}"
  http_method             = "${aws_api_gateway_method.EndpointAPIMethod.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.EndpointAPILambda.invoke_arn}"
  content_handling        = "CONVERT_TO_TEXT"

  /*request_templates = {
    "application/json" = "{\n  \"path\" : $context.path,\n  \"body\" : $input.json('$'),\n  \"headers\": {\n    #foreach($param in $input.params().header.keySet())\n    \"$param\": \"$util.escapeJavaScript($input.params().header.get($param))\" #if($foreach.hasNext),#end\n    \n    #end  \n  }\n}"
  }*/
}

resource "aws_api_gateway_method_response" "EndpointAPIResponse200" {
  rest_api_id = "${aws_api_gateway_rest_api.EndpointAPI.id}"
  resource_id = "${aws_api_gateway_resource.EndpointAPIResource.id}"
  http_method = "${aws_api_gateway_method.EndpointAPIMethod.http_method}"
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "EndpointAPIIntegrationResponse200" {
  rest_api_id = "${aws_api_gateway_rest_api.EndpointAPI.id}"
  resource_id = "${aws_api_gateway_resource.EndpointAPIResource.id}"
  http_method = "${aws_api_gateway_method.EndpointAPIMethod.http_method}"
  status_code = "${aws_api_gateway_method_response.EndpointAPIResponse200.status_code}"
}

resource "aws_api_gateway_deployment" "EndpointAPIDeployment" {
  depends_on = ["aws_api_gateway_integration.EndpointAPILambdaIntegration"]

  rest_api_id = "${aws_api_gateway_rest_api.EndpointAPI.id}"
  stage_name  = "Production"
}

# SQS
resource "aws_sqs_queue" "EndpointAPIQueue" {
  name                      = "EndpointAPIQueue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 345600
  receive_wait_time_seconds = 0

  tags {
    Terraform = "true"
  }
}

resource "aws_sqs_queue" "EndpointAPIQueueStripe" {
  name                      = "EndpointAPIQueueStripe"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 345600
  receive_wait_time_seconds = 0

  tags {
    Terraform = "true"
  }
}

# Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.EndpointAPILambda.arn}"
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.aws_region}:${var.account_id}:${aws_api_gateway_rest_api.EndpointAPI.id}/*/${aws_api_gateway_method.EndpointAPIMethod.http_method}${aws_api_gateway_resource.EndpointAPIResource.path}"
}

resource "aws_lambda_function" "EndpointAPILambda" {
  filename         = "lambda.py.zip"
  function_name    = "EndpointAPILambda"
  role             = "arn:aws:iam::229884242446:role/EndpointAPIRole"
  handler          = "lambda.lambda_handler"
  runtime          = "python3.6"
  source_code_hash = "${base64sha256(file("lambda.py.zip"))}"
  timeout          = "300"
}
