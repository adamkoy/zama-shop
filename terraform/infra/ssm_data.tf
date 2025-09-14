data "aws_ssm_parameter" "api_key" {
  name            = var.ssm_api_key_name
  with_decryption = true
}

locals {
  api_key_final = data.aws_ssm_parameter.api_key.value
}
