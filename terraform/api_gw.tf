data "template_file" "ingest_alert_template" {
  template = file("ingest_alert_swagger.tpl") // fixme

  vars = {
    api_name = "ingest_alert"
    ingest_alert_lambda_arn = "lambda_arn" //fixme
    aws_region = "eu-west-1"
  }
}

resource "local_file" "ingest_alert_swagger_template" {
  filename = "ingest_alert_swagger.yaml"
  content = data.template_file.ingest_alert_template.rendered
}

resource "aws_api_gateway_stage" "default" {
  stage_name = "default"
  rest_api_id = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.api_deployment.id
}

resource "aws_api_gateway_rest_api" "api" {
  name = "ingest_alert"
  body = data.template_file.ingest_alert_template.rendered
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_rest_api.api
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name = "" // workaround: https://github.com/terraform-providers/terraform-provider-aws/issues/2918

}

# API key for tracking endpoint.
resource "aws_api_gateway_api_key" "tracking_api_key" {
  name = "ingest_alert_api_key"
}

resource "aws_api_gateway_usage_plan" "api_usage_plan" {
  depends_on = [
    aws_api_gateway_rest_api.api]
  name = "ingest_alert_usage_plan"
  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage = aws_api_gateway_stage.default.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "integration_api_key_usage_plan" {
  depends_on = [
    aws_api_gateway_usage_plan.api_usage_plan]
  key_id = aws_api_gateway_api_key.tracking_api_key.id
  key_type = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.api_usage_plan.id
}