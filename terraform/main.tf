# Creating the security groups that allow port 80 and port 22
resource "aws_security_group" "allowing_http" {
    name        = "allowing_http"
    description = "Allows http inbound traffic"

    ingress = [
        {
            description = "http"
            from_port   = 80
            to_port     = 80
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
            ipv6_cidr_blocks = []
            prefix_list_ids = []
            security_groups = []
            self = false
        },
        {
            description = "ssh"
            from_port   = 22
            to_port     = 22
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
            ipv6_cidr_blocks = []
            prefix_list_ids = []
            security_groups = []
            self = false
        }
    ]

    egress = [
        {
            description = "for all outgoing traffics"
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"]
            ipv6_cidr_blocks = ["::/0"]
            prefix_list_ids = []
            security_groups = []
            self = false
        }

    ]

    tags = {
        Name = "own_secure_group"
    }
}

# Enabling GuardDuty (IDS)
resource "aws_guardduty_detector" "test_IDS" {

}

# Configuring GuardDuty to monitor specific AWS accounts and regions
resource "aws_guardduty_organization_admin_account" "test_IDS" {
    admin_account_id = "123456789012"
}


# Creating an IAM role for Systems Manager
resource "aws_iam_role" "ssm_role" {
    name = "ssm_role"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "ssm.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

# Attaching AWS managed policy for SSM to the IAM role
resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    role       = aws_iam_role.ssm_role.name
}

# Creating an IAM user with necessary permissions
resource "aws_iam_user" "test_user" {
    name = "test_user"
}

# Attaching policies to the IAM user
resource "aws_iam_user_policy_attachment" "test_user_policy" {
    user       = aws_iam_user.test_user.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess" # It can be configured based on requirements
}

# Creating the instance
resource "aws_instance" "static_web_page" {
    count         = var.instance_count
    ami           = var.ami
    instance_type = var.instance_type
    availability_zone = var.availability_zone
    vpc_security_group_ids = [aws_security_group.allowing_http.id]
    iam_instance_profile   = aws_iam_role.ssm_role.name

    connection {
        type = "ssh"
        user = "ec2-user"
        private_key = tls_private_key.example_priv_key.private_key_pem
        host = aws_instance.static_web_page.public_ip
    }

    user_data = <<-EOF
                #!/bin/bash
                apt-get update
                apt-get install -y nginx
                echo '<!DOCTYPE html>
                        <html lang="en">
                        <head>
                            <meta charset="UTF-8">
                            <meta name="viewport" content="width=device-width, initial-scale=1.0">
                            <title>User Registration</title>
                            <style>
                                body {
                                    font-family: Arial, sans-serif;
                                    text-align: center;
                                    padding: 20px;
                                }
                                form {
                                    max-width: 400px;
                                    margin: 0 auto;
                                }
                                table {
                                    width: 100%;
                                    border-collapse: collapse;
                                    margin-top: 20px;
                                }
                                table, th, td {
                                    border: 1px solid #ddd;
                                }
                                th, td {
                                    padding: 10px;
                                    text-align: left;
                                }
                            </style>
                        </head>
                        <body>

                            <h1>User Registration</h1>

                            <form id="registrationForm">
                                <label for="name">Name:</label>
                                <input type="text" id="name" name="name" required><br>

                                <label for="email">Email:</label>
                                <input type="email" id="email" name="email" required><br>

                                <button type="button" onclick="registerUser()">Register</button>
                            </form>

                            <h2>Registered Users</h2>
                            <table id="userTable">
                                <thead>
                                    <tr>
                                        <th>Name</th>
                                        <th>Email</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <!-- Registered users will be displayed here -->
                                </tbody>
                            </table>

                            <script>
                                function registerUser() {
                                    // Get input values
                                    var name = document.getElementById('name').value;
                                    var email = document.getElementById('email').value;

                                    // Display registered user
                                    displayUser(name, email);

                                    // Clear form fields
                                    document.getElementById('name').value = '';
                                    document.getElementById('email').value = '';
                                }

                                function displayUser(name, email) {
                                    // Create a new row in the table
                                    var table = document.getElementById('userTable').getElementsByTagName('tbody')[0];
                                    var newRow = table.insertRow(table.rows.length);

                                    // Insert cells in the new row
                                    var cell1 = newRow.insertCell(0);
                                    var cell2 = newRow.insertCell(1);

                                    // Set the cell values
                                    cell1.innerHTML = name;
                                    cell2.innerHTML = email;
                                }
                            </script>

                        </body>
                        </html>' > /var/www/html/static_web_page.html
                systemctl start nginx
                EOF

    tags = {
        Name = "web-instance"
    }
}

#Creation of the EC2 key-pair

resource "tls_private_key" "example_priv_key" {
    algorithm = "RSA"
    rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
    key_name   = var.key_name
    public_key = tls_private_key.example_priv_key.public_key_openssh
}
