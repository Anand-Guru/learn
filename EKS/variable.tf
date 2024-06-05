variable "cluster_role_name" {
  type = string
}
variable "cluster_role_policy_name" {
  type = string
}

variable "create_test_role" {
  type    = bool
  default = true
}
variable "create_test_policy" {
  type    = bool
  default = true
}

# variable "policy_arn" {
#   type    = string
#   default = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
# }


variable "vpc_id" {
  type = string
}

variable "subnet_id1" {
  type = string
}

variable "subnet_id2" {
  type = string
}
variable "cidr_block" {
  type = string
}

variable "inbound" {
  type    = number
  default = 80
}

variable "sg_name" {
  type = string
}
variable "inbound_port" {
  type = number
}

variable "outbound_cidr_ipv4" {
  type = string
  validation {
    condition = var.outbound_cidr_ipv4 == "0.0.0.0/0"
    error_message = "outnound cidr ipv4 should be 0.0.0.0/0"
  }

}
variable "cluster_name" {
  type = string
}
variable "cluster_version" {
  type = string
}

variable "cluster_log_types" {
  type = set(string)
}

variable "private_acces_endpoint" {
  type = bool

  validation {
    condition = var.private_acces_endpoint == true
    error_message = "private_acces_endpoint should be true"
  }
}

variable "public_acces_endpoint" {
  type = bool
  
}
variable "public_access_cidrs" {
  type = string
}
variable "authentatication_mode" {
  type = string
  validation {
    condition = var.authentatication_mode == "API_AND_CONFIG_MAP"
    error_message = "authentatication_mode should be  API_AND_CONFIG_MAP"
  }
}

variable "bootstrap_cluster_creator_admin_permissions" {
  type = bool

  validation {
    condition = var.bootstrap_cluster_creator_admin_permissions == true
    error_message = "bootstrap_cluster_creator_admin_permissions must be true"
  }
}

variable "ip_family" {
  type = string
}
variable "NG_iam_name" {
  type = string
}

variable "node_group_name" {
  type = string
}

variable "node_group_name_2" {
  type = string
  default = "value"
}

variable "ami_type" {
  type = string
}
variable "disk_size" {
  type = number

  validation {
    condition = var.disk_size >= 20 
    error_message = "disk size should be greater or equal to 20"
  }
}
variable "instance_types" {
  type = string

  validation {
    condition = var.instance_types != "t3.micro"
    error_message = "instance type should not be higher that t3.micro "
  }
}
variable "capacity_type" {
  type = string
}

variable "region" {
  type = string
}

variable "namespace" {
  type = set(string)
  default = [ "test" ]
}

variable "account_id" {
  type = any
}