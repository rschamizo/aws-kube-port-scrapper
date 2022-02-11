output "bucket_id" {
  value = var.BucketCreation ? aws_s3_bucket.bucket_project[0].id : null
  description = "ID of the bucket"
}

output "sns_topic_arn" {
  value = var.SnsCreation ? aws_sns_topic.sns_topic[0].arn : null
  description = "SNS topic ARN"
}

output "passwords" {
  value = { for p in aws_iam_user_login_profile.login_profile : p.user => p.encrypted_password }
}

output "access_key" {
  value = { for p in aws_iam_access_key.access_key : p.user => p.encrypted_secret }
}

output "access_key_id" {
  value = { for p in aws_iam_access_key.access_key : p.user => p.id }
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
  description = "Account id"
}

output "iam_login_url" {
  value = "https://${data.aws_caller_identity.current.account_id}.signin.aws.amazon.com/console"
  description = "IAM signing url"
}

