
output "security_group_id_web" {
  value = aws_security_group.openvpn-web.id
}

output "security_group_id_connection" {
  value = aws_security_group.openvpn-conn.id
}

output "security_group_id_ec2" {
  value = aws_security_group.ec2.id
}

output "instance_profile_arn" {
  value = var.use_rds ? aws_iam_instance_profile.openvpn-ec2-profile[0].arn : ""
}

output "instance_primary_arn" {
  value = aws_instance.primary.arn
}

output "instance_root_block_id" {
  value = aws_instance.primary.root_block_device.0.volume_id
}

output "aws_lb_web_arn" {
  value = aws_lb.web.arn
}

output "aws_lb_web_dns" {
  value = aws_lb.web.dns_name
}

output "aws_lb_connection_arn" {
  value = aws_lb.connection.arn
}

output "aws_lb_connection_dns" {
  value = aws_lb.connection.dns_name
}

output "asg_arn" {
  value = aws_autoscaling_group.ovpn-ext-asg.arn
}

output "launch_configuration_arn" {
  value = aws_launch_configuration.ovpn-launch.arn
}

output "acm_arn" {
  value = aws_acm_certificate.cert.arn
}

output "acm_domain_name" {
  value = aws_acm_certificate.cert.domain_name
}