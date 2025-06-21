provider "aws" {
  region = "us-east-1"
}

# DynamoDB Table for chat logs and session data
resource "aws_dynamodb_table" "chat_logs" {
  name         = "ChatLogs"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "sessionId"

  attribute {
    name = "sessionId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  # Optional: Use a composite key for better querying
  range_key = "timestamp"
}

# IAM Role that Lambda assumes
resource "aws_iam_role" "lambda_exec_role" {
  name = "ChatbotLambdaExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# IAM Policy for Lambda to access AI services and DynamoDB
resource "aws_iam_role_policy" "lambda_policy" {
  name = "ChatbotLambdaPolicy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.chat_logs.arn
      },
      {
        Effect = "Allow"
        Action = [
          "lex:PostText",
          "lex:PostContent",
          "transcribe:StartStreamTranscription",
          "comprehend:DetectSentiment",
          "comprehend:DetectEntities",
          "translate:TranslateText",
          "rekognition:DetectLabels",
          "rekognition:DetectModerationLabels",
          "bedrock:*",             # Assuming Bedrock API actions, adjust as needed
          "polly:SynthesizeSpeech",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda function - backend logic (needs zip with your code)
resource "aws_lambda_function" "chatbot_lambda" {
  function_name = "CustomerSupportChatbot"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  filename         = "chatbot_lambda.zip" # Your zipped Lambda function
  source_code_hash = filebase64sha256("chatbot_lambda.zip")

  # Optionally configure memory and timeout for AI service calls
  memory_size      = 1024
  timeout          = 30
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "chatbot_api" {
  name        = "CustomerSupportChatbotAPI"
  description = "API Gateway for Multimodal Customer Support Chatbot"
}

# Resource in API Gateway root: /chat
resource "aws_api_gateway_resource" "chat_resource" {
  rest_api_id = aws_api_gateway_rest_api.chatbot_api.id
  parent_id   = aws_api_gateway_rest_api.chatbot_api.root_resource_id
  path_part   = "chat"
}

# Method POST on /chat
resource "aws_api_gateway_method" "post_chat" {
  rest_api_id   = aws_api_gateway_rest_api.chatbot_api.id
  resource_id   = aws_api_gateway_resource.chat_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integration with Lambda
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.chatbot_api.id
  resource_id             = aws_api_gateway_resource.chat_resource.id
  http_method             = aws_api_gateway_method.post_chat.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.chatbot_lambda.invoke_arn
}

# Permission for API Gateway to invoke Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chatbot_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.chatbot_api.execution_arn}/*/*"
}

# Deployment of API Gateway
resource "aws_api_gateway_deployment" "chatbot_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.chatbot_api.id
  # Remove stage_name here
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.chatbot_api.id
  deployment_id = aws_api_gateway_deployment.chatbot_deployment.id
  stage_name    = "prod"
}

