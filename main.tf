# VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.cidr
tags = {
  Name = "my-vpc"
}
}

  
# Subnet 1
resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

# Subnet 2
resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

# Route Table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Route Table Association
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.rt.id
}

# Security Group
resource "aws_security_group" "webSg" {
  name   = "web"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance 1
resource "aws_instance" "webserver1" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.sub1.id
  vpc_security_group_ids = [aws_security_group.webSg.id]
  tags = {
    Name = "server-1"
  }
  user_data = file("userdata1.sh")
}

# EC2 Instance 2
resource "aws_instance" "webserver2" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.sub2.id
  vpc_security_group_ids = [aws_security_group.webSg.id]
  tags = {
    Name = "sever-2"
  }

  user_data = file("userdata.sh")
}

# Application Load Balancer
resource "aws_lb" "mylb" {
  name               = "my-loadbalancer"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.webSg.id]
  subnets         = [aws_subnet.sub1.id, aws_subnet.sub2.id]
}

# Target Group
resource "aws_lb_target_group" "tg" {
  name     = "myTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
    path = "/"
  }
}

# Attach Instance 1
resource "aws_lb_target_group_attachment" "tg1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver1.id
  port             = 80
}

# Attach Instance 2
resource "aws_lb_target_group_attachment" "tg2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver2.id
  port             = 80
}

# Listener
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.mylb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Output
output "loadbalancer_dns" {
  value = aws_lb.mylb.dns_name
}