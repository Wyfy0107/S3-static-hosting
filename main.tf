# Create s3 bucket for static files
resource "aws_s3_bucket" "web" {
  bucket        = var.domain_name
  acl           = "private"
  force_destroy = true
  policy        = data.aws_iam_policy_document.s3_policy.json

  website {
    index_document = "index.html"
  }

  tags = {
    Name = var.project
  }
}
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.domain_name}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }
}


# Create and configure route 53 zone and record
resource "aws_route53_zone" "primary" {
  name          = var.domain_name
  force_destroy = true
}

resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.distribution.domain_name
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

# Create and configure cloudfront
locals {
  s3_origin_id = "myS3Origin"
}
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {

}
resource "aws_cloudfront_distribution" "distribution" {
  aliases = [var.domain_name]

  origin {
    domain_name = aws_s3_bucket.web.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE", "FI"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    acm_certificate_arn            = aws_acm_certificate.cert.arn
    ssl_support_method             = "sni-only"
  }
}

# Create ssl certificate
resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn = aws_acm_certificate.cert.arn
}
output "s3_bucket_name" {
  value = aws_s3_bucket.web.id
}
