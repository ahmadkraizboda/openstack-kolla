terraform {
  backend "s3" {
    bucket         = var.tf_state_bucket
    key            = "prod/openstack/terraform.tfstate"
    region         = var.aws_region
  }
}

provider "aws" {
  region = var.aws_region
}

# Create VPC
resource "aws_vpc" "openstack" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "openstack-vpc" }
}

resource "aws_subnet" "controller_subnet" {
  vpc_id            = aws_vpc.openstack.id
  cidr_block        = "10.0.1.0/24"
  tags = { Name = "controller-subnet" }
}

resource "aws_subnet" "compute_subnet" {
  vpc_id            = aws_vpc.openstack.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = { Name = "compute-subnet" }
}

resource "aws_subnet" "storage_subnet" {
  vpc_id            = aws_vpc.openstack.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1c"
  tags = { Name = "storage-subnet" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.openstack.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.openstack.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "controller" {
  subnet_id      = aws_subnet.controller_subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "compute" {
  subnet_id      = aws_subnet.compute_subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "storage" {
  subnet_id      = aws_subnet.storage_subnet.id
  route_table_id = aws_route_table.public.id
}


# Security group
resource "aws_security_group" "openstack_sg" {
  name   = "openstack-sg"
  vpc_id = aws_vpc.openstack.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = [80, 443, 3306, 5000, 5672, 8774]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instances (Controllers, Compute, Storage)

resource "aws_instance" "controller" {
  count                  = 3
  ami                    = var.controller_ami
  instance_type          = var.controller_type
  subnet_id              = aws_subnet.controller_subnet.id
  availability_zone      = "us-east-1a"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.openstack_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "controller-${count.index + 1}"
  }
}

resource "aws_instance" "compute" {
  count                  = 3
  ami                    = var.compute_ami
  instance_type          = var.compute_type
  subnet_id              = aws_subnet.compute_subnet.id
  availability_zone      = "us-east-1b"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.openstack_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "compute-${count.index + 1}"
  }
}

resource "aws_instance" "storage" {
  count                  = 3
  ami                    = var.storage_ami
  instance_type          = var.storage_type
  subnet_id              = aws_subnet.storage_subnet.id
  availability_zone      = "us-east-1c"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.openstack_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "storage-${count.index + 1}"
  }
}

# Generate Ansible inventory after apply
resource "null_resource" "run_ansible" {
  provisioner "local-exec" {
    command = <<EOT
#!/bin/bash
cat > generated_inventory.ini <<EOF
[control]
${join("\n", formatlist("controller%d ansible_host=%s", range(1, 4), aws_instance.controller[*].public_ip))}

[compute]
${join("\n", formatlist("compute%d ansible_host=%s", range(1, 4), aws_instance.compute[*].public_ip))}

[storage]
${join("\n", formatlist("storage%d ansible_host=%s", range(1, 4), aws_instance.storage[*].public_ip))}

[swift-proxy]
${join("\n", formatlist("controller%d ansible_host=%s", range(1, 4), aws_instance.controller[*].public_ip))}

[swift-account]
${join("\n", formatlist("storage%d ansible_host=%s", range(1, 4), aws_instance.storage[*].public_ip))}

[swift-container]
${join("\n", formatlist("storage%d ansible_host=%s", range(1, 4), aws_instance.storage[*].public_ip))}

[swift-object]
${join("\n", formatlist("storage%d ansible_host=%s", range(1, 4), aws_instance.storage[*].public_ip))}

EOF

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i generated_inventory.ini -u ubuntu --private-key ~/.ssh/my-aws-key.pem ansible/deploy.yml
EOT
  }
  depends_on = [aws_instance.controller, aws_instance.compute, aws_instance.storage]
}
