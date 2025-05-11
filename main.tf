// main.tf

// --- Networking ---
// This section defines the basic network infrastructure for your EC2 instance.

// 1. Virtual Private Cloud (VPC)
// A VPC is your own isolated section of the AWS cloud.
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr // Uses the CIDR block defined in variables.tf (e.g., "10.0.0.0/16")

  // Enables DNS support within your VPC, allowing instances to resolve DNS names.
  enable_dns_support   = true
  // Enables DNS hostnames, so instances launched into the VPC get DNS hostnames.
  enable_dns_hostnames = true

  tags = {
    Name        = "TP-VPC-P1" // Naming tag for easy identification in the AWS console
    Environment = "Production"
    Project     = "TPDevOpsTask1"
  }
}

// 2. Availability Zones Data Source
// This data source retrieves information about available Availability Zones (AZs) in the current region.
// We'll use this to place our subnet in one of the available AZs.
data "aws_availability_zones" "available" {
  state = "available" // Filters for AZs that are currently operational
}

// 3. Public Subnet
// A subnet is a range of IP addresses in your VPC. A public subnet has a route to the internet.
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id // Associates this subnet with the VPC created above
  cidr_block              = var.subnet_cidr     // Uses the CIDR block for the subnet (e.g., "10.0.1.0/24")
  map_public_ip_on_launch = true                // Instances launched into this subnet will automatically get a public IP address.
                                                // This is needed for the instance to be reachable from the internet (e.g., for Nginx).
  availability_zone       = data.aws_availability_zones.available.names[0] // Places the subnet in the first available AZ.
                                                                         // For production, you might want to create subnets in multiple AZs for high availability.
  tags = {
    Name        = "TP-PublicSubnet-P1"
    Environment = "Production"
    Project     = "TPDevOpsTask1"
  }
}

// 4. Internet Gateway (IGW)
// An IGW allows communication between instances in your VPC and the internet.
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id // Attaches the IGW to our VPC

  tags = {
    Name        = "TP-IGW-P1"
    Environment = "Production"
    Project     = "TPDevOpsTask1"
  }
}

// 5. Route Table
// A route table contains a set of rules, called routes, that determine where network traffic is directed.
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id // Associates this route table with our VPC

  // This route directs all outbound traffic (0.0.0.0/0) to the Internet Gateway.
  // This makes the subnet associated with this route table a "public" subnet.
  route {
    cidr_block = "0.0.0.0/0"         // Represents all IP addresses (the internet)
    gateway_id = aws_internet_gateway.main_igw.id // Traffic goes through our IGW
  }

  tags = {
    Name        = "TP-PublicRouteTable-P1"
    Environment = "Production"
    Project     = "TPDevOpsTask1"
  }
}

// 6. Route Table Association
// This associates our public subnet with the public route table.
resource "aws_route_table_association" "public_subnet_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

// --- IAM for EC2 and SSM Session Manager ---
// This section defines the IAM Role and Instance Profile that will be attached to the EC2 instance.
// This role grants the EC2 instance permissions to interact with AWS Systems Manager (SSM)
// for features like Session Manager, without needing to manage SSH keys for access.

// 1. IAM Role for EC2
// This role will be assumed by the EC2 instance.
resource "aws_iam_role" "ec2_ssm_role" {
  name = "EC2-SSM-Access-Role-P1"

  // The assume_role_policy defines which entities can assume this role.
  // In this case, we allow the EC2 service to assume this role.
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "EC2-SSM-Access-Role-P1"
    Environment = "Production"
    Project     = "TPDevOpsTask1"
  }
}

// 2. Attach SSM Policy to the Role
// This attaches the AWS managed policy `AmazonSSMManagedInstanceCore` to the role created above.
// This policy grants the necessary permissions for the SSM Agent on the EC2 instance
// to communicate with the Systems Manager service.
resource "aws_iam_role_policy_attachment" "ssm_policy_attach" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

// 3. IAM Instance Profile
// An instance profile is a container for an IAM role that you can use to pass role
// information to an EC2 instance when the instance starts.
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2-SSM-Instance-Profile-P1"
  role = aws_iam_role.ec2_ssm_role.name // Associates the role with this instance profile

  tags = {
    Name        = "EC2-SSM-Instance-Profile-P1"
    Environment = "Production"
    Project     = "TPDevOpsTask1"
  }
}

// --- Security Group ---
// A security group acts as a virtual firewall for your instance to control inbound and outbound traffic.
resource "aws_security_group" "web_server_sg" {
  name        = "web-server-sg-prod"
  description = "Allow HTTP inbound traffic and all outbound. Access via SSM Session Manager."
  vpc_id      = aws_vpc.main_vpc.id // Associates this security group with our VPC

  // Inbound Rules:
  // We allow HTTP traffic on port 80 from anywhere for the Nginx web server.
  ingress {
    description      = "HTTP from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] // Allows HTTP traffic from any IP address
    ipv6_cidr_blocks = ["::/0"]      // Allows HTTP traffic from any IPv6 address
  }

  // NOTE on SSH: Since we are primarily using AWS Systems Manager Session Manager for access,
  // we do NOT need to open port 22 (SSH) to the internet or specific IPs.
  // This significantly enhances security by reducing the attack surface.
  // If direct SSH was required as a fallback, an ingress rule for port 22 would be added here,
  // ideally restricted to a specific IP or Bastion Host.

  // Outbound Rules:
  // Allows all outbound traffic. This is generally acceptable for many use cases,
  // as it allows the instance to download updates, connect to AWS services (including SSM), etc.
  // For stricter production environments, you might restrict outbound traffic to specific ports/destinations.
  egress {
    from_port        = 0          // All ports
    to_port          = 0          // All ports
    protocol         = "-1"       // All protocols
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "TP-WebServerSG-P1"
    Environment = "Production"
    Project     = "TPDevOpsTask1"
  }
}

// --- Compute (EC2 Instance) ---
// This section defines the EC2 virtual server.

// Data source to read the content of the user_data.sh script.
// This allows us to keep the script in a separate file for better organization.
data "local_file" "user_data_script" {
  filename = "${path.module}/user_data.sh" // Assumes user_data.sh is in the same directory
}

// EC2 Instance Resource
resource "aws_instance" "web_server" {
  ami           = var.ami_id      // Amazon Machine Image ID (from variables.tf)
  instance_type = var.instance_type // Instance type (e.g., t2.micro, from variables.tf)

  // Associates the EC2 Key Pair. Even with SSM, having a key pair can be useful for
  // certain SSM functionalities or as an emergency fallback (if SSH access is ever enabled).
  key_name      = var.key_name

  subnet_id                   = aws_subnet.public_subnet.id // Launches the instance into our public subnet
  vpc_security_group_ids      = [aws_security_group.web_server_sg.id] // Attaches our security group
  associate_public_ip_address = true // Ensures the instance gets a public IP (redundant if subnet's map_public_ip_on_launch is true, but good for clarity)

  // Attach the IAM instance profile created earlier.
  // This gives the EC2 instance the necessary permissions for SSM Session Manager.
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  // User data script to run on instance launch (e.g., to install Nginx and MySQL).
  // The content is read from the user_data.sh file.
  user_data = data.local_file.user_data_script.content

  user_data_replace_on_change = true
  // user_data_replace_on_change = false: By default, if user_data changes, Terraform might want to
  // replace (destroy and recreate) the instance. Setting this to false can prevent that if
  // you only want user_data to run on first boot. However, for immutable infrastructure,
  // replacing the instance on user_data change is often the desired behavior.
  // For this project, let's assume we want changes to user_data to potentially trigger a replacement
  // to ensure the new script runs. So we can omit this or set it to true (which is the default if not specified for some changes).
  // If you want to ensure it runs only once and never causes replacement, you might need other strategies.

  tags = {
    Name        = "TP-Server-P1"
    Environment = "Production"
    Project     = "TPDevOpsTask1"
  }
}
