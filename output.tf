// outputs.tf

// This output will display the public IP address of the EC2 web server instance.
// You can use this IP address to access your Nginx web server in a browser
// or for direct SSH access (if configured and needed).
output "server_public_ip" {
  description = "Public IP address of the EC2 web server."
  // The value is derived from the `aws_instance` resource named "web_server"
  // (defined in main.tf) and its `public_ip` attribute.
  value = aws_instance.web_server.public_ip
}

// This output will display the public DNS name of the EC2 web server instance.
// This DNS name can also be used to access your Nginx web server in a browser.
output "server_public_dns" {
  description = "Public DNS name of the EC2 web server."
  // The value is derived from the `aws_instance` resource named "web_server"
  // and its `public_dns` attribute.
  value = aws_instance.web_server.public_dns
}

// This output will display the ID of the EC2 instance.
// This can be useful for identifying the instance in the AWS console or for use with AWS CLI commands.
output "server_instance_id" {
  description = "ID of the EC2 web server instance."
  value       = aws_instance.web_server.id
}

// Note on SSM Session Manager Access:
// While we output the public IP and DNS, remember that for secure access,
// AWS Systems Manager Session Manager is the recommended approach.
// To connect via Session Manager using the AWS CLI, you would typically use the Instance ID:
// `aws ssm start-session --target <INSTANCE_ID_FROM_ABOVE_OUTPUT>`
// Or connect via the AWS Management Console using the instance ID.
