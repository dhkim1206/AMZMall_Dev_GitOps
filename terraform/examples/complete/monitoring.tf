# C:\AMZMall_Dev_GitOps\terraform\examples\complete\monitoring.tf

locals {
  oidc_provider = replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")
}

resource "aws_iam_policy" "loki_iam_policy" {
  name        = "AWSS3EksLokiAccess-${var.infra_name}"
  description = "Policy for Loki to access S3"
  policy      = file("${path.module}/policy/loki_iam_policy.json")
}

resource "aws_iam_role" "loki_iam_role" {
  name               = "AmazonEKS-Loki-Role-${var.infra_name}"
  assume_role_policy = data.aws_iam_policy_document.loki_assume_role_policy.json
  tags = {
    "Name" = "AmazonEKS-Loki-Role-${var.infra_name}"
  }
}

data "aws_iam_policy_document" "loki_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_provider}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:sub"
      values   = ["system:serviceaccount:monitoring:loki-sa"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "loki_iam_policy_attachment" {
  role       = aws_iam_role.loki_iam_role.name
  policy_arn = aws_iam_policy.loki_iam_policy.arn
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_service_account" "loki_service_account" {
  metadata {
    name        = "loki-sa"
    namespace   = "monitoring"
    annotations = {"eks.amazonaws.com/role-arn" = aws_iam_role.loki_iam_role.arn}
  }
}

resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-distributed"
  namespace  = "monitoring"

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.loki_service_account.metadata[0].name
  }
  set {
    name  = "global.labels.app"
    value = "loki"
  }

  values = [file("${path.module}/values/loki-values.yaml")]
}


# promtail 배포
resource "helm_release" "promtail" {
  name       = "promtail"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  namespace  = "monitoring"

  values = [file("${path.module}/values/promtail-values.yaml")]
}

# prometheus, grafana 설치
resource "helm_release" "prometheus_grafana" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"

}

# grafana
resource "kubernetes_ingress_v1" "grafana_ingress" {
  metadata {
    name        = "grafana-ingress"
    namespace   = "monitoring"
    annotations = {
      "kubernetes.io/ingress.class"               = "alb"
      "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
      "alb.ingress.kubernetes.io/listen-ports"    = jsonencode([{"HTTPS": 443},{"HTTP": 80}])
      "alb.ingress.kubernetes.io/certificate-arn" = "arn:aws:acm:ap-northeast-2:009946608368:certificate/f44c8be0-432d-4e90-934a-aa3d768c9ace"
      "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
    }
  }

  spec {
    rule {
      host = "grafana.amzdraw.shop"
      http {
        path {
          path = "/*"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "prometheus-grafana"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
  depends_on = [ helm_release.prometheus_grafana ]
}
