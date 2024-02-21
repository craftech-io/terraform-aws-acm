locals {
  # Use existing (via data source) or create new zone (will fail validation, if zone is not reachable)
  use_existing_route53_zone = var.use_existing_route53_zone

  domain       = var.domain
  extra_domain = var.extra_domain

  # Removing trailing dot from domain - just to be sure :)
  domain_name = trimsuffix(local.domain, ".")

  region = "us-east-1"

  zone_id = try(data.aws_route53_zone.this[0].zone_id, aws_route53_zone.this[0].zone_id)
}

##########################################################
# Example (use multiple domains in the same certificate):
# Generate an ACM certificate for multiple domains, useful
# to be used in CloudFront which only supports one ACM
# certificate.
##########################################################

# REF: https://github.com/terraform-aws-modules/terraform-aws-acm/pull/137

provider "aws" {
  region = local.region
}

data "aws_route53_zone" "this" {
  count = local.use_existing_route53_zone ? 1 : 0

  name         = local.domain_name
  private_zone = false
}

resource "aws_route53_zone" "this" {
  count = !local.use_existing_route53_zone ? 1 : 0

  name = local.domain_name
}

data "aws_route53_zone" "extra" {
  count = local.use_existing_route53_zone ? 1 : 0

  name         = local.extra_domain
  private_zone = false
}

resource "aws_route53_zone" "extra" {
  count = !local.use_existing_route53_zone ? 1 : 0

  name = local.extra_domain
}

module "acm_multi_domain" {
  source = "../../modules/acm/"

  domain_name = local.domain_name
  zone_id     = local.zone_id

  subject_alternative_names = [
    "*.alerts.${local.domain_name}",
    "new.sub.${local.domain_name}",
    "*.${local.domain_name}",
    "alerts.${local.domain_name}",
    "*.alerts.${local.extra_domain}",
    "new.sub.${local.extra_domain}",
    "*.${local.extra_domain}",
    "alerts.${local.extra_domain}",
    local.extra_domain,
    "*.${local.extra_domain}"
  ]

  zones = {
    (local.extra_domain)            = try(data.aws_route53_zone.extra[0].zone_id, aws_route53_zone.extra[0].zone_id),
    "alerts.${local.extra_domain}"  = try(data.aws_route53_zone.extra[0].zone_id, aws_route53_zone.extra[0].zone_id),
    "new.sub.${local.extra_domain}" = try(data.aws_route53_zone.extra[0].zone_id, aws_route53_zone.extra[0].zone_id)
  }
}