# OpenVPN

This module setups an openvpn server with 2 load balancers, 1 for user logins for retrieval or profile, and 1 for vpn client connection and admin access

## Design

![Architecture](architecture.png)

## Usage

```
module "ovpn"{
  name = "my-openvpn"

  openvpn_hostname          = "example-connection.com"
  openvpn_pool_ip           = "172.40.200.0/22"
  openvpn_ami_id            = "ami-xxx" # From your openvpn marketplace subscription
  domain_name               = "example.com"
  route53_zone_id           = "xx" # For ACM creation
  vpc_id                    = "vpc-xx"
  s3_bucket_access_logs     = "my-bucket"
  public_subnet_ids         = ["subnet-xxx"]
  private_subnet_ids        = ["subnet-yyy"]
  key_name                  = "my-ssh-key-pair"

  # Your VPC cidr for clients to access private network
  vpn_private_network_cidrs = [
    "172.111.111.0/22"
  ]
}
```

## Notes

### Use RDS

#### Requirements

1. RDS MySQL setup separately
2. RDS username and password in secrets manager with the following key/values
   1. username
   2. password

If you wish to use RDS with this module for backing up your openvpn settings remotely, please note the following

1. certain variables will cause a change in user-data script, this will cause a recreation of your EC2 primary server instance. If you have yet to be connected to the RDS succesfully, this will result in a loss of your current settings (Please see [here](https://openvpn.net/vpn-server-resources/configuration-database-management-and-backups/#change-database-backend-to-mysql-or-amazon-rds) if you are migrating from a local sqlite to rds mysql)
2. When using RDS, a custom user data script will be ran, do take a look at the [template](./vm_openvpn.tpl) before using it to see if it fits your needs
3. This module does not set your linux admin user password as that is not a safe practice. Therefore on initial setup, you have to ssh in to set the admin password before you can manage via the admin web server. Run `passwd openvpn` to set your password in the server

### Autoscaling cluster

> WIP## Requirements

No requirements.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| admin\_allowed\_ips | Map of User and IP for tcp admin\_port admin web | <pre>map(object({<br>    name    = string,<br>    ip_addr = set(string)<br>  }))</pre> | `{}` | no |
| admin\_port | Port number which openvpn admin website wil be hosted on | `number` | `943` | no |
| aws\_region | AWS region. | `string` | `"ap-southeast-1"` | no |
| conn\_allow\_public | Allow public vpn clients to connect to the vpn server? | `bool` | `true` | no |
| conn\_allowed\_ips | Map of User and IP for openvpn connection | <pre>map(object({<br>    name    = string,<br>    ip_addr = set(string)<br>  }))</pre> | `{}` | no |
| conn\_port | Port number which openvpn clients will use to establish a vpn connection to the server with, 1-65535 | `number` | `1194` | no |
| domain\_name | domain name to serve site on | `string` | n/a | yes |
| key\_name | SSH Key pair name | `string` | `""` | no |
| nacl\_udp\_port\_allow\_list | Creating NACL rules for openvpn UDP connection | <pre>map(object({<br>    nacl_id     = string,<br>    rule_number = number<br>  }))</pre> | `{}` | no |
| name | Name prefix for various resources created | `string` | n/a | yes |
| openvpn\_ami\_id | Openvpn AMI id from marketplace subscription | `string` | n/a | yes |
| openvpn\_hostname | openvpn connection url, different from the web url | `string` | n/a | yes |
| openvpn\_pool\_ip | IP Pool range for clients | `string` | `"172.27.200.0/22"` | no |
| openvpn\_secret\_manager\_credentials\_arn | ARN of AWS Secret Manager secret that contains ths password to use for openvpn admin user | `string` | `""` | no |
| permissions\_boundary | Permissions boundary that will be added to the created roles. | `string` | `null` | no |
| private\_subnet\_ids | List of private subnet ids for launch configuration to create ec2 instances in | `list(string)` | n/a | yes |
| public\_subnet\_ids | List of public subnet ids for elastic load balancer | `list(string)` | n/a | yes |
| rds\_fqdn | Hostname of RDS | `string` | `""` | no |
| rds\_secret\_manager\_credentials\_arn | ARN of AWS Secret Manager secret that contains ths password to use to connect to RDS with | `string` | `""` | no |
| rds\_secret\_manager\_id | Path of AWS Secret Manager secret that contains ths password to use to connect to RDS with | `string` | `""` | no |
| route53\_zone\_id | Route53 Zone ID | `string` | `""` | no |
| s3\_bucket\_access\_logs | S3 bucket for storing access logs | `string` | n/a | yes |
| s3\_prefix | Prefix for access logs if you want to change the object folder. remember to add a prevailing '/' e.g 'nlb/ | `string` | `""` | no |
| ssh\_allowed\_ips | Map of User and IP for ssh | <pre>map(object({<br>    name    = string,<br>    ip_addr = set(string)<br>  }))</pre> | n/a | yes |
| tags | Tags to include | `map` | `{}` | no |
| use\_rds | Toggle to use RDS or local sqlite db | `bool` | `false` | no |
| vpc\_id | VPC ID | `string` | n/a | yes |
| vpn\_private\_network\_cidrs | Private network cidr which clients will be able to access, typically your VPC cidr | `list(string)` | `[]` | no |
| web\_allow\_public | Allow public to access the web UI? | `bool` | `true` | no |
| web\_allowed\_ips | Map of User and IP for tcp 443 web | <pre>map(object({<br>    name    = string,<br>    ip_addr = set(string)<br>  }))</pre> | `{}` | no |
| web\_port | Port number which openvpn website wil be hosted on | `number` | `443` | no |

## Outputs

| Name | Description |
|------|-------------|
| acm\_arn | n/a |
| acm\_domain\_name | n/a |
| asg\_arn | n/a |
| aws\_lb\_connection\_arn | n/a |
| aws\_lb\_connection\_dns | n/a |
| aws\_lb\_web\_arn | n/a |
| aws\_lb\_web\_dns | n/a |
| instance\_primary\_arn | n/a |
| instance\_profile\_arn | n/a |
| instance\_root\_block\_id | n/a |
| launch\_configuration\_arn | n/a |
| security\_group\_id\_connection | n/a |
| security\_group\_id\_ec2 | n/a |
| security\_group\_id\_web | n/a |

