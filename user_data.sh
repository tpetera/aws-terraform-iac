#!/bin/bash
# user_data.sh
# This script is executed by cloud-init when the EC2 instance first boots.
# It's used to install and configure software on the instance.

# Exit immediately if a command exits with a non-zero status.
set -e

# Optional: Print commands and their arguments as they are executed. Useful for debugging.
# set -x

# --- Update System Packages ---
# It's good practice to update the package lists and upgrade existing packages first.
echo "Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y
echo "System packages updated."

# --- Install Nginx ---
# Nginx is a popular high-performance web server.
echo "Installing Nginx..."
sudo apt-get install -y nginx
# Start Nginx service
sudo systemctl start nginx
# Enable Nginx to start on boot
sudo systemctl enable nginx
echo "Nginx installed and started."

# --- Install MySQL Server ---
# MySQL is a widely used open-source relational database management system.
echo "Installing MySQL Server..."
# Set DEBIAN_FRONTEND to noninteractive to prevent prompts during installation,
# which would cause cloud-init to hang.
export DEBIAN_FRONTEND=noninteractive
# For Ubuntu 22.04, mysql-server package should work.
sudo apt-get install -y mysql-server

# Start MySQL service
sudo systemctl start mysql
# Enable MySQL to start on boot
sudo systemctl enable mysql
echo "MySQL Server installed and started."

# SECURITY NOTE for MySQL:
# The default MySQL installation is not secure for production.
# For a production environment, you would typically:
# 1. Run `sudo mysql_secure_installation` (interactively or scripted with expect).
# 2. Set a strong root password.
# 3. Remove anonymous users.
# 4. Disallow root login remotely.
# 5. Remove the test database.
# These steps are beyond the scope of a simple user_data script for initial setup
# and often handled by configuration management tools (Ansible, Chef, Puppet)
# or more sophisticated bootstrap scripts, potentially using secrets management
# for passwords.

# --- Create a Simple Test Page for Nginx ---
echo "Creating a test HTML page for Nginx..."
# This creates a basic index.html file in the default Nginx web root.
# You should see this page when you access the public IP of your EC2 instance in a browser.
sudo bash -c 'cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hello from Terraform!</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f4f4f4; color: #333; }
        .container { background-color: #fff; padding: 20px; border-radius: 8px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        h1 { color: #007bff; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Hello from your Web Server!</h1>
        <p>This page is served by Nginx, installed on an EC2 instance managed by Terraform.</p>
        <p>MySQL Server has also been installed.</p>
        <p>Access to this instance is primarily managed via AWS Systems Manager Session Manager.</p>
    </div>
</body>
</html>
EOF'
echo "Test HTML page created."

# --- Final Steps ---
echo "User data script finished successfully."

# Note on SSM Agent:
# Most modern Ubuntu AMIs (and Amazon Linux AMIs) come with the SSM Agent pre-installed
# and configured to start automatically. If you were using a very minimal OS or a custom AMI
# without it, you might need to add steps here to install and start the SSM Agent.
# For standard Ubuntu Server AMIs from AWS, this is usually not necessary.

