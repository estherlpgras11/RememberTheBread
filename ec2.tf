############################# DATABASE ####################################

resource "aws_db_instance" "vm_db" {
  engine                              = "MySQL"
  engine_version                      = "8.0.21"
  storage_type                        = "gp2"
  instance_class                      = "db.t2.micro"
  identifier                          = "mysql-webapp"
  allocated_storage                   = 20
  max_allocated_storage               = 0
  port                                = 3306
  iam_database_authentication_enabled = false
  name                                = var.db_name
  username                            = var.db_username
  password                            = var.db_password
  parameter_group_name                = "default.mysql8.0"
  vpc_security_group_ids              = [aws_security_group.sg_db.id]
  publicly_accessible                 = true
  db_subnet_group_name                = aws_db_subnet_group.subnet_group.id
  apply_immediately                   = true
  multi_az                            = false
  allow_major_version_upgrade         = false
  auto_minor_version_upgrade          = false
  deletion_protection                 = false
  skip_final_snapshot                 = true
  performance_insights_enabled        = false
  backup_retention_period             = 0
}


############################## LAUNCH TEMPLATE WEBAPP ##############################

resource "aws_launch_template" "lt_webapp" {
  name          = "lt-webapp"
  image_id      = var.instance_ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.key_pair.key_name
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.sg_webapp.id]
  }
  user_data = filebase64("./bootstrap.sh")
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
  tags = {
    Name = "${var.resource_name_pattern}-vm-webapp"
  }
}

############################## LOAD BALANCER ##############################

# Create a new load balancer
resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = [aws_subnet.subnet_public1.id, aws_subnet.subnet_public2.id]
  depends_on = [
    aws_subnet.subnet_public1,
    aws_subnet.subnet_public2,
    aws_security_group.sg_alb
  ]
}

# Target group
resource "aws_lb_target_group" "target_group" {
  name        = "webapp-tg"
  target_type = "instance"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  health_check {
    path                = "/api/utils/healthcheck"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 4
    interval            = 5
    matcher             = "200"
  }
  depends_on = [
    aws_lb.alb
  ]
}

# Listener
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
  depends_on = [
    aws_lb.alb,
    aws_lb_target_group.target_group
  ]
}


############################## AUTOSCALING GROUP ##############################

resource "aws_autoscaling_group" "ag_webapp" {
  target_group_arns   = [aws_lb_target_group.target_group.arn]
  vpc_zone_identifier = [aws_subnet.subnet_private1.id, aws_subnet.subnet_private2.id]
  desired_capacity    = 2
  max_size            = 2
  min_size            = 2

  launch_template {
    id      = aws_launch_template.lt_webapp.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "ASG"
    propagate_at_launch = true
  }
}


############################## BASTION ##############################


resource "aws_instance" "bastion" {
  ami                         = "ami-0c95efaa8fa6e2424"
  instance_type               = "t2.large"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.subnet_public1.id
  vpc_security_group_ids      = [aws_security_group.sg_bastion.id]
  key_name                    = aws_key_pair.key_pair.key_name
  disable_api_termination     = false
  monitoring                  = false
  tags = {
    Name = "bastion"
  }
  depends_on = [
    aws_subnet.subnet_public1,
    aws_security_group.sg_bastion,
    aws_key_pair.key_pair
  ]
}
