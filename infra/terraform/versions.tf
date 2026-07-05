terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Copy backend.tf.example to backend.tf and fill the real bucket/table names.
  # backend.tf is intentionally gitignored through *.tfvars/state rules and should
  # not contain secrets.
}
