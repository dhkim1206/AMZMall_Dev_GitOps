# C:\AMZMall_Dev_GitOps\terraform\examples\complete\ca.tf
# CA IAM Role을 위한 정책 설정
resource "aws_iam_policy" "ca_iam_policy" {
  name        = "ca_iam_policy-${var.infra_name}"
  description = "ca policy"
  policy      = file("${path.module}/policy/ca_iam_policy.json")
}

data "aws_iam_policy_document" "ca_assume_role_policy" {
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
      values = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }
  }
}

resource "aws_iam_role" "ca_iam_role" {
  name = "${var.cluster_name}-ca-role"

  assume_role_policy = data.aws_iam_policy_document.ca_assume_role_policy.json


  tags = {
    "Name" = "${var.cluster_name}-ca-role"
  }
}



resource "aws_iam_role_policy_attachment" "ca_iam_policy_attach" {
  role       = aws_iam_role.ca_iam_role.name
  policy_arn = aws_iam_policy.ca_iam_policy.arn
}

# Metrics Server Helm Release
resource "helm_release" "metrics_server" {
  namespace  = "kube-system"
  name       = "metrics-server"
  chart      = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
}

resource "kubernetes_service_account" "cluster_autoscaler" {
  metadata {
    name        = "cluster-autoscaler"
    namespace   = "kube-system"
    annotations = {"eks.amazonaws.com/role-arn" = aws_iam_role.ca_iam_role.arn}
  }
}

# # Cluster Autoscaler Helm Release
# resource "helm_release" "cluster_autoscaler" {
#   name       = "cluster-autoscaler"
#   namespace  = "kube-system"
#   chart      = "cluster-autoscaler"
#   repository = "https://kubernetes.github.io/autoscaler"

#   set {
#     name  = "autoDiscovery.clusterName"
#     value = var.cluster_name
#   }

#   set {
#     name  = "awsRegion"
#     value = var.aws_region
#   }

#   set {
#     name  = "rbac.serviceAccount.create"
#     value = "false"
#   }

#   set {
#     name  = "rbac.serviceAccount.name"
#     value = kubernetes_service_account.cluster_autoscaler.metadata[0].name
#   }

#   set {
#     name  = "rbac.serviceAccount.annotations.eks.amazonaws.com/role-arn"
#     value = aws_iam_role.ca_iam_role.arn
#   }

#   values = [file("${path.module}/values/ca-values.yaml")]
# }