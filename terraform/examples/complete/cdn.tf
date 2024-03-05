# # C:\Users\user\Documents\GitHub\AMZMall_Dev_GitOps\terraform\examples\complete\cdn.tf
# # CloudFront 관련 리소스를 위한 프로바이더

# resource "aws_s3_bucket" "amzdraw_react_app" {
#     bucket = "amzdraw-react-bucket"
# }

# # S3 버킷에 대한 정적 웹사이트 호스팅 구성을 분리합니다.
# resource "aws_s3_bucket_website_configuration" "amzdraw_react_app_website" {
#     bucket = aws_s3_bucket.amzdraw_react_app.id

#     index_document {
#         suffix = "index.html"
#     }

#     error_document {
#         key = "error.html"
#     }
# }

# # CloudFront 오리진 액세스 아이덴티티(OAI)를 생성합니다.
# resource "aws_cloudfront_origin_access_identity" "oai" {
#     comment = "OAI for amzdraw-react-app"
# }

# # S3 버킷 정책을 업데이트하여 OAI를 통한 접근만을 허용합니다.
# resource "aws_s3_bucket_policy" "amzdraw_react_app_policy" {
#     bucket = aws_s3_bucket.amzdraw_react_app.id

#     policy = jsonencode({
#         Version = "2012-10-17",
#         Statement = [
#             {
#                 Effect    = "Allow",
#                 Principal = {"AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.oai.id}"},
#                 Action    = "s3:GetObject",
#                 Resource  = "${aws_s3_bucket.amzdraw_react_app.arn}/*"
#             },
#         ]
#     })
# }

# resource "aws_cloudfront_distribution" "amzdraw_react_app_distribution" {
#     provider = aws.us_east_1
#     origin {
#         domain_name = "${aws_s3_bucket.amzdraw_react_app.bucket}.s3-website-${var.aws_region}.amazonaws.com"
#         origin_id   = "amzdraw-react-bucket"
        
#         s3_origin_config {
#             origin_access_identity = "origin-access-identity/cloudfront/${aws_cloudfront_origin_access_identity.oai.id}"
#             }
#     }

#     enabled = true
#     is_ipv6_enabled = true
#     default_root_object = "index.html"

#     default_cache_behavior {
#         allowed_methods  = ["GET", "HEAD"]
#         cached_methods   = ["GET", "HEAD"]
#         target_origin_id = "S3-amzdraw-react-app"

#     forwarded_values {
#         query_string = false
#         cookies {
#             forward = "none"
#         }
#     }

#     viewer_protocol_policy = "redirect-to-https"
#     min_ttl                = 0
#     default_ttl            = 3600
#     max_ttl                = 86400
#     }

#     price_class = "PriceClass_All"

#     restrictions {
#     geo_restriction {
#         restriction_type = "none"
#         }
#     }

#     viewer_certificate {
#         acm_certificate_arn      = "arn:aws:acm:us-east-1:009946608368:certificate/7aa04d61-2ca2-4dd9-a1e4-bcdf7733d8b5"
#         ssl_support_method       = "sni-only"
#         minimum_protocol_version = "TLSv1.2_2019"
#     }

#     depends_on = [
#         aws_s3_bucket.amzdraw_react_app,
#         aws_s3_bucket_policy.amzdraw_react_app_policy,
#         aws_s3_bucket_website_configuration.amzdraw_react_app_website
#     ]
# }