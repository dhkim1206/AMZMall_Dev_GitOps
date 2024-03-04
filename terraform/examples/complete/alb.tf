# EKS 클러스터 정보를 가져옵니다. 이 데이터는 OIDC Provider 생성 및 IAM 역할 정의에 사용됩니다.
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name # EKS 클러스터의 이름을 변수에서 가져옵니다.
}

# EKS 클러스터의 인증 정보를 가져옵니다. 이 정보는 클러스터와의 상호작용에 필요합니다.
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name # 위와 동일하게 EKS 클러스터의 이름을 지정합니다.
}

# EKS 클러스터를 위한 IAM OIDC Identity Provider를 생성합니다.
# OIDC Provider는 Kubernetes 서비스 계정과 AWS IAM 역할을 연결하는 데 사용됩니다.
# resource "aws_iam_openid_connect_provider" "oidc_provider" {
#   client_id_list  = ["sts.amazonaws.com"] # EKS 클러스터에서 발급한 토큰을 인증하는 데 사용되는 서비스입니다.
#   thumbprint_list = [data.aws_eks_cluster.cluster.identity.0.oidc.0.thumbprint] # OIDC의 SSL 인증서 지문입니다.
#   url             = data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer # OIDC 발급자 URL입니다.
# }

# AWS Load Balancer Controller를 실행할 Kubernetes 서비스 계정에 부여할 IAM 역할을 생성합니다.
resource "aws_iam_role" "aws_lb_controller_role" {
  name = "${var.cluster_name}-aws-lb-controller-role" # 역할의 이름을 정의합니다.

  # 이 역할을 가진 엔티티가 sts:AssumeRoleWithWebIdentity 액션을 사용할 수 있도록 합니다.
  # 이 정책은 EKS 클러스터의 OIDC Provider를 통해 발급된 토큰을 기반으로 역할을 맡을 수 있게 합니다.
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
    "Name" = "${var.cluster_name}-aws-lb-controller-role" # 역할에 태그를 추가합니다.
  }
}

# AWS Load Balancer Controller에 필요한 권한을 정의한 사용자 정의 IAM 정책을 생성합니다.
resource "aws_iam_policy" "aws_lb_controller_policy_custom" {
  name        = "aws_lb_controller_policy_custom-${var.infra_name}" # 정책의 이름을 정의합니다.
  description = "Custom Load Balancer Controller policy" # 정책에 대한 설명을 추가합니다.
  policy      = file("${path.module}/policy/alb_iam_policy.json") # 정책 내용을 파일에서 불러옵니다.
}

# 생성된 IAM 정책을 IAM 역할에 연결합니다.
resource "aws_iam_role_policy_attachment" "aws_lb_controller_policy_attachment" {
  role       = aws_iam_role.aws_lb_controller_role.name # 위에서 생성한 IAM 역할을 지정합니다.
  policy_arn = aws_iam_policy.aws_lb_controller_policy_custom.arn # 위에서 생성한 IAM 정책을 지정합니다.
}

# AWS Load Balancer Controller를 실행할 Kubernetes 서비스 계정을 생성합니다.
# 이 서비스 계정은 위에서 생성한 IAM 역할과 연동됩니다.
resource "kubernetes_service_account" "aws_lb_controller_sa" {
  metadata {
    name        = "aws-load-balancer-controller" # 서비스 계정의 이름을 지정합니다.
    namespace   = "kube-system" # 서비스 계정이 위치할 네임스페이스를 지정합니다.
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws_lb_controller_role.arn # 서비스 계정에 IAM 역할의 ARN을 연결합니다.
    }
  }
}

# Helm을 사용하여 AWS Load Balancer Controller를 EKS 클러스터에 배포합니다.
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller" # 배포할 Helm release의 이름을 지정합니다.
  namespace  = "kube-system" # Helm chart가 배포될 네임스페이스를 지정합니다.
  chart      = "aws-load-balancer-controller" # 사용할 Helm chart의 이름을 지정합니다.
  repository = "https://aws.github.io/eks-charts" # Helm chart가 위치한 저장소의 URL을 지정합니다.

  set {
    name  = "clusterName"
    value = module.eks.cluster_name # EKS 클러스터의 이름을 Helm chart에 전달합니다.
  }

  set {
    name  = "serviceAccount.create"
    value = "false" # Helm chart가 서비스 계정을 생성하지 않도록 합니다. Terraform이 이미 생성했습니다.
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.aws_lb_controller_sa.metadata[0].name # 사용할 Kubernetes 서비스 계정의 이름을 지정합니다.
  }
}
