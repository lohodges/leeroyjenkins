############################################
# Locals (naming convention: Echobase-*)
############################################
locals {
  name_prefix = var.project_name

  # TODO: Students should lock this down after apply using the real secret ARN from outputs/state
  echobase_secret_arn_guess = "arn:aws:secretsmanager:${data.aws_region.echobase_region01.region}:${data.aws_caller_identity.echobase_self01.account_id}:secret:${local.name_prefix}/rds/mysql*"

  # Explanation: This is the roar address — where the galaxy finds your app.
  echobase_fqdn = var.domain_name

  # Explanation: echobase needs a home planet—Route53 hosted zone is your DNS territory.
  echobase_zone_name = var.domain_name

  # Explanation: Use either Terraform-managed zone or a pre-existing zone ID (students choose their destiny).
  echobase_zone_id = var.manage_route53_in_terraform #? aws_route53_zone.echobase_zone01[0].zone_id : var.route53_hosted_zone_id

  # Explanation: This is the app address that will growl at the galaxy (app.echobase.click).
  echobase_app_fqdn = "${var.app_subdomain}.${var.domain_name}"
}

# Explanation: Chewbacca wants to know “who am I in this galaxy?” so ARNs can be scoped properly.
data "aws_caller_identity" "echobase_self01" {}

# Explanation: Region matters—hyperspace lanes change per sector.
data "aws_region" "echobase_region01" {}
# ^^^ added by Lonnie Hodges on 2026-01-17


############################################
# VPC + Internet Gateway
############################################

# Explanation: Echobase needs a hyperlane—this VPC is the Millennium Falcon’s flight corridor.
resource "aws_vpc" "echobase_vpc01" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc01"
  }
}

# Explanation: Even Wookiees need to reach the wider galaxy—IGW is your door to the public internet.
resource "aws_internet_gateway" "echobase_igw01" {
  vpc_id = aws_vpc.echobase_vpc01.id

  tags = {
    Name = "${local.name_prefix}-igw01"
  }
}

############################################
# Subnets (Public + Private)
############################################

# Explanation: Public subnets are like docking bays—ships can land directly from space (internet).
resource "aws_subnet" "echobase_public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.echobase_vpc01.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-subnet0${count.index + 1}"
  }
}

# Explanation: Private subnets are the hidden Rebel base—no direct access from the internet.
resource "aws_subnet" "echobase_private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.echobase_vpc01.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${local.name_prefix}-private-subnet0${count.index + 1}"
  }
}

############################################
# NAT Gateway + EIP
############################################

# # Explanation: Echobase wants the private base to call home—EIP gives the NAT a stable “holonet address.”
# resource "aws_eip" "echobase_nat_eip01" {
#   domain = "vpc"

#   tags = {
#     Name = "${local.name_prefix}-nat-eip01"
#   }
# }

# # Explanation: NAT is Echobase’s smuggler tunnel—private subnets can reach out without being seen.
# resource "aws_nat_gateway" "echobase_nat01" {
#   allocation_id = aws_eip.echobase_nat_eip01.id
#   subnet_id     = aws_subnet.echobase_public_subnets[0].id # NAT in a public subnet

#   tags = {
#     Name = "${local.name_prefix}-nat01"
#   }

#   depends_on = [aws_internet_gateway.echobase_igw01]
# }

############################################
# Routing (Public + Private Route Tables)
############################################

# Explanation: Public route table = “open lanes” to the galaxy via IGW.
resource "aws_route_table" "echobase_public_rt01" {
  vpc_id = aws_vpc.echobase_vpc01.id

  tags = {
    Name = "${local.name_prefix}-public-rt01"
  }
}

# Explanation: This route is the Kessel Run—0.0.0.0/0 goes out the IGW.
resource "aws_route" "echobase_public_default_route" {
  route_table_id         = aws_route_table.echobase_public_rt01.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.echobase_igw01.id
}

# Explanation: Attach public subnets to the “public lanes.”
resource "aws_route_table_association" "echobase_public_rta" {
  count          = length(aws_subnet.echobase_public_subnets)
  subnet_id      = aws_subnet.echobase_public_subnets[count.index].id
  route_table_id = aws_route_table.echobase_public_rt01.id
}

# Explanation: Private route table = “stay hidden, but still ship supplies.”
resource "aws_route_table" "echobase_private_rt01" {
  vpc_id = aws_vpc.echobase_vpc01.id

  tags = {
    Name = "${local.name_prefix}-private-rt01"
  }
}

# Explanation: Private subnets route outbound internet via NAT (Echobase-approved stealth).
# resource "aws_route" "echobase_private_default_route" {
#   route_table_id         = aws_route_table.echobase_private_rt01.id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.echobase_nat01.id
# }

# Explanation: Attach private subnets to the “stealth lanes.”
resource "aws_route_table_association" "echobase_private_rta" {
  count          = length(aws_subnet.echobase_private_subnets)
  subnet_id      = aws_subnet.echobase_private_subnets[count.index].id
  route_table_id = aws_route_table.echobase_private_rt01.id
}

############################################
# Security Groups (EC2 + RDS)
############################################

# # Explanation: EC2 SG is Echobase’s bodyguard—only let in what you mean to.
resource "aws_security_group" "echobase_ec2_sg01" {
  name        = "${local.name_prefix}-ec2-sg01"
  description = "EC2 app security group"
  vpc_id      = aws_vpc.echobase_vpc01.id

  tags = {
    Name = "${local.name_prefix}-ec2-sg01"
  }
}

# # TODO: student adds inbound rules (HTTP 80, SSH 22 from their IP)
# # added by Lonnie Hodges
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.echobase_ec2_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.echobase_ec2_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

# # added by Lonnie Hodges
# # Jenkins 8080
resource "aws_vpc_security_group_ingress_rule" "jenkins" {
  security_group_id = aws_security_group.echobase_ec2_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  #cidr_ipv4   = "65.32.131.115/32"
  ip_protocol = "tcp"
  from_port   = 8080
  to_port     = 8080
}

resource "aws_vpc_security_group_egress_rule" "out_ec2_all" {
  security_group_id = aws_security_group.echobase_ec2_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

############################################
# EC2 Instance (App Host)
############################################

# Explanation: This is your “Han Solo box”—it talks to RDS and complains loudly when the DB is down.
resource "aws_instance" "echobase_ec201" {
  ami                         = var.ec2_ami_id
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.echobase_public_subnets[0].id
  vpc_security_group_ids      = [aws_security_group.echobase_ec2_sg01.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.linux.key_name

  # provisioner "file" {
  #   source      = "${path.module}/plugins.yaml"
  #   destination = "/tmp/plugins.yaml"

  #   connection {
  #     type        = "ssh"
  #     user        = "ec2-user"
  #     private_key = file("${path.module}/id_ed25519_aws_ec2")
  #     host        = self.public_ip
  #   }

  # }

  # TODO: student supplies user_data to install app + CW agent + configure log shipping
  # added by Lonnie Hodges
  user_data = file("${path.module}/user-data.sh")

  root_block_device {
    volume_size = 20
  }

  tags = {
    Name = "jenkins-${local.name_prefix}-ec201"
  }
}

#--------------------------------------------------------------------
# Compute - Key Pairs
#
# Windows:  https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement
# Linux/Mac: https://www.ssh.com/academy/ssh/keygen
# Linux/Mac: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
#--------------------------------------------------------------------
resource "aws_key_pair" "linux" {
  public_key      = file("${path.module}/id_ed25519_aws_ec2.pub")
  key_name_prefix = "${local.name_prefix}-kp201"
}

