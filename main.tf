##################################################################

#Gets the current Amazon Linux AMI for the region
module "ami" {
  source = "modules/amazon-linux/"
}

#
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name = "test-vpc"
  cidr = "${var.vpc_cidr}"

  azs             = ["${element(var.aws_availability_zones["${var.aws_region}"], 0)}", "${element(var.aws_availability_zones["${var.aws_region}"], 1)}"]
  private_subnets = ["${var.private_subnet_cidr}"]
  public_subnets  = ["${var.public_subnet_cidr}"]

  enable_nat_gateway = true

  reuse_nat_ips       = true                      # Skip creation of EIPs for the NAT Gateways
  external_nat_ip_ids = ["${aws_eip.nat.*.id}"]   # IPs specified here as input to the module

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

module "docker_sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = "docker-instance"
  description = "Security group for web-server with HTTP ports open within VPC"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress_cidr_blocks = ["${var.public_subnet_cidr}"]
}

#module "public_host_sg" {
#  source = "terraform-aws-modules/security-group/aws"
#
#  name        = "public-host"
#  description = "Security group for user-service with custom ports open within VPC"
#  vpc_id      = "${module.vpc.vpc_id}"
#
#  ingress_cidr_blocks      = ["${var.public_ip}/24"]
#  ingress_rules            = ["ssh-tcp"]
#  egress_cidr_blocks       = ["0.0.0.0/0"]
#  egress_rules             = ["all-all"]
#}

#module "public_to_private_sg" {
#  source = "terraform-aws-modules/security-group/aws"
#
#  name        = "public-to-private"
#  description = "Security group for user-service with custom ports open within VPC"
#  vpc_id      = "${module.vpc.vpc_id}"
#
#  ingress_cidr_blocks      = ["${var.private_subnet_cidr}" , "${var.public_subnet_cidr}"]
#  ingress_rules            = ["all-all"]
#  egress_cidr_blocks       = ["${var.private_subnet_cidr}" , "${var.public_subnet_cidr}"]
#  egress_rules             = ["ssh-tcp"]
#}

module "asg" {
  source = "terraform-aws-modules/autoscaling/aws"
  name = "docker"

  # Launch configuration settings
  lc_name = "docker-launch-config"

  image_id             = "${module.ami.ec2_linux_ami_id}"
  instance_type        = "t2.micro"
  security_groups      = ["${module.docker_sg.this_security_group_id}"]# "${module.public_to_private_sg.this_security_group_id}"]
  key_name             = "${var.key_name}"
  iam_instance_profile = "${aws_iam_instance_profile.docker_instance_profile.id}"

  ebs_block_device = [
    {
      device_name           = "/dev/xvdz"
      volume_type           = "gp2"
      volume_size           = "50"
      delete_on_termination = true
    },
  ]

  root_block_device = [
    {
      volume_size = "50"
      volume_type = "gp2"
    },
  ]

  # Auto scaling group
  asg_name                  = "docker-asg"
  vpc_zone_identifier       = ["${module.vpc.private_subnets[0]}", "${module.vpc.private_subnets[1]}"]
  health_check_type         = "EC2"
  min_size                  = "${var.instance_count}"
  max_size                  = "${var.instance_count}"
  desired_capacity          = "${var.instance_count}"
  wait_for_capacity_timeout = 0
  user_data                 = "${data.template_cloudinit_config.docker.rendered}"
  tags = [
    {
      key                 = "Environment"
      value               = "dev"
      propagate_at_launch = true
    },
    {
      key                 = "Terraform"
      value               = "true"
      propagate_at_launch = true
    },
  ]
}


#The following is for a bastion/jump box host to access the ec2 instances created
#Uses the public IP address in variables.tf to create a security group only your public source address can access
#
#module "public_host_sg" {
#  source = "terraform-aws-modules/security-group/aws"
#
#  name        = "public-host"
#  description = "Security group for user-service with custom ports open within VPC"
#  vpc_id      = "${module.vpc.vpc_id}"
#
#  ingress_cidr_blocks      = ["${var.public_ip}/32"]
#  ingress_rules            = ["ssh-tcp"]
#  egress_cidr_blocks       = ["0.0.0.0/0"]
#  egress_rules             = ["all-all"]
#}

#module "public_to_private_sg" {
#  source = "terraform-aws-modules/security-group/aws"
#
#  name        = "public-to-private"
#  description = "Security group for user-service with custom ports open within VPC"
#  vpc_id      = "${module.vpc.vpc_id}"
#
#  ingress_cidr_blocks      = ["${var.private_subnet_cidr}" , "${var.public_subnet_cidr}"]
#  ingress_rules            = ["all-all"]
#  egress_cidr_blocks       = ["${var.private_subnet_cidr}" , "${var.public_subnet_cidr}"]
#  egress_rules             = ["ssh-tcp"]
#}

#module "public_host" {
#  source                 = "terraform-aws-modules/ec2-instance/aws"
#  version                = "1.12.0"
#
#  name                   = "public-host"
#  instance_count         = "1"
#  associate_public_ip_address = "true"
#
#  ami                    = "${module.ami.ec2_linux_ami_id}"
#  instance_type          = "t2.micro"
#  key_name               = "${var.key_name}"
#  monitoring             = true
#  vpc_security_group_ids = ["${module.public_host_sg.this_security_group_id}"]
#  subnet_id              = "${module.vpc.public_subnets[0]}"
#
#  tags = {
#    Terraform = "true"
#    Environment = "dev"
#  }
#}

