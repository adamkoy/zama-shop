
locals {
  aws_region = "eu-west-3"
}

resource "aws_iam_role" "github_actions" {
  name               = "zama-shop-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_trust.json
}


resource "aws_iam_role_policy_attachment" "attach_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
