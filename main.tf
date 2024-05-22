# main.tf

provider "aws" {
  region = var.aws_region
}

provider "time" {}

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "random_pet" "random_name" {
  length = 1
}

# VPC Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"
  name    = "my-vpc"
  cidr    = var.vpc_cidr_block

  azs              = data.aws_availability_zones.available.names
  public_subnets   = slice(var.public_subnet_cidr_blocks, 0, var.public_subnet_count)
  private_subnets  = slice(var.private_subnet_cidr_blocks, 0, var.private_subnet_count)
  database_subnets = slice(var.private_subnet_cidr_blocks, var.private_subnet_count, var.private_subnet_count * 2)

  enable_nat_gateway = true
  enable_vpn_gateway = false
  single_nat_gateway = true

  tags = var.tags
}

module "aws-security-group" {
  source = "./modules/aws-security-group"

  vpc_id = module.vpc.vpc_id

  tags = var.tags
}

# ECS Cluster Module
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.11.1" # Specify the desired version

  cluster_name = "my-ecs-cluster-${random_pet.random_name.id}-${var.tags["builder"]}-${var.tags["context"]}"
}

module "ec2_autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "7.4.1"

  name = "my-asg"

  launch_template_name    = "my-launch-template"
  launch_template_version = "$Latest"

  vpc_zone_identifier = module.vpc.private_subnets
  min_size            = 1
  max_size            = 4
  desired_capacity    = 3

  instance_type = "t2.micro"
  image_id      = data.aws_ami.ubuntu.id
}

resource "aws_launch_template" "example" {
  name = "my-launch-template"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = module.aws-security-group.ec2_sg_ids
  }
}


module "elb" {
  source  = "terraform-aws-modules/elb/aws"
  version = "4.0.1"

  # Ensure load balancer name is unique
  name = "lb-${random_pet.random_name.id}-${var.tags["builder"]}-${var.tags["context"]}"

  internal = false

  security_groups = module.aws-security-group.alb_sg_ids
  subnets         = module.vpc.public_subnets

  number_of_instances = length(module.ec2_instances.instance_ids)
  instances           = module.ec2_instances.instance_ids

  listener = [{
    instance_port     = "80"
    instance_protocol = "HTTP"
    lb_port           = "80"
    lb_protocol       = "HTTP"
  }]

  health_check = {
    target              = "HTTP:80/index.html"
    interval            = 10
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
  }

  tags = var.tags
}

module "ec2_instances" {
  source = "./modules/aws-instance"

  depends_on = [module.vpc]

  instance_count     = var.private_subnet_count
  instance_type      = var.ec2_instance_type
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = module.aws-security-group.ec2_sg_ids

  tags = var.tags
}

# RDS Module
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.6.0"

  identifier     = "my-rds-sonartest"
  engine         = "mysql"
  engine_version = "5.7"
  instance_class = var.db_instance_type

  family               = "mysql5.7"
  major_engine_version = "5.7"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"

  db_name  = "mydbSonarTest"
  username = var.db_username
  password = var.db_password


  subnet_ids             = module.vpc.database_subnets
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = module.aws-security-group.rds_sg_ids

  multi_az            = true
  publicly_accessible = false
  storage_encrypted   = true

  backup_retention_period = 7
}

module "website_s3_bucket" {
  source = "./modules/aws-s3-static-website-bucket"

  bucket_name = "bucket-leclerc-${random_pet.random_name.id}-${var.tags["builder"]}-${var.tags["context"]}"

  tags = var.tags
}
