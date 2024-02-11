terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws",
      version = "~> 5.36"
    }
  }

  required_version = ">= 1.7.0"
}

provider "aws" {
    region = "us-west-2"
}

// Route53/DNS
resource "aws_route53_zone" "maxdelgiudice" {
    name = "maxdelgiudice.com"
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.maxdelgiudice.zone_id
  name    = "www.maxdelgiudice.com"
  type    = "CNAME"
  ttl     = 300
  records = ["maxdelgiudice.com"]
}

resource "aws_route53_record" "s3_alias" {
  zone_id = aws_route53_zone.maxdelgiudice.zone_id
  name    = "maxdelgiudice.com"
  type    = "A"
  alias {
    evaluate_target_health = false
    name                   = aws_cloudfront_distribution.maxdelgiudice.domain_name
    zone_id                = aws_cloudfront_distribution.maxdelgiudice.hosted_zone_id
  }
}

locals {
  s3_origin_id = "myS3Origin"
  caching_optimized_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
}

// Cloudfront distribution (note: assumes existence of certificate)
resource "aws_cloudfront_distribution" "maxdelgiudice" {
  origin {
    domain_name              = aws_s3_bucket.maxdelgiudice.website_endpoint
    origin_id                = aws_s3_bucket.maxdelgiudice.website_endpoint
    connection_attempts      = 3
    connection_timeout       = 10
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy = "http-only"
      origin_read_timeout = 30
      origin_ssl_protocols = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  http_version        = "http2and3"

  aliases = ["maxdelgiudice.com"]

  default_cache_behavior {
    target_origin_id       = aws_s3_bucket.maxdelgiudice.website_endpoint
    cache_policy_id        = local.caching_optimized_policy_id
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  tags = {
    Environment = "production"
  }

  viewer_certificate {
    acm_certificate_arn            = data.aws_acm_certificate.maxdelgiudice.arn
    cloudfront_default_certificate = false
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }
}


// hosting bucket
resource "aws_s3_bucket" "maxdelgiudice" {
    bucket = "maxdelgiudice.com"
}

resource "aws_s3_bucket_ownership_controls" "maxdelgiudice" {
  bucket = aws_s3_bucket.maxdelgiudice.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
