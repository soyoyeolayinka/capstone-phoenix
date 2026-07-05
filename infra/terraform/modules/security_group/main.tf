resource "aws_security_group" "nodes" {
  name        = "${var.project_name}-${var.environment}-nodes"
  description = "k3s node firewall"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from operator IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "Kubernetes API from operator IP only"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  dynamic "ingress" {
    for_each = var.allow_public_http_tls ? [80, 443] : []
    content {
      description = "Public HTTP/TLS ingress"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
    description = "k3s internal node traffic only"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.node_internal_cidrs
  }

  egress {
    description = "Outbound internet access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-nodes"
  }
}
