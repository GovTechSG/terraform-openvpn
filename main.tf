data "template_file" "ovpn_ext_tpl_primary" {
  count    = var.use_rds ? 1 : 0
  template = file("${path.module}/vm_openvpn.tpl")

  vars = {
    tf_openvpn_pool_ip        = var.openvpn_pool_ip
    tf_openvpn_hostname       = var.openvpn_hostname
    tf_rds_fqdn               = var.rds_fqdn
    tf_rds_secret_arn         = var.rds_secret_manager_credentials_arn
    tf_conn_port              = var.conn_port
    tf_web_port               = var.web_port
    tf_private_network_cidrs  = join(", ", var.vpn_private_network_cidrs)
    tf_openvpn_admin_password = var.openvpn_secret_manager_credentials_arn
    tf_aws_region             = var.aws_region
  }
}

data "template_file" "ovpn_ext_tpl_secondary" {
  count    = var.use_rds ? 1 : 0
  template = file("${path.module}/vm_openvpn.tpl")

  vars = {
    tf_openvpn_pool_ip        = var.openvpn_pool_ip
    tf_openvpn_hostname       = var.openvpn_hostname
    tf_rds_fqdn               = var.rds_fqdn
    tf_rds_secret_arn         = var.rds_secret_manager_credentials_arn
    tf_conn_port              = var.conn_port
    tf_web_port               = var.web_port
    tf_private_network_cidrs  = join(", ", var.vpn_private_network_cidrs)
    tf_openvpn_admin_password = var.openvpn_secret_manager_credentials_arn
    tf_aws_region             = var.aws_region
  }
}

resource "aws_lb_target_group_attachment" "primary-web" {
  target_group_arn = aws_lb_target_group.web-to-ec2.arn
  target_id        = aws_instance.primary.id
  port             = var.web_port
}

resource "aws_lb_target_group_attachment" "primary-conn" {
  target_group_arn = aws_lb_target_group.conn-to-ec2.arn
  target_id        = aws_instance.primary.id
  port             = var.conn_port
}

resource "aws_lb_target_group_attachment" "primary-conn-udp" {
  target_group_arn = aws_lb_target_group.conn-to-ec2-udp.arn
  target_id        = aws_instance.primary.id
  port             = 1194
}

resource "aws_lb_target_group_attachment" "primary-conn-admin" {
  target_group_arn = aws_lb_target_group.conn-admin-to-ec2.arn
  target_id        = aws_instance.primary.id
  port             = var.admin_port
}

resource "aws_launch_configuration" "ovpn-launch" {
  name_prefix   = "${var.name}-"
  image_id      = var.openvpn_ami_id
  instance_type = "t3.small"

  security_groups = [aws_security_group.ec2.id]
  key_name        = var.key_name
  root_block_device {
    volume_size = "50"
    volume_type = "gp2"
    encrypted   = true
  }

  user_data_base64 = var.use_rds ? base64encode(data.template_file.ovpn_ext_tpl_secondary[0].rendered) : ""

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ovpn-ext-asg" {
  name                 = var.name
  launch_configuration = aws_launch_configuration.ovpn-launch.name
  vpc_zone_identifier  = var.private_subnet_ids
  min_size             = 0
  max_size             = 2
  health_check_type    = "EC2"

  target_group_arns = [aws_lb_target_group.web-to-ec2.arn, aws_lb_target_group.conn-to-ec2.arn, aws_lb_target_group.conn-to-ec2-udp.arn, aws_lb_target_group.conn-admin-to-ec2.arn]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "connection" {
  name               = "${var.name}-lb-conn"
  internal           = false
  load_balancer_type = "network"
  subnets            = var.public_subnet_ids

  enable_deletion_protection       = true
  enable_cross_zone_load_balancing = true

  access_logs {
    bucket  = var.s3_bucket_access_logs
    prefix  = "${var.s3_prefix}${var.name}-openvpn-conn"
    enabled = true
  }

  tags = var.tags
}


resource "aws_route53_record" "conn" {
  zone_id = var.route53_zone_id
  name    = var.openvpn_hostname
  type    = "A"

  alias {
    name                   = aws_lb.connection.dns_name
    zone_id                = aws_lb.connection.zone_id
    evaluate_target_health = true
  }
}

resource "aws_lb_listener" "connection" {
  load_balancer_arn = aws_lb.connection.arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.conn-to-ec2.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "connection-udp" {
  load_balancer_arn = aws_lb.connection.arn
  port              = "1194"
  protocol          = "UDP"

  default_action {
    target_group_arn = aws_lb_target_group.conn-to-ec2-udp.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "connection-admin" {
  load_balancer_arn = aws_lb.connection.arn
  port              = var.admin_port
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.conn-admin-to-ec2.id
    type             = "forward"
  }
}

resource "aws_lb_target_group" "conn-to-ec2-udp" {
  name        = "${var.name}-nlb-udp-openvpn"
  port        = 1194
  protocol    = "UDP"
  target_type = "instance"
  vpc_id      = var.vpc_id
}

resource "aws_lb_target_group" "conn-to-ec2" {
  name        = "${var.name}-nlb-to-openvpn"
  port        = var.conn_port
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.vpc_id
}


resource "aws_lb_target_group" "conn-admin-to-ec2" {
  name        = "${var.name}-admin-to-openvpn"
  port        = var.admin_port
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = var.vpc_id
}

resource "aws_lb" "web" {
  name               = "${var.name}-lb-web"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.openvpn-web.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = true

  access_logs {
    bucket  = var.s3_bucket_access_logs
    prefix  = "alb/${var.name}-openvpn-web"
    enabled = true
  }

  tags = var.tags
}

resource "aws_route53_record" "web" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.web.dns_name
    zone_id                = aws_lb.web.zone_id
    evaluate_target_health = true
  }
}

resource "aws_lb_listener" "web-front-end" {
  load_balancer_arn = aws_lb.web.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web-to-ec2.arn
  }
}

resource "aws_lb_target_group" "web-to-ec2" {
  name        = "${var.name}-alb-to-openvpn"
  port        = 443
  protocol    = "HTTPS"
  target_type = "instance"
  vpc_id      = var.vpc_id
}

resource "aws_iam_instance_profile" "openvpn-ec2-profile" {
  count = var.use_rds ? 1 : 0
  name  = "${var.name}-openvpn-instance-profile"
  role  = aws_iam_role.openvpn[0].name
}

resource "aws_iam_role" "openvpn" {
  count                = var.use_rds ? 1 : 0
  name                 = "${var.name}-role"
  path                 = "/"
  permissions_boundary = var.permissions_boundary

  managed_policy_arns  = var.extra_iam_policy_arns

  inline_policy {
    name = "my_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = "secretsmanager:GetSecretValue"
          Effect   = "Allow"
          Resource = var.rds_secret_manager_credentials_arn
        },
      ]
    })
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_instance" "primary" {
  ami           = var.openvpn_ami_id
  instance_type = "t3.medium"

  subnet_id = var.private_subnet_ids[0]

  root_block_device {
    volume_size = "50"
    volume_type = "gp2"
    encrypted   = true
  }
  monitoring              = true
  disable_api_termination = false
  ebs_optimized           = false
  hibernation             = false

  iam_instance_profile = var.use_rds ? aws_iam_instance_profile.openvpn-ec2-profile[0].name : ""

  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = var.key_name
  user_data_base64       = var.use_rds ? base64encode(data.template_file.ovpn_ext_tpl_primary[0].rendered) : ""

  tags = {
    Name = "${var.name}-primary"
  }
}

