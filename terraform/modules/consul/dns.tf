resource "aws_route53_record" "consul_servers" {
  zone_id = "${var.vpc_zone_id}"
  name    = "consul.${var.vpc_zone_name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_elb.consul_server.dns_name}"]
}
