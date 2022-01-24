variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "aws_region" {
  description = "AWS region."
  default     = "ap-southeast-1"
  type        = string
}

variable "name" {
  description = "Name prefix for various resources created"
  type        = string
}

variable "domain_name" {
  description = "domain name to serve site on"
  type        = string
}

variable "openvpn_ami_id" {
  description = "Openvpn AMI id from marketplace subscription"
  type        = string
}

variable "openvpn_hostname" {
  description = "openvpn connection url, different from the web url"
  type        = string
}

variable "openvpn_pool_ip" {
  description = "IP Pool range for clients"
  default     = "172.27.200.0/22"
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 Zone ID"
  type        = string
  default     = ""
}

variable "s3_bucket_access_logs" {
  description = "S3 bucket for storing access logs"
  type        = string
}

variable "s3_prefix" {
  description = "Prefix for access logs if you want to change the object folder. remember to add a prevailing '/' e.g 'nlb/"
  type        = string
  default     = ""
}

variable "public_subnet_ids" {
  description = "List of public subnet ids for elastic load balancer"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet ids for launch configuration to create ec2 instances in"
  type        = list(string)
}

variable "ssh_allowed_ips" {
  type = map(object({
    name    = string,
    ip_addr = set(string)
  }))
  description = "Map of User and IP for ssh"
}

variable "web_allow_public" {
  description = "Allow public to access the web UI?"
  type        = bool
  default     = true
}

variable "admin_allowed_ips" {
  type = map(object({
    name    = string,
    ip_addr = set(string)
  }))
  description = "Map of User and IP for tcp admin_port admin web"
  default     = {}
}

variable "web_allowed_ips" {
  type = map(object({
    name    = string,
    ip_addr = set(string)
  }))
  description = "Map of User and IP for tcp 443 web"
  default     = {}
}

variable "conn_allow_public" {
  description = "Allow public vpn clients to connect to the vpn server?"
  type        = bool
  default     = true
}

variable "key_name" {
  description = "SSH Key pair name"
  type        = string
  default     = ""
}

variable "conn_allowed_ips" {
  type = map(object({
    name    = string,
    ip_addr = set(string)
  }))
  description = "Map of User and IP for openvpn connection"
  default     = {}
}

variable "conn_port" {
  description = "Port number which openvpn clients will use to establish a vpn connection to the server with, 1-65535"
  type        = number
  default     = 1194
}

variable "web_port" {
  description = "Port number which openvpn website wil be hosted on"
  type        = number
  default     = 443
}

variable "admin_port" {
  description = "Port number which openvpn admin website wil be hosted on"
  type        = number
  default     = 943
}

variable "vpn_private_network_cidrs" {
  description = "Private network cidr which clients will be able to access, typically your VPC cidr"
  type        = list(string)
  default     = []
}

variable "openvpn_secret_manager_credentials_arn" {
  description = "ARN of AWS Secret Manager secret that contains ths password to use for openvpn admin user"
  default     = ""
  type        = string
}

variable "permissions_boundary" {
  description = "Permissions boundary that will be added to the created roles."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to include"
  default     = {}
}

variable "extra_iam_policy_arns" {
  description = "Extra IAM policies to include (e.g cloudwatch, session manager)"
  default     = []
}

## NACL

variable "nacl_udp_port_allow_list" {

  type = map(object({
    nacl_id     = string,
    rule_number = number
  }))
  description = "Creating NACL rules for openvpn UDP connection"
  default     = {}
}

## RDS

variable "rds_fqdn" {
  description = "Hostname of RDS"
  default     = ""
  type        = string
}

variable "rds_secret_manager_credentials_arn" {
  description = "ARN of AWS Secret Manager secret that contains ths password to use to connect to RDS with"
  default     = ""
  type        = string
}

variable "rds_secret_manager_id" {
  description = "Path of AWS Secret Manager secret that contains ths password to use to connect to RDS with"
  default     = ""
  type        = string
}

variable "use_rds" {
  description = "Toggle to use RDS or local sqlite db"
  type        = bool
  default     = false
}