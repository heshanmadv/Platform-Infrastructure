# Local backend for now — fine for a single operator on a homelab cluster.
# State lives in terraform.tfstate next to this file (gitignored).
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# To move to a remote backend later (e.g. once more than one person or CI
# needs to run terraform apply), replace the block above with one backend
# block, for example:
#
#   terraform {
#     backend "s3" {
#       bucket = "your-bucket"
#       key    = "platform-infra/pi-cluster.tfstate"
#       region = "your-region"
#     }
#   }
#
# then run `terraform init -migrate-state`. Nothing else in this
# environment needs to change.
