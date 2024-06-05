resource "aws_iam_role" "iam_role_cluster" {
  name = var.cluster_role_name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "eks.amazonaws.com"
          ]
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}
# 

#
resource "aws_iam_role_policy_attachment" "EKScluster_policy" {
  role       = aws_iam_role.iam_role_cluster.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

  depends_on = [aws_iam_role.iam_role_cluster]
}

resource "aws_iam_role_policy_attachment" "AmazonEBSCSIDriverPolicy" {
  role       = aws_iam_role.iam_role_cluster.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"

  depends_on = [aws_iam_role.iam_role_cluster]
}

#vpc

# data "aws_vpc" "selected" {
#   id         = var.vpc_id
#   cidr_block = var.cidr_block
# }
# data "aws_subnet" "example1" {

#   id = var.subnet_id1

# }



#security Group

resource "aws_security_group" "eks_securtiy_group" {
  name        = var.sg_name
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id = var.vpc_id



}

resource "aws_vpc_security_group_ingress_rule" "inbound" {
  security_group_id = aws_security_group.eks_securtiy_group.id
  cidr_ipv4         = var.cidr_block
  from_port         = var.inbound_port
  ip_protocol       = "tcp"
  to_port           = var.inbound_port

  depends_on = [aws_security_group.eks_securtiy_group]
}

resource "aws_vpc_security_group_egress_rule" "outbound" {
  security_group_id = aws_security_group.eks_securtiy_group.id
  cidr_ipv4         = var.outbound_cidr_ipv4
  ip_protocol       = "-1" # semantically equivalent to all ports
  depends_on        = [aws_security_group.eks_securtiy_group]
}






resource "aws_eks_cluster" "aws_cluster" {
  name                      = var.cluster_name
  role_arn                  = aws_iam_role.iam_role_cluster.arn
  enabled_cluster_log_types = var.cluster_log_types
  version                   = var.cluster_version




  vpc_config {
    subnet_ids              = [var.subnet_id1,var.subnet_id2]
    endpoint_private_access = var.private_acces_endpoint
    endpoint_public_access  = var.public_acces_endpoint
    security_group_ids      = [aws_security_group.eks_securtiy_group.id]

    public_access_cidrs = ["0.0.0.0/0"]
  }

  access_config {
    authentication_mode                         = var.authentatication_mode
    bootstrap_cluster_creator_admin_permissions = var.bootstrap_cluster_creator_admin_permissions
  }

  kubernetes_network_config {
    ip_family         = var.ip_family
    service_ipv4_cidr = null
  }


  depends_on = [aws_iam_role.iam_role_cluster]
}

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name                = aws_eks_cluster.aws_cluster.name
  addon_name                  = "eks-pod-identity-agent"
  addon_version               = "v1.2.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  depends_on                  = [aws_eks_cluster.aws_cluster]
}


resource "aws_eks_addon" "kube-proxy" {
  cluster_name                = aws_eks_cluster.aws_cluster.name
  addon_name                  = "kube-proxy"
  addon_version               = "v1.29.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  depends_on                  = [aws_eks_addon.vpc_cni]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.aws_cluster.name
  addon_name                  = "vpc-cni"
  addon_version               = "v1.16.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.node_group]
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.aws_cluster.name
  addon_name                  = "coredns"
  addon_version               = "v1.11.1-eksbuild.4"
  resolve_conflicts_on_create = "OVERWRITE"
  depends_on                  = [aws_eks_addon.kube-proxy]
}



resource "aws_iam_role" "iam_role_for_NG" {
  name = var.NG_iam_name
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "eks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      },
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ec2.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "container_registry" {
  role       = aws_iam_role.iam_role_for_NG.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"

}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  role       = aws_iam_role.iam_role_for_NG.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"

}


resource "aws_iam_role_policy_attachment" "node_policy" {
  role       = aws_iam_role.iam_role_for_NG.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"

}


resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.aws_cluster.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.iam_role_for_NG.arn
  subnet_ids      = [var.subnet_id1,var.subnet_id2]


  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1

  }

  update_config {
    max_unavailable = 1
  }
  ami_type       = var.ami_type
  disk_size      = var.disk_size
  instance_types = [var.instance_types]
  capacity_type  = var.capacity_type

  depends_on = [aws_iam_role.iam_role_for_NG]
}




resource "null_resource" "cluster-2" {

  provisioner "local-exec" {
   command = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.aws_cluster.name}"
  }
  depends_on = [ aws_eks_node_group.node_group ]
}

resource "time_sleep" "wait_30_second" {
  depends_on = [null_resource.cluster-2]

  create_duration = "60s"
}

# resource "kubernetes_namespace" "namespace" {
#   for_each = var.namespace
#   metadata {
    
#     name = each.value

#   }
#   depends_on = [ aws_eks_node_group.node_group , null_resource.cluster-2 ,time_sleep.wait_30_second]
# }




data "tls_certificate" "certificate" {
  url        = aws_eks_cluster.aws_cluster.identity[0].oidc[0].issuer
  depends_on = [aws_eks_cluster.aws_cluster]

}

resource "aws_iam_openid_connect_provider" "default" {
  url = aws_eks_cluster.aws_cluster.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [data.tls_certificate.certificate.certificates.0.sha1_fingerprint]
  depends_on = [ aws_eks_cluster.aws_cluster , data.tls_certificate.certificate ]
}

data "aws_iam_policy_document" "example_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.default.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:efs-csi-*"]
    }
    condition {
        test   = "StringLike"
      variable = "${replace(aws_iam_openid_connect_provider.default.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.default.arn]
      type        = "Federated"
    }
  }
  depends_on = [ aws_iam_openid_connect_provider.default ]
}

resource "aws_iam_role" "efs-iam" {
  assume_role_policy = data.aws_iam_policy_document.example_assume_role_policy.json
  name               = "efs-iam"
  depends_on = [ data.aws_iam_policy_document.example_assume_role_policy ]
}

resource "aws_iam_role_policy_attachment" "example" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
  role       = aws_iam_role.efs-iam.name
  depends_on = [ aws_iam_role.efs-iam ]
}

resource "aws_eks_addon" "efs_csi_driver" {
  cluster_name = aws_eks_cluster.aws_cluster.name
  addon_name = "aws-efs-csi-driver"
  addon_version = "v2.0.2-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  service_account_role_arn = aws_iam_role.efs-iam.arn
  
  depends_on = [  aws_eks_cluster.aws_cluster, aws_eks_node_group.node_group, aws_iam_role.efs-iam ]

}

resource "kubernetes_service_account" "test2" {
  metadata {
    name = "efs-csi-sa"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.efs-iam.arn
    }
  }
  depends_on = [ aws_eks_addon.efs_csi_driver ]
}


