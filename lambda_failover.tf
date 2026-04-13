# Empaqueta el index.py que está en la misma carpeta
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/index.py"
  output_path = "${path.module}/lambda_failover.zip"
}

resource "aws_lambda_function" "cambiar_pesos" {
  function_name    = "failover-cambiar-pesos-alb"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "python3.11"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      LISTENER_ARN = aws_lb_listener.https.arn
      WEB_TG_ARN   = aws_lb_target_group.web_tg.arn
      EC2_TG_ARN   = aws_lb_target_group.ec2_tg.arn
    }
  }
}

# Permiso para que SNS invoque la Lambda
resource "aws_lambda_permission" "sns_invoke" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cambiar_pesos.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.failover_topic.arn
}

# IAM Role para la Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-failover-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_alb_policy" {
  name = "lambda-alb-policy"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["elasticloadbalancing:ModifyListener", "elasticloadbalancing:DescribeListeners"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      }
    ]
  })
}