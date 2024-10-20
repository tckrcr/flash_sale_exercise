provider "aws" {
  region = "us-east-1"
}

resource "aws_ecr_repository" "ecr_repo" {
  name                 = "tec-takehome-2024"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }

}

# Create an IAM user
resource "aws_iam_user" "ecr_user" {
  name = "eks_cluster_access" # Change to your desired IAM user name
}

# Create an IAM policy for ECR access
resource "aws_iam_policy" "ecr_access_policy" {
  name        = "ECRAccessPolicy"
  description = "Policy to allow access to ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DeleteRepository",
          "ecr:DeleteRepositoryPolicy",
          "ecr:DescribeRepository",
        ]
        Resource = aws_ecr_repository.ecr_repo.arn
      },
    ]
  })
}

# Attach the policy to the IAM user
resource "aws_iam_policy_attachment" "attach_ecr_policy" {
  name       = "ecr-access-attachment"
    users      = [aws_iam_user.ecr_user.name]
  policy_arn = aws_iam_policy.ecr_access_policy.arn

}

# Output the repository URL and IAM user access credentials
output "repository_url" {
  value = aws_ecr_repository.ecr_repo.repository_url
}

output "iam_user_access_key" {
  value = aws_iam_access_key.my_user_access_key.id
}

output "iam_user_secret_key" {
  value     = aws_iam_access_key.my_user_access_key.secret
  sensitive = true
}

resource "aws_iam_access_key" "my_user_access_key" {
  user = aws_iam_user.ecr_user.name
}