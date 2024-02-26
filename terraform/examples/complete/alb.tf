# OIDC Provider for the EKS Cluster
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

# IAM Role for AWS Load Balancer Controller
resource "aws_iam_role" "aws_lb_controller_role" {
  name = "${var.cluster_name}-aws-lb-controller-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRoleWithWebIdentity",
      Effect    = "Allow",
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer}"
      },
      Condition = {
        StringEquals = {
          "${data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })

  tags = {
    "Name" = "${var.cluster_name}-aws-lb-controller-role"
  }
}

# Custom IAM Policy for AWS Load Balancer Controller
resource "aws_iam_policy" "aws_lb_controller_policy_custom" {
  name        = "aws_lb_controller_policy_custom-${var.infra_name}"
  description = "Custom Load Balancer Controller policy"
  policy      = file("${path.module}/policy/alb_iam_policy.json")
}

# IAM policy attachment for AWS Load Balancer Controller
resource "aws_iam_role_policy_attachment" "aws_lb_controller_policy_attachment" {
  role       = aws_iam_role.aws_lb_controller_role.name
  policy_arn = aws_iam_policy.aws_lb_controller_policy_custom.arn
}

# Kubernetes Service Account for AWS Load Balancer Controller
resource "kubernetes_service_account" "aws_lb_controller_sa" {
  metadata {
    name        = "aws-load-balancer-controller"
    namespace   = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws_lb_controller_role.arn
    }
  }
}

# Helm Release for AWS Load Balancer Controller
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  chart      = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.aws_lb_controller_sa.metadata[0].name
  }
}
