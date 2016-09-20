provider "aws" {
  region = "us-west-2"
}

variable "key_name" {
  type    = "string"
  default = "jen20"
}

variable "instance_type" {
  type    = "string"
  default = "m3.medium"
}

data "aws_ami" "consul_server" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:Service"
    values = ["ConsulServer"]
  }

  filter {
    name   = "tag:OS"
    values = ["Ubuntu-16.04"]
  }
}

data "terraform_remote_state" "vpc" {
  backend = "atlas"

  config = {
	  name="jen20/ny-hug-vpc"
  }
}

module "consul" {
  source = "modules/consul"

  cluster_name = "NY HUG"
  cluster_size = 3

  vpc_zone_name = "${data.terraform_remote_state.vpc.zone_name}"
  vpc_zone_id   = "${data.terraform_remote_state.vpc.zone_id}"

  vpc_id              = "${data.terraform_remote_state.vpc.vpc_id}"
  subnets             = ["${data.terraform_remote_state.vpc.private_subnet_ids}"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  key_name      = "${var.key_name}"
  ami           = "${data.aws_ami.consul_server.id}"
  instance_type = "${var.instance_type}"
}

output "asg_id" {
  value = "${module.consul.asg_id}"
}

output "ui_elb_dns_name" {
  value = "${module.consul.ui_elb_dns_name}"
}

output "client_sg_id" {
  value = "${module.consul.client_sg_id}"
}
