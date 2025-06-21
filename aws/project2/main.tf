# --------------------------------------------------------
# Provider Configuration
# --------------------------------------------------------
provider "aws" {
  region = "us-east-1"  # Set AWS region
}

# --------------------------------------------------------
# VPC and Subnet Configuration (Using Default VPC)
# --------------------------------------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

# --------------------------------------------------------
# Security Group for EC2 and RDS
# --------------------------------------------------------
resource "aws_security_group" "allow_http_postgres" {
  name        = "allow_http_postgres"
  description = "Allow inbound HTTP and PostgreSQL access"
  vpc_id      = data.aws_vpc.default.id

  # Allow HTTP (for web server)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow PostgreSQL access
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --------------------------------------------------------
# EC2 Web Instances Running Simple Python HTTP Server
# --------------------------------------------------------
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnet_ids.default.ids[0]
  vpc_security_group_ids = [aws_security_group.allow_http_postgres.id]

  # User data starts a basic HTTP server on port 8080
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World!" > index.html
              python3 -m http.server 8080 &
              EOF

  tags = {
    Name = "WebServer1"
  }
}

resource "aws_instance" "web2" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnet_ids.default.ids[1]
  vpc_security_group_ids = [aws_security_group.allow_http_postgres.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World_2!" > index.html
              python3 -m http.server 8080 &
              EOF

  tags = {
    Name = "WebServer2"
  }
}

# --------------------------------------------------------
# S3 Bucket with Versioning and Encryption
# --------------------------------------------------------
resource "aws_s3_bucket" "bucket" {
  bucket         = "my-unique-bucket-name-12345"  # Must be globally unique
  force_destroy  = true  # Deletes even if bucket has objects
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"  # Uses AES encryption by default
    }
  }
}

# --------------------------------------------------------
# Application Load Balancer Configuration
# --------------------------------------------------------
resource "aws_lb" "app" {
  name               = "app-lb"
  internal           = false  # Public-facing ALB
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default.ids
  security_groups    = [aws_security_group.allow_http_postgres.id]
}

# Target group to register EC2 instances
resource "aws_lb_target_group" "instances" {
  name     = "target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  # Health check config
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

# Attach EC2 instance 1 to ALB target group
resource "aws_lb_target_group_attachment" "attach_web1" {
  target_group_arn = aws_lb_target_group.instances.arn
  target_id        = aws_instance.web.id
  port             = 8080
}

# Attach EC2 instance 2 to ALB target group
resource "aws_lb_target_group_attachment" "attach_web2" {
  target_group_arn = aws_lb_target_group.instances.arn
  target_id        = aws_instance.web2.id
  port             = 8080
}

# Listener to forward HTTP traffic on port 80 to target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.instances.arn
  }
}

# --------------------------------------------------------
# Amazon RDS - PostgreSQL Instance
# --------------------------------------------------------

# RDS subnet group to place DB in subnets
resource "aws_db_subnet_group" "default" {
  name       = "rds-subnet-group"
  subnet_ids = data.aws_subnet_ids.default.ids
}

# Basic PostgreSQL instance
resource "aws_db_instance" "postgres" {
  identifier              = "my-postgres-db"
  engine                  = "postgres"
  engine_version          = "14.10"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  username                = "adminuser"
  password                = "adminpassword123"  # Don't hardcode in production
  db_name                 = "appdb"
  skip_final_snapshot     = true
  publicly_accessible     = true
  vpc_security_group_ids  = [aws_security_group.allow_http_postgres.id]
  db_subnet_group_name    = aws_db_subnet_group.default.name

  tags = {
    Name = "PostgresDB"
  }
}

# --------------------------------------------------------
# Outputs
# --------------------------------------------------------
output "alb_dns" {
  description = "Public DNS of the ALB"
  value       = aws_lb.app.dns_name
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres.endpoint
}
