data "aws_acm_certificate" "maxdelgiudice" {
  domain   = "maxdelgiudice.com"
  statuses = ["ISSUED"]
}
