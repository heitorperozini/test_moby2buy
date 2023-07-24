################################################################################
# EC2
################################################################################
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}
resource "aws_instance" "web" {
  ami           = "data.aws_ami.amazon_linux_2.id"
  instance_type = "${var.ec2_instance_type}"
  subnet_id     = element(var.private_subnets, 0)
  key_name      = "${var.key_pair}"

  root_block_device {
    volume_size = 8

  }

  user_data = file("${path.module}/template/linux.sh")

  vpc_security_group_ids = [aws_security_group.web.id]

  iam_instance_profile = aws_iam_role.app_role.name

    tags = merge(
    { "Name" = "${var.name}-web-server" },
    var.tags,
  )
}

################################################################################
# SECURITY GROUP
################################################################################

resource "aws_security_group" "web" {
  description = "Giving aplication access"
  vpc_id      = "${var.vpc_id}"
  ingress {
    description = "Web"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer.id]
  }
  ingress {
    description     = "SSH"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${var.bastion_sg}"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  depends_on = [var.bastion_sg]
}

resource "aws_security_group" "load_balancer" {
  description = "Giving web access"
  vpc_id      = "${var.vpc_id}"
  ingress {
    description = "Web"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

################################################################################
# IAM
################################################################################

resource "aws_iam_role" "app_role" {
  name = "AppRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "s3_policy" {
  name        = "S3Policy"
  description = "Policy to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "${var.bucket_arn}"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "${var.bucket_arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
  policy_arn = aws_iam_policy.s3_policy.arn
  role       = aws_iam_role.app_role.name
}


resource "aws_iam_policy" "ecr_policy" {
  name        = "ECRPolicy"
  description = "Policy to ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
            "ecr:BatchCheckLayerAvailability",
            "ecr:BatchGetImage",
            "ecr:CompleteLayerUpload",
            "ecr:GetDownloadUrlForLayer",
            "ecr:InitiateLayerUpload",
            "ecr:PutImage",
            "ecr:UploadLayerPart"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_policy_attachment" {
  policy_arn = aws_iam_policy.ecr_policy.arn
  role       = aws_iam_role.app_role.name
}

output "iam_role_arn" {
  value = aws_iam_role.app_role.arn
}

################################################################################
# LOAD BALANCER
################################################################################

resource "aws_lb" "load_balancer" {
  name               = "AppLoadBalancer"
  subnets            = ["${var.subnets_id[0]}"]
  security_groups    = [aws_security_group.load_balancer.id]

    tags = merge(
    { "Name" = "AppLoadBalancer" },
    var.tags,
  )
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
  depends_on = [aws_lb_target_group.app]
}

resource "aws_lb_target_group" "app" {
  name        = "app-lb-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.web.id
  port             = 80
}

################################################################################
# SUPORT RESOURCES
################################################################################resource "aws_ecr_repository" "hello-world" {
resource "aws_ecr_repository" "test-mobi2buy" {
  name                 = "test-mobi2buy"
  image_tag_mutability = "MUTABLE"

  tags = var.tags
}