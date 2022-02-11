####################################
### General Resources 
####################################
resource "random_string" "random" {
  length           = 8
  lower            = true
  upper            = false
  special          = false
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


####################################
### IAM
####################################

resource "aws_iam_user" "user" {
  for_each = toset(var.Userlist)
  name = each.key
}

resource "aws_iam_access_key" "access_key" {
  for_each = toset(var.Userlist)
  user    = each.key
  pgp_key = "keybase:${var.KeybaseUser}"
  depends_on = [aws_iam_user.user]
}

resource "aws_iam_user_login_profile" "login_profile" {
  for_each = toset(var.Userlist)
  user = each.key
  password_reset_required = true
  pgp_key = "keybase:${var.KeybaseUser}"
  depends_on = [aws_iam_user.user]
}

resource "aws_iam_user_policy" "iam_policy" {
  for_each = toset(var.Userlist)
  name = "${each.key}-iam"
  user = each.key
  depends_on = [aws_iam_user.user]

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "iam:ChangePassword"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:iam::*:user/${each.key}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:GetAccountPasswordPolicy"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

####################################
### DynamoDB
####################################

resource "aws_dynamodb_table" "table_project" {
  count = var.DynamoCreation ? 1 : 0
  name             = var.DynamoTable
  hash_key         = var.DynamoIndexAttribute
  billing_mode     = "PAY_PER_REQUEST"
  stream_enabled   = false

  attribute {
    name = var.DynamoIndexAttribute
    type = "S"
  }
}

resource "aws_iam_user_policy" "dynamodb_policy" {
  for_each = { for k, r in toset(var.Userlist) : k => r if var.DynamoCreation }
  name = "${each.key}-dynamodb"
  user = each.key
  depends_on = [aws_iam_user.user]

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "dynamodb:*",
                "dax:*"
            ],
            "Effect": "Allow",
            "Resource": "${aws_dynamodb_table.table_project[0].arn}"
        },
        {
            "Action": [
                "dynamodb:ListTables"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}

####################################
### S3
####################################

resource "aws_s3_bucket_public_access_block" "bucket_project_public_access_block" {
  count = var.BucketCreation ? 1 : 0
  bucket = aws_s3_bucket.bucket_project[0].id
  block_public_acls   = true
  block_public_policy = true
  restrict_public_buckets = true
  depends_on = [aws_s3_bucket.bucket_project[0]]
}

resource "aws_s3_bucket" "bucket_project" {
  count = var.BucketCreation ? 1 : 0
  bucket = "s3-bucket-${var.BucketNamePrefix}-${random_string.random.result}"
  acl    = "private"
  tags = {
    Type = "${var.ProjectName}"
  }
  force_destroy = true
}

resource "aws_iam_user_policy" "s3_permissions" {
  for_each = { for k, r in toset(var.Userlist) : k => r if var.BucketCreation }
  name = "${each.key}-s3"
  user = each.key
  depends_on = [aws_iam_user.user]

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowUserToSeeBucketListInTheConsole",
            "Action": [
                "s3:ListAllMyBuckets",
                "s3:GetBucketLocation"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::*"
            ]
        },
        {
            "Sid": "AllowUserToSeeBucket",
            "Action": [
                "s3:ListBucket"
            ],
            "Effect": "Allow",
            "Resource": [
                "${aws_s3_bucket.bucket_project[0].arn}"
            ]
        },
        {
            "Sid": "AllowAllS3Actions",
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "${aws_s3_bucket.bucket_project[0].arn}/*"
            ]
        }
    ]
}
EOF
}

####################################
### SNS
####################################

resource "aws_sns_topic" "sns_topic" {
  count = var.SnsCreation ? 1 : 0
  name = var.SnsTopic
}

resource "aws_sns_topic_subscription" "sns_subscription" {
  count = var.SnsCreation ? 1 : 0
  topic_arn = aws_sns_topic.sns_topic[0].arn
  protocol  = "email"
  endpoint  = "${var.EmailtoNotify}"
}

resource "aws_iam_user_policy" "sns_policy" {
  for_each = { for k, r in toset(var.Userlist) : k => r if var.SnsCreation }
  # for_each = toset(var.Userlist)
  name = "${each.key}-sns"
  user = each.key
  depends_on = [aws_iam_user.user]

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "sns:Publish",
                "sns:Subscribe",
                "sns:Unsubscribe"
            ],
            "Effect": "Allow",
            "Resource": "${aws_sns_topic.sns_topic[0].arn}"
        }
    ]
}
EOF
}

####################################
### EKS
####################################

resource "aws_iam_user_policy" "eks_policy" {
  for_each = toset(var.Userlist)
  name = "${each.key}-eks"
  user = each.key
  depends_on = [aws_iam_user.user]

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ListClusters",
            "Effect": "Allow",
            "Action": [
                "eks:ListClusters",
                "eks:DescribeAddonVersions"
            ],
            "Resource": "*"
        },
        {
            "Sid": "FullAccessCluster",
            "Effect": "Allow",
            "Action": "eks:*",
            "Resource": "arn:aws:eks:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${var.EksName}"
        }
    ]
}
EOF
}

# data.aws_caller_identity.current.account_id
