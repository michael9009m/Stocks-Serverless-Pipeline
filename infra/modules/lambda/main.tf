
resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "dynamodb_access" {
  name = "${var.project_name}-dynamodb-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Resource = var.dynamodb_table_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dynamodb_access" {
  role = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

resource "aws_iam_policy" "secrets_access" {
  name = "${var.project_name}-secrets-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "secretsmanager:GetSecretValue"
        Resource = var.secret_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_access" {
  role = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

# runs daily to get stock data
resource "aws_lambda_function" "ingestion" {
  function_name = "${var.project_name}-ingestion"
  role = aws_iam_role.lambda_exec.arn
  handler = "handler.lambda_handler"
  runtime = "python3.11"
  filename = var.ingestion_zip_path
  source_code_hash = filebase64sha256(var.ingestion_zip_path)

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
      SECRET_NAME = var.secret_name
    }
  }

  timeout = 30
}

resource "aws_lambda_function" "api" {
  function_name = "${var.project_name}-api"
  role = aws_iam_role.lambda_exec.arn
  handler = "handler.lambda_handler"
  runtime = "python3.11"
  filename = var.api_zip_path
  source_code_hash = filebase64sha256(var.api_zip_path)

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
    }
  }

  timeout = 10
}

resource "aws_cloudwatch_event_rule" "daily_trigger" {
  name = "${var.project_name}-daily-trigger"
  schedule_expression = "cron(0 21 * * ? *)"
}

resource "aws_cloudwatch_event_target" "trigger_ingestion" {
  rule = aws_cloudwatch_event_rule.daily_trigger.name
  target_id = "ingestion"
  arn = aws_lambda_function.ingestion.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id = "AllowEventBridge"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingestion.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.daily_trigger.arn
}