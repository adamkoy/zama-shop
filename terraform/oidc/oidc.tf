data "aws_caller_identity" "current" {}

# Fetch GitHub's TLS certs and use the LAST thumbprint 
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

locals {
  github_thumbprints = [for c in data.tls_certificate.github.certificates : c.sha1_fingerprint]
  github_thumbprint  = local.github_thumbprints[length(local.github_thumbprints) - 1]
}

# OIDC Provider for GitHub
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [local.github_thumbprint]
}

data "aws_iam_policy_document" "github_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:adamkoy/zama-shop:*",
        "repo:adamkoy/zama-shop:ref:refs/heads/main",
      ]
    }
  }
}