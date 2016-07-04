resource "aws_security_group" "consul_elb" {
  name        = "consul-ui-elb-sg"
  description = "Security group for the Consul UI/Join ELBs"
  vpc_id      = "${var.vpc_id}"

  tags {
    Name = "Consul UI (ELB) (${var.cluster_name})"
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.ingress_cidr_blocks}"]
  }

  # Join (Serf TCP)
  # TODO(jen20): Make this more restrictive
  ingress {
    from_port   = 8301
    to_port     = 8301
    protocol    = "tcp"
    cidr_blocks = ["${var.ingress_cidr_blocks}"]
  }

  # TCP All outbound traffic
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# TODO(jen20): Lock this down
resource "aws_security_group" "consul" {
  name        = "consul-sg"
  description = "Security group for Consul Agent instances"
  vpc_id      = "${var.vpc_id}"

  tags {
    Name = "Consul Agent (Instance)"
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.ingress_cidr_blocks}"]
  }

  # Serf (TCP)
  ingress {
    from_port   = 8301
    to_port     = 8302
    protocol    = "tcp"
    cidr_blocks = ["${var.ingress_cidr_blocks}"]
  }

  # Serf (UDP)
  ingress {
    from_port   = 8301
    to_port     = 8302
    protocol    = "udp"
    cidr_blocks = ["${var.ingress_cidr_blocks}"]
  }

  # Server RPC
  ingress {
    from_port   = 8300
    to_port     = 8300
    protocol    = "tcp"
    cidr_blocks = ["${var.ingress_cidr_blocks}"]
  }

  # RPC
  ingress {
    from_port   = 8400
    to_port     = 8400
    protocol    = "tcp"
    cidr_blocks = ["${var.ingress_cidr_blocks}"]
  }

  # TCP All outbound traffic
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # UDP All outbound traffic
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "consul_server" {
  name        = "consul-server-sg"
  description = "Security group for Consul Server instances"
  vpc_id      = "${var.vpc_id}"

  tags {
    Name = "Consul Server (Instance) (${var.cluster_name})"
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.ingress_cidr_blocks}"]
  }

  # HTTP UI from ELB
  ingress {
    from_port       = 8500
    to_port         = 8500
    protocol        = "tcp"
    security_groups = ["${aws_security_group.consul_elb.id}"]
  }

  # DNS (TCP)
  ingress {
    from_port   = 8600
    to_port     = 8600
    protocol    = "tcp"
    cidr_blocks = ["${var.ingress_cidr_blocks}"]
  }

  # DNS (UDP)
  ingress {
    from_port   = 8600
    to_port     = 8600
    protocol    = "udp"
    cidr_blocks = ["${var.ingress_cidr_blocks}"]
  }

  # HTTP
  ingress {
    from_port   = 8500
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = ["${var.ingress_cidr_blocks}"]
  }

  # Serf (TCP)
  ingress {
    from_port   = 8301
    to_port     = 8302
    protocol    = "tcp"
    cidr_blocks = ["${var.ingress_cidr_blocks}"]
  }

  # Serf (UDP)
  ingress {
    from_port   = 8301
    to_port     = 8302
    protocol    = "udp"
    cidr_blocks = ["${var.ingress_cidr_blocks}"]
  }

  # Server RPC
  ingress {
    from_port   = 8300
    to_port     = 8300
    protocol    = "tcp"
    cidr_blocks = ["${var.ingress_cidr_blocks}"]
  }

  # RPC
  ingress {
    from_port   = 8400
    to_port     = 8400
    protocol    = "tcp"
    cidr_blocks = ["${var.ingress_cidr_blocks}"]
  }

  # TCP All outbound traffic
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # UDP All outbound traffic
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "consul_server" {
  name               = "ConsulServer"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_role_policy" "consul_server" {
  name   = "ConsulServer"
  role   = "${aws_iam_role.consul_server.id}"
  policy = "${data.aws_iam_policy_document.consul_server.json}"
}

resource "aws_iam_instance_profile" "consul_server" {
  name  = "ConsulServer"
  roles = ["${aws_iam_role.consul_server.name}"]
}

resource "aws_launch_configuration" "consul_server" {
  image_id                    = "${var.ami}"
  instance_type               = "${var.instance_type}"
  security_groups             = ["${aws_security_group.consul_server.id}"]
  associate_public_ip_address = false
  ebs_optimized               = false
  key_name                    = "${var.key_name}"
  iam_instance_profile        = "${aws_iam_instance_profile.consul_server.id}"
}

resource "aws_autoscaling_group" "consul_server" {
  launch_configuration = "${aws_launch_configuration.consul_server.id}"
  vpc_zone_identifier  = ["${var.subnets}"]

  name = "${var.cluster_name}"

  max_size         = "${var.cluster_size}"
  min_size         = "${var.cluster_size}"
  desired_capacity = "${var.cluster_size}"
  default_cooldown = 30
  force_delete     = true

  load_balancers = ["${aws_elb.consul_server.name}"]

  tag {
    key                 = "Name"
    value               = "${format("%s Consul Server", var.cluster_name)}"
    propagate_at_launch = true
  }
}

resource "aws_elb" "consul_server" {
  name            = "${replace("${var.cluster_name} UI ELB", " ", "-")}"
  internal        = true
  security_groups = ["${aws_security_group.consul_elb.id}"]
  subnets         = ["${var.subnets}"]

  listener {
    instance_port     = 8500
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 8301
    instance_protocol = "tcp"
    lb_port           = 8301
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 10
    target              = "HTTP:8500/v1/catalog/datacenters"
    interval            = 30
  }
}
