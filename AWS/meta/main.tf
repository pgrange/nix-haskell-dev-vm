resource "aws_kms_key" "terraform" {
  description             = "This key is used to encrypt Terraform State bucket objects"
  deletion_window_in_days = 10
}
resource "aws_s3_bucket" "remote_state" {
  bucket    = var.STATE_BUCKET

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "S3 Remote Terraform State Store"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "remote_state" {
  bucket = aws_s3_bucket.remote_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "remote_state" {
  bucket = aws_s3_bucket.remote_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "remote_state" {
  bucket = aws_s3_bucket.remote_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# create a dynamodb table for locking the state file
resource "aws_dynamodb_table" "remote_state" {
  name = var.DYNAMODB_TABLE
  hash_key = "LockID"
  read_capacity = 20
  write_capacity = 20
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    Name = "DynamoDB Terraform State Lock Table"
  }
}
