# ----------------------------------------------------------------------------------------------------------------------
# TERRAFORM VERSION
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.0.0"

  # This module has been updated for helm v3 usage. We do not recommend using this version with helm v2.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.70.0"
    }
  }
}
