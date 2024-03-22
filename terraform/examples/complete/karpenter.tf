# Karpenter IAM 정책 설정
resource "aws_iam_policy" "karpenter_iam_policy" {
  name        = "karpenter_iam_policy-${var.infra_name}"
  description = "Karpenter policy"
  policy      = file("${path.module}/policy/karpenter_iam_policy.json")
}

data "aws_iam_policy_document" "karpenter_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect = "Allow"
    principals {
      type = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"]
    }
    condition {
      test = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values = ["system:serviceaccount:kube-system:karpenter"]
    }
  }
}

resource "aws_iam_role" "karpenter_iam_role" {
  name = "${var.cluster_name}-karpenter-role"

  assume_role_policy = data.aws_iam_policy_document.karpenter_assume_role_policy.json

  tags = {
    "Name" = "${var.cluster_name}-karpenter-role"
  }
}

resource "aws_iam_role_policy_attachment" "karpenter_iam_policy_attach" {
  role       = aws_iam_role.karpenter_iam_role.name
  policy_arn = aws_iam_policy.karpenter_iam_policy.arn
}

# Karpenter 서비스 계정 설정
resource "kubernetes_service_account" "karpenter_service_account" {
  metadata {
    name        = "karpenter"
    namespace   = "kube-system"
    annotations = {"eks.amazonaws.com/role-arn" = aws_iam_role.karpenter_iam_role.arn}
  }
}

# Karpenter Helm Release 설정
resource "helm_release" "karpenter" {
  namespace  = "kube-system"
  name       = "karpenter"
  chart      = "karpenter"
  repository = "https://charts.karpenter.sh"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "aws.defaultInstanceProfile"
    value = "your-instance-profile-name" # 적절한 인스턴스 프로필 이름으로 변경하세요.
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.karpenter_service_account.metadata[0].name
  }

  depends_on = [aws_iam_role_policy_attachment.karpenter_iam_policy_attach]
}
