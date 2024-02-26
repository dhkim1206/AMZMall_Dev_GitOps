# CA IAM Role을 위한 정책 설정
resource "aws_iam_policy" "ca_iam_policy" {
  name        = "ca_iam_policy-${var.infra_name}"
  description = "CA policy for Cluster Autoscaler"
  policy      = file("${path.module}/policy/ca_iam_policy.json")
}

# CA IAM Role 생성
resource "aws_iam_role" "ca_iam_role" {
  name = "ca-irsa-role-${var.infra_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "${module.eks.oidc_provider_arn}"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider_arn}:sub": "system:serviceaccount:kube-system:aws-cluster-autoscaler"
          }
        }
      }
    ]
  })

  tags = {
    "Name" = "ca-irsa-role-${var.infra_name}"
  }
}

resource "aws_iam_role_policy_attachment" "ca_iam_role_attach" {
  role       = aws_iam_role.ca_iam_role.name
  policy_arn = aws_iam_policy.ca_iam_policy.arn
}


# Metrics Server Helm Release
resource "helm_release" "metrics_server" {
  namespace  = "kube-system"
  name       = "metrics-server"
  chart      = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"

  # AWS Load Balancer Controller에 의존합니다.
  depends_on = [helm_release.aws_load_balancer_controller]
}

# aws-cluster-autoscaler 서비스 계정 생성
resource "kubernetes_service_account" "aws_cluster_autoscaler" {
  metadata {
    name        = "aws-cluster-autoscaler"
    namespace   = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.ca_iam_role.arn
    }
  }
}

# Cluster Autoscaler Helm Release
resource "helm_release" "cluster_autoscaler" {
  name       = "aws-cluster-autoscaler"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"

  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.aws_region
  }

  set {
    name  = "rbac.serviceAccount.create"
    value = "false"
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = kubernetes_service_account.aws_cluster_autoscaler.metadata[0].name
  }
}
