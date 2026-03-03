output "api_url" {
    description = "Public URL of the API Gateway endpoint"
    value = "https://${aws_api_gateway_rest_api.stocks_api.id}.execute-api.${var.region}.amazonaws.com/prod/movers"
}