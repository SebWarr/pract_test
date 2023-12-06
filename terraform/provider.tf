# Two providers: AWs and null
# Null: allows to carry out custom actions that may not 
# be part of Terraform’s inbuilt functionalities

terraform {
    required_providers {
    aws = {
        source  = "hashicorp/aws"
        version = "~> 4.16"
    }

    null = {
        source = "hashicorp/null"
    }
    }

    required_version = ">= 1.2.0"
}

provider "aws" {
    region = var.region
}