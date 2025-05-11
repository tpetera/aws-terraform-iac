// backend.tf

// This block configures the remote backend where Terraform will store its state file.
// Using a remote backend is crucial for collaboration, CI/CD automation, and state protection.
terraform {
  backend "s3" {
    // S3 Bucket: The name of the S3 bucket you created to store the Terraform state file.
    // IMPORTANT: Replace "YOUR-UNIQUE-TERRAFORM-STATE-BUCKET-NAME-PROD-EU-WEST-2"
    // with the actual, globally unique name of the S3 bucket you created in the AWS preparation phase.
    bucket = "tp-tfstate-london-bucket1"

    // Key: The path and filename for the state file within the S3 bucket.
    // It's good practice to organize state files, e.g., by project/environment.
    key = "global/s3/p1/TPDevOpsTask1/terraform.tfstate" // you can customize this.

    // Region: The AWS region where your S3 bucket and DynamoDB table are located.
    // This should match the region of your S3 bucket.
    region = "eu-west-2" // London

    // DynamoDB Table: The name of the DynamoDB table you created for state locking.
    // This table prevents concurrent state modifications.
    // IMPORTANT: Replace "terraform-prod-state-locks"
    // with the actual name of the DynamoDB table you created.
    dynamodb_table = "tp-tfstatelocks-1"

    // Encrypt: Enables server-side encryption of the state file in S3.
    // This is highly recommended for protecting sensitive information that might be in the state file.
    // Assumes your S3 bucket has default encryption enabled (which we configured).
    encrypt = true
  }
}
