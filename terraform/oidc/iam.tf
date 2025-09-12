
locals {
  aws_region = "eu-west-3"
  repo_name  = "zama-shop"  
  repo_arn   = "arn:aws:ecr:${local.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${local.repo_name}"
}

resource "aws_iam_role" "github_actions" {
  name               = "zama-shop-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_trust.json
}

# ECR permissions for GitHub Actions
data "aws_iam_policy_document" "ecr_repo_access" {
  # Login to ECR
  statement {
    sid       = "ECRAuthToken"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # Allow creating the repo if it doesn't exist
  statement {
    sid       = "CreateRepositoryIfMissing"
    effect    = "Allow"
    actions   = ["ecr:CreateRepository"]
    resources = ["*"]
  }

  # Push/Pull/Describe on your specific repo
  statement {
    sid    = "RepoPushPull"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:ListImages",
      "ecr:BatchDeleteImage",
      "ecr:DescribeImageScanFindings",
      "ecr:Describe*",
    ]
    resources = [local.repo_arn]
  }
}

resource "aws_iam_policy" "ecr_repo_access" {
  name   = "zama-shop-github-ecr"
  policy = data.aws_iam_policy_document.ecr_repo_access.json
}

resource "aws_iam_role_policy_attachment" "attach_ecr" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.ecr_repo_access.arn
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
