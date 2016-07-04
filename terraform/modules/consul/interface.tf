variable "vpc_id" {
  type = "string"
}

variable "vpc_zone_name" {
  type = "string"
}

variable "vpc_zone_id" {
  type = "string"
}

variable "subnets" {
  type = "list"
}

variable "cluster_size" {
  type = "string"
}

variable "cluster_name" {
  type = "string"
}

variable "ingress_cidr_blocks" {
  type = "list"
}

variable "key_name" {
  type = "string"
}

variable "ami" {
  type = "string"
}

variable "instance_type" {
  type = "string"
}

output "asg_id" {
  value = "${aws_autoscaling_group.consul_server.id}"
}

output "ui_elb_dns_name" {
  value = "${aws_elb.consul_server.dns_name}"
}

output "client_sg_id" {
  value = "${aws_security_group.consul.id}"
}
