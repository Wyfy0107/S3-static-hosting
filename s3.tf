resource "aws_s3_bucket" "web-static" {
  bucket = "${var.project}-${var.environment}-web"
  acl    = "public-read"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":[{
    "Action": ["s3:GetObject"],
    "Effect": "Allow",
    "Resource": [
      "arn:aws:s3:::test-dev-web/index.html",
      "arn:aws:s3:::test-dev-web/index.js"
      ],
    "Principal": "*"
  }]
}
EOF

  website {
    index_document = "index.html"
  }

  tags = {
    Name = var.project
  }
}

resource "aws_s3_bucket_object" "web-static" {
  bucket       = aws_s3_bucket.web-static.bucket
  key          = "index.html"
  source       = "web-static/index.html"
  content_type = "text/html"
}

resource "aws_s3_bucket_object" "web-static-js" {
  bucket = aws_s3_bucket.web-static.bucket
  key    = "index.js"
  source = "web-static/index.js"
}
