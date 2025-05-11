// provider.tf

// This block defines the specific providers required by your configuration.
// Terraform will download and install these providers when you run `terraform init`.
terraform {
  required_providers {
    // We are declaring that we need the "aws" provider.
    aws = {
      source  = "hashicorp/aws" // This specifies the official AWS provider from HashiCorp.
      version = "~> 5.0"        // This constrains the provider version to any version
                                // compatible with 5.0 (e.g., 5.0.1, 5.1.0, but not 6.0.0).
                                // Using version constraints helps ensure that your configuration
                                // behaves predictably even if new, potentially breaking versions
                                // of the provider are released. It's good practice to use a
                                // recent, stable version.
    }
  }
}

// This block configures the AWS provider.
// Terraform uses these settings to authenticate and target the correct AWS region.
provider "aws" {
  // Specifies the AWS region where your resources will be created.
  // We are using a variable `var.aws_region` here, which we will define
  // in `variables.tf`. This makes the region configurable.  
  region = var.aws_region
  // Authentication:
  // The AWS provider will automatically look for credentials in several places,
  // in a specific order. For GitHub Actions, we will configure credentials
  // as environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN (optional)).
  // For local development, it can use credentials from:
  // 1. Environment variables.
  // 2. Shared credentials file (~/.aws/credentials).
  // 3. IAM instance profile (if running Terraform on an EC2 instance).
  // We don't need to explicitly define access keys here, especially for production,
  // as it's more secure to manage them outside the Terraform code.
}
