# AWS EC2 IaC with Terraform and GitHub Actions

## Project goal

The goal here is to build an automation that can deploy EC2 Server instance on AWS, running Nginx and mySQL on it.
All by Terraform and GitHub Action as code.

*(Although the code works in a prod  environment, the main goal of this project is DevOps automation learning.)*

### Extended with Destroy Action (Manual run only)

## How it works

This project leverages GitHub Actions for fully automated infrastructure deployment and management using Terraform. When changes to the Terraform code are pushed to the `main` branch, or a pull request targeting `main` is created, a predefined GitHub Actions workflow is automatically triggered. This workflow securely authenticates with AWS using credentials stored as GitHub Secrets. It then executes a series of Terraform commands: `init` to prepare the environment and backend, `validate` to check code syntax, and `plan` to preview changes. For pushes to `main`, the workflow proceeds to `apply` these changes, provisioning or updating the AWS infrastructure (VPC, EC2 server with Nginx/MySQL, SSM access) as defined in the code, ensuring a consistent and version-controlled environment.

## Amazon AWS, preparation

**Prerequisites and preparation steps:**
- [ ] Register AWS free tier account
- [ ] Setup SSH key pair for  local-to-EC2 SSH login (though we use SSM in this project, so optional)
- [ ] Create S3 bucket for Terraform State file storage
- [ ] Create DynamoDB table for Terraform State locking
- [ ] Create IAM technical user, and setup rights (policy) for GitHub Actions

### EC2 SSH key-pairs setup

**Purpose:** 
SSH login from localhost to EC2 Instance after server provision. (not needed if use only SSM access)

**How to create:**
AWS Console > EC2 Service > Network & Security > Key Pairs > Create

Name: `london-srv1-admin-key` *(name can be anything)*
type: `RSA`
key: `.pem` (for OpenSSH)

*(store private key in a secure place eg.: .ssh folder)*
### S3 Bucket setup for Terraform State file storage

**Purpose:** 
store state file `terraform.tfstate` in a remote location.

**How to create:**
AWS Console > S3 Service > Create Bucket

Name: `tp-tfstate-london-bucket1`
Object ownership: `ACLs disabled (recommended)`
`Block all public access`
Bucket versioning: `Enable`
Default Encryption: `Server-side encryption with Amazon S3 managed keys (SSE-S3)`
Bucket Key: `Enabled`

### Create a DynamoDB Table for Terraform State Locking

**Purpose:**
Lock state file avoid paralell updating.

**How to create:**
AWS Console > DynamoDB service > create table

name: `tp-tfstatelocks-1`
Partition key: `LockID` *(case sensitive!)* , String
table settings: `default`

### Create IAM User, role Policy and access key for GitHub Actions

**Purpose**:
GitHub (Actions) will perform tasks programatically in AWS environment, so we need to create a technical user with the neccessary privileges to achive this.

**How to create:**
AWS Console: IAM > Users > create user
username: `tp-github-actions-tuser1`
*(Do NOT select "Provide user access to the AWS Management Console")*

**Permission options**:
Permissions options:  "Attach policies directly" > Create policy > JSON: *(below)*
Policy name: `TP-TfEC2VPCManagementPolicy-1`

TEMPLATE: *(templates/aws-iam-permission-policy.json)*
*(Make sure replacing "placeholder" values in the file)*

Double check if the user created.

#### Create Access Key for the user

Create an access key for the user. It will be needed for GitHub to access the user. 
Credentials will need to be stored in GitHub Secrets.

### Github Repository Secrets

Following values must be stored in GitHub Secrets:

`AWS_ACCESS_KEY_ID`: Access Key ID for the GitHub Actions IAM user.
`AWS_SECRET_ACCESS_KEY`: Secret Access Key for the GitHub Actions IAM user.
`TF_VAR_ami_id`: AMI ID for the EC2 instance.
`TF_VAR_key_name`: Name of the EC2 Key Pair.

### GitHub Actions code

GitHub Actions code is in Workflow File:
`.github/workflows/terraform_deploy.yml`

### Terraform code files and user_data.sh script file

* **`provider.tf`:**
    * Declares and configures the `hashicorp/aws` provider, setting the region to `eu-west-2` via `var.aws_region`.
* **`variables.tf`:**
    * Defines input variables for:
        * `aws_region` 
        * `vpc_cidr`
        * `subnet_cidr` 
        * `instance_type`
        * `ami_id` 
        * `key_name` 

* **`main.tf`:**
    * **Networking:** Defines `aws_vpc`, `aws_subnet`, `aws_internet_gateway`, `aws_route_table`, `aws_route_table_association`.

    * **IAM for SSM:** Defines `aws_iam_role` (with `AmazonSSMManagedInstanceCore` policy) and `aws_iam_instance_profile` for EC2 instance.

    * **Security Group (`aws_security_group`):** Allows inbound HTTP (port 80) from anywhere. Outbound is all allowed. **No inbound SSH (port 22) rule** due to primary access via SSM Session Manager.

    * **EC2 Instance (`aws_instance`):** Deploys the server, associates the IAM instance profile (for SSM), key pair, and executes `user_data.sh`.

* **`user_data.sh`:**
    * Shell script run on EC2 instance boot.
    * Updates system packages.
    * Installs and enables Nginx.
    * Installs and enables MySQL Server.
    * Creates a basic `index.html` for Nginx.

* **`outputs.tf`:**
    * Defines outputs for `server_public_ip`, `server_public_dns`, and `server_instance_id`.

* **`backend.tf`:**
    * Configures the S3 remote backend for Terraform state.
    * Specifies the `bucket` name, `key` (path to state file), `region`, and `dynamodb_table` name (for state locking).
    * Encryption (`encrypt = true`) enabled.


### GitHub Repo file structure

```
our-git-repository-folder/ 
├── .git/ <-- This is your hidden Git directory 
├── .github/ <-- Create this folder 
│   └── workflows/ <-- Create this folder inside .github 
│       └── terraform_deploy.yml <-- Your GitHub Actions workflow file goes here 
|       └── terraform_destroy.yml <-- Your GitHub Actions destroy workflow file goes here 
├── provider.tf <-- Terraform file 
├── variables.tf <-- Terraform file 
├── main.tf <-- Terraform file 
├── user_data.sh <-- Your shell script for EC2 setup 
├── outputs.tf <-- Terraform file 
└── backend.tf <-- Terraform file
```

## Destroy the infrastructure

To destroy the infrastructure, you cam amnually run Destroy workflow in GitHub Actions.

