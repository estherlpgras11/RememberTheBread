variable "aws_profile" {
  default = "default"
}

variable "aws_region" {
  default = "eu-west-1"
}

variable "resource_name_pattern" {
  default = "kc"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "subnet_public1_cidr" {
  default = "10.0.1.0/24"
}

variable "subnet_public2_cidr" {
  default = "10.0.2.0/24"
}

variable "subnet_private1_cidr" {
  default = "10.0.3.0/24"
}

variable "subnet_private2_cidr" {
  default = "10.0.4.0/24"
}

variable "az_a" {
  default = "eu-west-1a"
}

variable "az_b" {
  default = "eu-west-1b"
}

variable "keypair_name" {
  default = "key"
}

variable "keypair_path" {
  default = "./key.pub"
}

variable "instance_ami" {
  default = "ami-06ce3edf0cff21f07"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "db_name" {
  default = "mydb"
}

variable "db_username" {
  default = "admin"
}

variable "db_password" {
  default = "keepcoding"
}