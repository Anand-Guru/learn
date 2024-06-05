output "endpoint" {
  value = aws_eks_cluster.aws_cluster.endpoint
}

output "certificate-authority" {
  value = aws_eks_cluster.aws_cluster.certificate_authority[0].data
}
output "openID" {
  value = aws_eks_cluster.aws_cluster.identity[0].oidc[0].issuer
}

# output "local" {
#   value = local.id_for_policy
# }

# output "tls_certificate" {
#   value = data.tls_certificate.certificate
# }

output "test" {
  value = data.tls_certificate.certificate.certificates.0.sha1_fingerprint
}