# C:\AMZMall_Dev_GitOps\terraform\examples\complete\karpenter.tf
resource "aws_iam_role" "karpenter_node_role" {
  name = "KarpenterNodeRole-${var.infra_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_node_policy_attachment" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_instance_profile" "karpenter_node_instance_profile" {
  name = "KarpenterNodeInstanceProfile-${var.infra_name}"
  role = aws_iam_role.karpenter_node_role.name
}


# Karpenter IAM Policy
resource "aws_iam_policy" "karpenter_iam_policy" {
  name        = "karpenter_iam_policy-${var.infra_name}"
  description = "Karpenter policy for cluster management and EC2 autoscaling"
  policy      = file("${path.module}/policy/karpenter_iam_policy.json")
}

# Karpenter IAM Role
resource "aws_iam_role" "karpenter_iam_role" {
  name = "karpenter-irsa-role-${var.infra_name}"

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
            "${module.eks.oidc_provider_arn}:sub": "system:serviceaccount:kube-system:karpenter"
          }
        }
      }
    ]
  })

  tags = {
    "Name" = "karpenter-irsa-role-${var.infra_name}"
  }
}

resource "aws_iam_role_policy_attachment" "karpenter_iam_role_attach" {
  role       = aws_iam_role.karpenter_iam_role.name
  policy_arn = aws_iam_policy.karpenter_iam_policy.arn
}

# Karpenter 서비스 계정 생성
resource "kubernetes_service_account" "karpenter_service_account" {
  metadata {
    name        = "karpenter"
    namespace   = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter_iam_role.arn
    }
  }
}
# Karpenter Helm Release
resource "helm_release" "karpenter" {
  name       = "karpenter"
  namespace  = "kube-system"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "aws.defaultInstanceProfile" # 이 설정은 Karpenter가 사용할 기본 인스턴스 프로파일을 지정합니다.
    value = "amzdraw-karpenter-instanceProfile" # 적절한 인스턴스 프로파일 이름으로 교체하세요.
  }

  # 서비스 계정 설정
  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.karpenter_service_account.metadata[0].name
  }

  depends_on = [aws_iam_role_policy_attachment.karpenter_iam_role_attach]
}
