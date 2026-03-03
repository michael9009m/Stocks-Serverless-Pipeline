# Creates the REST API gateway
resource "aws_api_gateway_rest_api" "stocks_api" {
  name        = "${var.project_name}-api"
  description = "REST API for retrieving top stock movers"
}

# Creates the /movers path on the API
resource "aws_api_gateway_resource" "movers" {
  rest_api_id = aws_api_gateway_rest_api.stocks_api.id
  parent_id   = aws_api_gateway_rest_api.stocks_api.root_resource_id
  path_part   = "movers"
}

# Creates the GET method on /movers endpoint
resource "aws_api_gateway_method" "get_movers" {
  rest_api_id   = aws_api_gateway_rest_api.stocks_api.id
  resource_id   = aws_api_gateway_resource.movers.id
  http_method   = "GET"
  authorization = "NONE"
}

# Connects the GET /movers method to the API Lambda function
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.stocks_api.id
  resource_id             = aws_api_gateway_resource.movers.id
  http_method             = aws_api_gateway_method.get_movers.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.api_lambda_invoke_arn
}

# Deploys the API so it gets a public URL
# depends_on ensures the integration is complete before deploying
resource "aws_api_gateway_deployment" "stocks_api" {
  rest_api_id = aws_api_gateway_rest_api.stocks_api.id

  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]
}

# Creates the prod stage - this is what appears in your public URL
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.stocks_api.id
  rest_api_id   = aws_api_gateway_rest_api.stocks_api.id
  stage_name    = "prod"
}

# Gives API Gateway permission to invoke the Lambda function
resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.api_lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.stocks_api.execution_arn}/*/*"
}

# OPTIONS method needed for CORS preflight requests
# Browsers send this before the real GET request to check if its allowed
resource "aws_api_gateway_method" "options_movers" {
  rest_api_id   = aws_api_gateway_rest_api.stocks_api.id
  resource_id   = aws_api_gateway_resource.movers.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# MOCK integration for OPTIONS - returns a static response without hitting Lambda
resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.stocks_api.id
  resource_id = aws_api_gateway_resource.movers.id
  http_method = aws_api_gateway_method.options_movers.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Defines the 200 response for OPTIONS including the CORS headers
resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.stocks_api.id
  resource_id = aws_api_gateway_resource.movers.id
  http_method = aws_api_gateway_method.options_movers.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# Sets the actual CORS header values that get returned to the browser
resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.stocks_api.id
  resource_id = aws_api_gateway_resource.movers.id
  http_method = aws_api_gateway_method.options_movers.http_method
  status_code = "200"

  depends_on = [
    aws_api_gateway_integration.options_integration,
    aws_api_gateway_method_response.options_200
  ]

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}