module "openvpn" {
  name = "my-openvpn"
  ssh_allowed_ips = {
    gcc-jumphost = {
      name    = "gcc-jumphost"
      ip_addr = ["10.100.100.0/25"]
    }
  }

  admin_allowed_ips = {
    vpn-cidr = {
      name    = "vpn-cidr"
      ip_addr = ["100.100.100.0/22"]
    }
    #Initial access for admin on internet, as we are not connected yet
    #remove after setting up successfully and you(admin) are connected to the vpn
    init-public-cidr = {
      name    = "init-public-cidr"
      ip_addr = ["0.0.0.0/0"]
    }
  }

  conn_allowed_ips = {
    #useful if you want to disable public access, and only allow certain internet IPs
    #to make a vpn client connection to your server
    my-house = {
      name    = "my-house"
      ip_addr = ["256.256.256.256/32"]
    }
  }

  web_allowed_ips = {
    #useful if you want to disable public access, and only allow certain internet IPs
    #to see your client web server
    my-house = {
      name    = "my-house"
      ip_addr = ["256.256.256.256/32"]
    }
  }

  # Creates the required NACL rules for connection
  nacl_udp_port_allow_list = {
    public-acl = {
      nacl_id = "acl-xx"
      rule_number = 141
    }
    private-acl = {
      nacl_id = "acl-yy"
      rule_number = 145
    }
  }

  openvpn_hostname          = "example-connection.com"
  openvpn_pool_ip           = "172.40.200.0/22"
  openvpn_ami_id            = "ami-xx"
  domain_name               = "example.com"
  route53_zone_id           = "Z0000000000"
  vpc_id                    = "vpc-xx"
  s3_bucket_access_logs     = "my-bucket"
  public_subnet_ids         = ["subnet-xxx"]
  private_subnet_ids        = ["subnet-yyy"]
  key_name                  = "my-ssh-key-pair"

  permissions_boundary = "arn:aws:iam::1234678:policy/GCCIAccountBoundary"

  # Secondary cidrs of both management and application vpcs
  vpn_private_network_cidrs = [
    "172.111.111.0/22"
  ]

  rds_fqdn                           = "rds.amazon.com"
  rds_secret_manager_credentials_arn = "arn::xxx:secret:my-secret-XXX"
  use_rds                            = true
}