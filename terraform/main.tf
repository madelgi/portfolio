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
    region = "us-east-1"
}

locals {
  caching_optimized_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
}


// hosting bucket + perms
resource "aws_s3_bucket" "maxdelgiudice" {
    bucket = "maxdelgiudice.com"
}

resource "aws_s3_bucket_ownership_controls" "maxdelgiudice" {
  bucket = aws_s3_bucket.maxdelgiudice.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_policy" "maxdelgiudice_public_access" {
  bucket = aws_s3_bucket.maxdelgiudice.id
  policy = data.aws_iam_policy_document.maxdelgiudice_public_access.json
}

data "aws_iam_policy_document" "maxdelgiudice_public_access" {
  statement {
    principals  {
      type = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:GetObject"]
    resources = [aws_s3_bucket.maxdelgiudice.arn, "${aws_s3_bucket.maxdelgiudice.arn}/*"]
    effect    = "Allow"
  }

}

resource "aws_s3_bucket_website_configuration" "maxdelgiudice" {
  bucket = aws_s3_bucket.maxdelgiudice.id
  index_document {
    suffix = "index.html"
  }
}

// bucket for external stuff (the gatsby s3 plugin overwrites everything on deploy, so this is
// for static assets managed externally, e.g., my resume)
resource "aws_s3_bucket" "external_maxdelgiudice" {
  bucket = "external.maxdelgiudice.com"
}

resource "aws_s3_bucket_ownership_controls" "external_maxdelgiudice" {
  bucket = aws_s3_bucket.external_maxdelgiudice.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_policy" "external_maxdelgiudice_public_access" {
  bucket = aws_s3_bucket.external_maxdelgiudice.id
  policy = data.aws_iam_policy_document.external_maxdelgiudice_public_access.json
}

data "aws_iam_policy_document" "external_maxdelgiudice_public_access" {
  statement {
    principals  {
      type = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:GetObject"]
    resources = [aws_s3_bucket.external_maxdelgiudice.arn, "${aws_s3_bucket.external_maxdelgiudice.arn}/*"]
    effect    = "Allow"
  }

}

// Cloudfront distribution (note: assumes existence of certificate)
resource "aws_cloudfront_distribution" "maxdelgiudice" {
  origin {
    domain_name              = aws_s3_bucket_website_configuration.maxdelgiudice.website_endpoint
    origin_id                = aws_s3_bucket_website_configuration.maxdelgiudice.website_endpoint
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
    target_origin_id       = aws_s3_bucket_website_configuration.maxdelgiudice.website_endpoint
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
