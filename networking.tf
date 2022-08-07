
############################## VPC ######################################

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.resource_name_pattern}-vpc"
  }
}

############################## DNS ######################################

resource "aws_route53_zone" "kcdevops" {
  name = "kcdevops.com"
  vpc {
    vpc_id = aws_vpc.vpc.id
  }
}

resource "aws_route53_record" "aws" {
  zone_id = aws_route53_zone.kcdevops.zone_id
  name    = "aws.kcdevops.com"
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
  depends_on = [
    aws_route53_zone.kcdevops,
    aws_lb.alb
  ]
}

##############################  INTERNET GATEWAY  ######################################

## Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.resource_name_pattern}-igw"
  }
  depends_on = [
    aws_vpc.vpc
  ]
}

resource "aws_route_table" "igw" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.resource_name_pattern}-rt_igw"
  }
  depends_on = [
    aws_vpc.vpc,
    aws_internet_gateway.igw
  ]
}


############################## ELASTIC IP's ######################################

## Elastic IP's para el nat_gw
resource "aws_eip" "nat_eip" {
  vpc              = true
  public_ipv4_pool = "amazon"
  tags = {
    Name = "${var.resource_name_pattern}-nat_eip"
  }
  depends_on = [
    aws_vpc.vpc
  ]
}

############################## NAT GATEWAY ######################################
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.subnet_public1.id
  tags = {
    Name = "${var.resource_name_pattern}-nat_gw"
  }
}

resource "aws_route_table" "ngw" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "${var.resource_name_pattern}-rt_natgw"
  }
  depends_on = [
    aws_vpc.vpc,
    aws_nat_gateway.nat_gw
  ]
}


############################## SUBNETS ######################################

########## Subnets PUBLICAS

resource "aws_subnet" "subnet_public1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subnet_public1_cidr
  map_public_ip_on_launch = false
  availability_zone       = var.az_a
  tags = {
    Name = "${var.resource_name_pattern}-subnet-public1"
  }
  depends_on = [
    aws_vpc.vpc
  ]
}

resource "aws_subnet" "subnet_public2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subnet_public2_cidr
  map_public_ip_on_launch = false
  availability_zone       = var.az_b
  tags = {
    Name = "${var.resource_name_pattern}-subnet-public2"
  }
  depends_on = [
    aws_vpc.vpc
  ]
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.subnet_public1.id
  route_table_id = aws_route_table.igw.id
  depends_on = [
    aws_subnet.subnet_public1,
    aws_route_table.ngw
  ]
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.subnet_public2.id
  route_table_id = aws_route_table.igw.id
  depends_on = [
    aws_subnet.subnet_public2,
    aws_route_table.ngw
  ]
}

########## Subnets PRIVADAS

resource "aws_subnet" "subnet_private1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subnet_private1_cidr
  availability_zone       = var.az_a
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.resource_name_pattern}-subnet-private1"
  }
}

resource "aws_subnet" "subnet_private2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subnet_private2_cidr
  map_public_ip_on_launch = false
  availability_zone       = var.az_b
  tags = {
    Name = "${var.resource_name_pattern}-subnet-private2"
  }
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.subnet_private1.id
  route_table_id = aws_route_table.ngw.id
  depends_on = [
    aws_subnet.subnet_private1,
    aws_route_table.ngw
  ]
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.subnet_private2.id
  route_table_id = aws_route_table.ngw.id
  depends_on = [
    aws_subnet.subnet_private2,
    aws_route_table.ngw
  ]
}

############################## SECURITY GROUPS ######################################

# SG DB
resource "aws_security_group" "sg_db" {
  name   = "sg_db"
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "sg_db"
  }
  depends_on = [
    aws_vpc.vpc
  ]
}

# SG WEBAPP
resource "aws_security_group" "sg_webapp" {
  name   = "sg_webapp"
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "sg_webapp"
  }
  depends_on = [
    aws_vpc.vpc
  ]
}

# SG ALB
resource "aws_security_group" "sg_alb" {
  name   = "sg_alb"
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "sg_alb"
  }
  depends_on = [
    aws_vpc.vpc
  ]
}

# SG Bastion Host
resource "aws_security_group" "sg_bastion" {
  name   = "sg_bastion"
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "sg_bastion"
  }
  depends_on = [
    aws_vpc.vpc
  ]
}

# Habilitamos las peticiones entrantes Database (RDS) <- Webapp (EC2) en el puerto TCP 3306.
resource "aws_security_group_rule" "security_group_rule_1" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.sg_webapp.id
  description              = "Webapp instances access"
  security_group_id        = aws_security_group.sg_db.id
  depends_on = [
    aws_security_group.sg_webapp,
    aws_security_group.sg_db
  ]
}

# Habilitamos las peticiones salientes Webapp (EC2) -> Database (RDS) en el puerto TCP 3306.
resource "aws_security_group_rule" "security_group_rule_2" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.sg_db.id
  description              = "Webapp database access"
  security_group_id        = aws_security_group.sg_webapp.id
  depends_on = [
    aws_security_group.sg_webapp,
    aws_security_group.sg_db
  ]
}

# Habilitamos todo el tráfico saliente Webapp (EC2) -> Internet.
resource "aws_security_group_rule" "security_group_rule_3" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Internet access"
  security_group_id = aws_security_group.sg_webapp.id
  depends_on = [
    aws_security_group.sg_webapp,
  ]
}

# Habilitamos las peticiones entrantes Webapp (EC2) <- Load Balancer (ALB) en el puerto TCP 8080.
resource "aws_security_group_rule" "security_group_rule_4" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.sg_alb.id
  description              = "Webapp balancer access"
  security_group_id        = aws_security_group.sg_webapp.id
  depends_on = [
    aws_security_group.sg_webapp,
    aws_security_group.sg_alb
  ]
}

# Habilitamos las peticiones salientes Load Balancer (ALB) -> Webapp (EC2) en el puerto TCP 8080.
resource "aws_security_group_rule" "security_group_rule_5" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.sg_webapp.id
  description              = "Webapp instances access"
  security_group_id        = aws_security_group.sg_alb.id
  depends_on = [
    aws_security_group.sg_webapp,
    aws_security_group.sg_alb
  ]
}

# Habilitamos las peticiones entrantes Load Balancer (ALB) <- Internet en el puerto TCP 80.
resource "aws_security_group_rule" "security_group_rule_6" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Webapp public access"
  security_group_id = aws_security_group.sg_alb.id
  depends_on = [
    aws_security_group.sg_alb
  ]
}

# Habilitamos las peticiones entrantes Bastion Host (EC2) <- Internet en el puerto TCP 3389.
resource "aws_security_group_rule" "security_group_rule_7" {
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "RDP public access"
  security_group_id = aws_security_group.sg_bastion.id
  depends_on = [
    aws_security_group.sg_bastion,
  ]
}

# Habilitamos todo el tráfico saliente Bastion Host (EC2) -> Internet.
resource "aws_security_group_rule" "security_group_rule_8" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Internet access"
  security_group_id = aws_security_group.sg_bastion.id
  depends_on = [
    aws_security_group.sg_bastion,
  ]
}

############################## DB SUBNET GROUP ######################################

resource "aws_db_subnet_group" "subnet_group" {
  name        = "subnet_group"
  description = "Webapp database subnet group"
  subnet_ids = [
    aws_subnet.subnet_private1.id,
    aws_subnet.subnet_private2.id
  ]
  tags = {
    Name = "RDS_subnet_group"
  }
  depends_on = [
    aws_subnet.subnet_private1,
    aws_subnet.subnet_private2
  ]
}