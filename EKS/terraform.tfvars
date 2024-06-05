cluster_role_name        = "ab-test-cluster-role"
cluster_role_policy_name = "ab-eks-cluster-pol"

create_test_role   = "true"
create_test_policy = "true"


vpc_id     = "vpc-0f08ed4df7e581bd7"
cidr_block = "172.30.0.0/16"

subnet_id1 = "subnet-01615365f3ae874a6"
subnet_id2 = "subnet-0dbd9f84a53bc07f4"

sg_name            = "eks_sg"
inbound_port       = 80
outbound_cidr_ipv4 = "0.0.0.0/0"

cluster_name    = "test-eks"
cluster_version = "1.29"

cluster_log_types = ["api", "audit"]

private_acces_endpoint = true
public_acces_endpoint  = true
public_access_cidrs    = "0.0.0.0/0"

authentatication_mode                       = "API_AND_CONFIG_MAP"
bootstrap_cluster_creator_admin_permissions = true

ip_family = "ipv4"

NG_iam_name = "iam_node_group"

node_group_name ="test_node_group"

ami_type = "AL2_x86_64"
disk_size      = 20
instance_types = "t3.small"
capacity_type  = "ON_DEMAND"

region = "us-west-2"

account_id ="562922379100"
