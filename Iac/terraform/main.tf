###################
# VPC Configuration
####################
# Create a VPC
resource "aws_vpc" "vpc" {
  tags = {
    "Name" = "rantzapp"
  }
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Create an internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "rantzapp-igw"
  }
}


# Get available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Create public subnets in only 2 availability zones
resource "aws_subnet" "public_subnets" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "rantzapp-public-${data.aws_availability_zones.available.names[count.index]}"
  }
}

# Create public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "rantzapp-public-rt"
  }
}

# Add public route to internet gateway
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate the route table with all public subnets
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public.id
}

###################
# Security Groups
###################
# Security group for EC2 instances
resource "aws_security_group" "ec2_sg" {
  name        = "rantzapp-ec2-sg"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes API Server
  ingress {
    description = "Kubernetes API Server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubelet API
  ingress {
    description = "Kubelet API"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kube Scheduler
  ingress {
    description = "Kube Scheduler"
    from_port   = 10251
    to_port     = 10251
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kube Controller Manager
  ingress {
    description = "Kube Controller Manager"
    from_port   = 10252
    to_port     = 10252
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # etcd client communication
  ingress {
    description = "etcd client communication"
    from_port   = 2379
    to_port     = 2379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # etcd peer communication
  ingress {
    description = "etcd peer communication"
    from_port   = 2380
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Canal/Flannel VXLAN overlay networking
  ingress {
    description = "Canal/Flannel VXLAN overlay networking"
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Canal/Flannel health check
  ingress {
    description = "Canal/Flannel health check"
    from_port   = 9099
    to_port     = 9099
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NodePort Services
  ingress {
    description = "NodePort Services"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rantzapp-ec2-sg"
  }
}

###################
# IAM Roles
###################
# Create IAM role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "rantzapp-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach policies to EC2 role
resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Additional policies for RKE
resource "aws_iam_role_policy_attachment" "ec2_ecr_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ec2_eks_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Create instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "rantzapp-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

###################
# Launch Template
###################
# Get latest openSUSE Leap 15.6 AMI
data "aws_ami" "opensuse_leap" {
  most_recent = true
  owners      = ["679593333241"]  # openSUSE official account

  filter {
    name   = "name"
    values = ["openSUSE-Leap-15.6-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Create launch template
resource "aws_launch_template" "main" {
  name_prefix   = "rantzapp-lt"
  image_id      = data.aws_ami.opensuse_leap.id
  instance_type = "t3.large"
  key_name      = aws_key_pair.main.key_name
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups            = [aws_security_group.ec2_sg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              
              # Update system
              zypper refresh
              zypper update -y
              
              # Install Docker
              zypper install -y docker

              #To avoid using ingore docker true, but doesnt always work
              #----------------------------------------------
              #zypper remove -y docker docker-compose
              # Add Docker repository for supported version
              #zypper addrepo https://download.docker.com/linux/opensuse/docker-ce.repo
              # Install specific Docker version (20.10.x is supported)
              #zypper install -y docker-ce-20.10.24 docker-ce-cli-20.10.24 containerd.io
              #-----------------------------------------------

              # Start and enable Docker
              systemctl start docker
              systemctl enable docker
              
              # Add user to docker group
              usermod -aG docker ec2-user
              
              # Install required packages
              zypper install -y curl wget git
              
              # Download and install RKE binary
              curl -LO https://github.com/rancher/rke/releases/latest/download/rke_linux-amd64
              chmod +x rke_linux-amd64
              mv rke_linux-amd64 /usr/local/bin/rke
              
              # Create RKE configuration directory
              mkdir -p /opt/rke
              
              # Install kubectl
              curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
              chmod +x kubectl
              mv kubectl /usr/local/bin/
              
              # Configure Docker daemon for RKE
              cat > /etc/docker/daemon.json << 'DOCKEREOF'
              {
                "log-driver": "json-file",
                "log-opts": {
                  "max-size": "10m",
                  "max-file": "3"
                }
              }
              DOCKEREOF
              
              # Restart Docker with new configuration
              systemctl restart docker
              
              # Set proper permissions
              chown -R ec2-user:ec2-user /opt/rke
              
              # Create a simple web server for health checks
              zypper install -y apache2
              systemctl start apache2
              systemctl enable apache2
              echo "<h1>RKE Ready - RantzApp Cluster</h1>" > /srv/www/htdocs/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "rantzapp-instance"
    }
  }
}

###################
# Auto Scaling Group
###################
# Create Auto Scaling Group
resource "aws_autoscaling_group" "main" {
  name                = "rantzapp-asg"
  desired_capacity    = 2
  max_size            = 3
  min_size            = 2
  target_group_arns   = [aws_lb_target_group.main.arn]
  vpc_zone_identifier = aws_subnet.public_subnets[*].id

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "rantzapp-asg"
    propagate_at_launch = true
  }
}

###################
# Application Load Balancer
###################
# Create ALB
resource "aws_lb" "main" {
  name               = "rantzapp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public_subnets[*].id

  tags = {
    Name = "rantzapp-alb"
  }
}

# Security group for ALB
resource "aws_security_group" "alb_sg" {
  name        = "rantzapp-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rantzapp-alb-sg"
  }
}

# Create target group
resource "aws_lb_target_group" "main" {
  name     = "rantzapp-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}

# Create listener
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# Create a key pair
resource "aws_key_pair" "main" {
  key_name   = "ec2-kp"
  public_key = file("${path.module}/ec2-kp.pub")  # You'll need the public key
}
