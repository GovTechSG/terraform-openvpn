resource "aws_network_acl_rule" "allow-udp-connection" {
  for_each = var.nacl_udp_port_allow_list

  network_acl_id = each.value.nacl_id
  cidr_block     = "0.0.0.0/0"
  rule_number    = each.value.rule_number
  protocol       = "udp"
  from_port      = 1194
  to_port        = 65535
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "allow-udp-connection-egress" {
  for_each = var.nacl_udp_port_allow_list

  network_acl_id = each.value.nacl_id
  cidr_block     = "0.0.0.0/0"
  rule_number    = each.value.rule_number
  protocol       = "udp"
  from_port      = 1194
  to_port        = 65535
  rule_action    = "allow"
  egress         = true
}