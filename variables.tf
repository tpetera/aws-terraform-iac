// variables.tf

// This variable defines the AWS region where the resources will be deployed.
// It's used by the provider configuration in `provider.tf`.
variable "aws_region" {
  description = "AWS region for deployment."
  type        = string
  default     = "eu-west-2" // London
}

// This variable defines the CIDR (Classless Inter-Domain Routing) block for the VPC.
// A CIDR block is a range of IP addresses. This will be the main IP address range
// for your private network in AWS.
variable "vpc_cidr" {
  description = "CIDR block for the Virtual Private Cloud (VPC)."
  type        = string
  default     = "10.0.0.0/16" // A common private IP range.
}

// This variable defines the CIDR block for the public subnet within the VPC.
// Subnets are subdivisions of your VPC. A public subnet has a route to the internet.
variable "subnet_cidr" {
  description = "CIDR block for the public subnet within the VPC."
  type        = string
  default     = "10.0.1.0/24" // A smaller range within the VPC's 10.0.0.0/16 range.
}

// This variable defines the type (size, CPU, memory) of the EC2 instance to be launched.
// For production, you'd choose based on workload. For testing, a Free Tier eligible
// instance is recommended to avoid costs.
variable "instance_type" {
  description = "EC2 instance type (e.g., t2.micro, t3.micro)."
  type        = string
  default     = "t2.micro" // Check AWS Free Tier eligibility for t2.micro in eu-west-2.
                           // t3.micro might also be an option if t2 is not available or preferred.
}

// This variable holds the Amazon Machine Image (AMI) ID for the EC2 instance.
// AMIs are templates that contain the software configuration (OS, application server, etc.).
// AMI IDs are REGION-SPECIFIC.
variable "ami_id" {
  description = "AMI ID for the EC2 instance (Ubuntu 24.04 LTS in eu-west-2)."
  type        = string  
  default     = "ami-0a94c8e4ca2674d5a"  // "Ubuntu Server 24.04 LTS"
}

// This variable specifies the name of the EC2 Key Pair to associate with the instance.
// This key pair is used for SSH access. It must already exist in your AWS account
// in the specified region (eu-west-2).
variable "key_name" {
  description = "Name of the EC2 Key Pair for SSH access (must exist in AWS in the selected region)."
  type        = string  
  default     = "london-srv1-admin-key"
}