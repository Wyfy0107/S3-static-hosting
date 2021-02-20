resource "aws_s3_bucket" "web" {
  bucket        = var.domain_name
  acl           = "public-read"
  force_destroy = true
  policy        = <<EOF
{
  "Version": "2012-10-17",
  "Statement":[
    {
      "Action": ["s3:GetObject"],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${var.domain_name}/index.html",
        "arn:aws:s3:::${var.domain_name}/index.js"
        ],
      "Principal": "*"
    }
  ]
}
EOF

  website {
    index_document = "index.html"
  }

  tags = {
    Name = var.project
  }
}


resource "aws_route53_zone" "primary" {
  name          = var.domain_name
  force_destroy = true
}

resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_s3_bucket.web.website_endpoint
    zone_id                = aws_s3_bucket.web.hosted_zone_id
    evaluate_target_health = false
  }
}

output "s3_bucket_name" {
  value = aws_s3_bucket.web.id
}
