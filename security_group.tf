# EC2 Security group
resource "aws_security_group" "ec2" {
  name        = "${var.name}-ec2"
  description = var.name
  vpc_id      = var.vpc_id

  tags = var.tags
}

resource "aws_security_group_rule" "allow-from-elb" {
  type        = "ingress"
  description = "WEB ALB to EC2"

  from_port                = var.web_port
  to_port                  = var.web_port
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.openvpn-web.id
  security_group_id        = aws_security_group.ec2.id
}

resource "aws_security_group_rule" "allow-943-from-cidr" {
  for_each    = var.admin_allowed_ips
  type        = "ingress"
  description = "Direct to EC2"

  from_port         = var.admin_port
  to_port           = var.admin_port
  protocol          = "TCP"
  cidr_blocks       = each.value.ip_addr
  security_group_id = aws_security_group.ec2.id
}

resource "aws_security_group_rule" "allow-1194-to-ec2" {
  type        = "ingress"
  description = "All to EC2 UDP"

  from_port         = 1194
  to_port           = 1194
  protocol          = "UDP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2.id
}

resource "aws_security_group_rule" "allow-conn-to-ec2" {
  count       = var.conn_allow_public ? 1 : 0
  type        = "ingress"
  description = "All to EC2 connection port"

  from_port         = var.conn_port
  to_port           = var.conn_port
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2.id
}

resource "aws_security_group_rule" "allow-web-internal" {
  for_each    = var.web_allowed_ips
  type        = "ingress"
  description = each.value.name

  from_port         = var.web_port
  to_port           = var.web_port
  protocol          = "TCP"
  cidr_blocks       = each.value.ip_addr
  security_group_id = aws_security_group.ec2.id
}

resource "aws_security_group_rule" "allow-outbound" {
  type        = "egress"
  description = "Allow all outbound"

  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2.id
}

resource "aws_security_group_rule" "allow-ssh" {
  for_each    = var.ssh_allowed_ips
  type        = "ingress"
  description = each.value.name

  from_port         = 22
  to_port           = 22
  protocol          = "TCP"
  cidr_blocks       = each.value.ip_addr
  security_group_id = aws_security_group.ec2.id
}

# Openvpn Connection ELB Security Group
resource "aws_security_group" "openvpn-conn" {
  name        = "${var.name}-connection"
  description = var.name
  vpc_id      = var.vpc_id

  tags = var.tags
}

resource "aws_security_group_rule" "conn-ingress-individual" {
  for_each = var.conn_allowed_ips

  type        = "ingress"
  description = each.value.name

  from_port         = var.conn_port
  to_port           = var.conn_port
  protocol          = "tcp"
  cidr_blocks       = each.value.ip_addr
  security_group_id = aws_security_group.openvpn-conn.id
}

resource "aws_security_group_rule" "conn-ingress-public" {
  count = var.web_allow_public ? 1 : 0

  type        = "ingress"
  description = "Public"

  from_port         = var.conn_port
  to_port           = var.conn_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.openvpn-conn.id
}

resource "aws_security_group_rule" "conn-egress" {
  type = "egress"

  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.openvpn-conn.id
}

# Openvpn Web UI ELB Security Group
resource "aws_security_group" "openvpn-web" {
  name        = var.name
  description = var.name
  vpc_id      = var.vpc_id

  tags = var.tags
}

resource "aws_security_group_rule" "web-ingress-individual-80" {
  for_each = var.web_allowed_ips

  type        = "ingress"
  description = each.value.name

  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  cidr_blocks       = each.value.ip_addr
  security_group_id = aws_security_group.openvpn-web.id
}

resource "aws_security_group_rule" "web-ingress-individual-443" {
  for_each = var.web_allowed_ips

  type        = "ingress"
  description = each.value.name

  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  cidr_blocks       = each.value.ip_addr
  security_group_id = aws_security_group.openvpn-web.id
}

resource "aws_security_group_rule" "web-ingress-public-80" {
  count = var.web_allow_public ? 1 : 0

  type        = "ingress"
  description = "Public"

  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.openvpn-web.id
}

resource "aws_security_group_rule" "web-ingress-public-443" {
  count = var.web_allow_public ? 1 : 0

  type        = "ingress"
  description = "Public"

  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.openvpn-web.id
}

resource "aws_security_group_rule" "web-egress" {
  type = "egress"

  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.openvpn-web.id
}
