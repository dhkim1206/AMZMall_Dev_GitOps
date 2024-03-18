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

  values = [file("${path.module}/values/loki-values.yaml")]
}
