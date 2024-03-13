# IAM (Identity and Access Management): 
# AWS에서 사용자, 서비스, 그리고 리소스에 대한 액세스를 관리하는 서비스.
# IAM 정책은 JSON 형태로 특정 권한을 세부적으로 정의. 어떤 AWS 서비스나 리소스에 대한 액세스 권한을 부여할지 결정.

# OIDC (OpenID Connect): 
# 인증을 위한 개방형 표준 프로토콜.
# EKS 클러스터는 AWS에서 OIDC 공급자를 생성할 수 있으며, 
# EKS 내의 서비스 계정에 AWS 리소스에 대한 액세스를 위임할 수 있다

# IRSA (IAM Roles for Service Accounts): 
# EKS에서 실행되는 컨테이너화된 애플리케이션들이 AWS 리소스에 액세스할 때 사용하는 메커니즘.
# Kubernetes 서비스 계정과 AWS IAM 역할을 연결하여, 해당 애플리케이션이 필요한 AWS API를 호출할 수 있게 해준다.

# EKS 클러스터에 OIDC 공급자가 설정되고, 이 공급자를 통해 IAM 역할을 가정할 수 있는 자격 증명을 생성할 수 있다.
# sts:AssumeRoleWithWebIdentity 액션을 통해 이루어진다.

# aws_iam_policy_document에서 OIDC 공급자를 Federated 주체로 지정하고,
# sts:AssumeRoleWithWebIdentity 액션을 사용하여 특정 서비스 계정이 특정 IAM 역할을 가정할 수 있도록 한다.

# 이때 condition 블록이 중요한 역할을 합니다. 
# StringEquals 조건은 서비스 계정의 sub (subject)과 OIDC 토큰의 클레임이 일치할 때만 IAM 역할을 가정할 수 있게 제한합니다.
# 즉, 특정 Kubernetes 서비스 계정이 IAM 역할을 가정할 수 있도록 세부적으로 제어합니다.

# Kubernetes 서비스 계정은 annotations를 통해 특정 IAM 역할의 ARN을 연결합니다.
#  이 어노테이션은 EKS 클러스터에서 컨테이너가 실행될 때 AWS의 자격 증명을 자동으로 얻을 수 있도록 합니다.

# 마지막으로, 서비스 계정을 사용하는 컨테이너화된 애플리케이션이 있으면,
#  해당 애플리케이션이 AWS API를 호출할 때, Kubernetes가 OIDC 토큰을 사용하여 애플리케이션에게 IAM 역할을 가정할 수 있는 자격 증명을 제공합니다.


# EBS CSI 드라이버가 AWS의 리소스에 접근하기 위해 사용하는 역할을 위임 받을 때 필요한 정책을 정의
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    # "sts:AssumeRoleWithWebIdentity" 액션을 허용. 이는 특정 역할을 가정할 수 있게 한다
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect = "Allow"
    principals {
      # "Federated" 타입의 주체들에게 이 액션을 허용
      # 이 경우, EKS 클러스터가 생성한 OIDC 공급자
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"]
    }

    # 조건을 추가하여 오직 "ebs-csi-controller" 서비스 계정에서만 역할을 가정할 수 있게 제한
    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller"]
    }
  }
}

# Kubernetes 내에서 "ebs-csi-controller"라는 이름의 서비스 계정을 생성
# 이 서비스 계정은 EBS CSI 드라이버가 AWS 리소스에 접근하는데 사용
resource "kubernetes_service_account" "ebs_csi_controller_sa" {
  metadata {
    name        = "ebs-csi-controller"
    namespace   = "kube-system"  # kube-system 네임스페이스에 생성됩니다.
    annotations = {
      # AWS IAM 역할의 ARN을 어노테이션으로 추가. 이 역할은 위에서 정의한 IAM 역할을 참조
      "eks.amazonaws.com/role-arn" = aws_iam_role.ebs_csi_role.arn
    }
  }
}

# 위에서 정의한 정책 문서를 사용하여 IAM 역할을 생성
resource "aws_iam_role" "ebs_csi_role" {
  name = "${var.cluster_name}-ebs-csi-role"

  # 이 역할은 STS Assume Role With Web Identity를 사용하여 가정
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  tags = {
    "Name" = "${var.cluster_name}-ebs-csi-role"
  }
}

# EBS CSI 드라이버가 AWS에서 EBS 볼륨을 관리하는데 필요한 권한을 가진 정책을 생성
resource "aws_iam_policy" "ebs_csi_policy" {
  name        = "${var.cluster_name}-ebs-csi-policy"
  description = "Policy for EBS CSI driver"

  # 정책 내용은 별도의 JSON 파일에서 호출
  policy = file("${path.module}/policy/ebs_csi_policy.json")
}

# 생성된 IAM 정책을 위에서 생성한 IAM 역할에 연결
resource "aws_iam_role_policy_attachment" "ebs_csi_policy_attachment" {
  role       = aws_iam_role.ebs_csi_role.name
  policy_arn = aws_iam_policy.ebs_csi_policy.arn
}

# Helm을 사용하여 EBS CSI 드라이버를 Kubernetes 클러스터에 배포
resource "helm_release" "ebs_csi_driver" {
  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver/"
  chart      = "aws-ebs-csi-driver"
  namespace  = "kube-system"  # kube-system 네임스페이스에 배포됩니다.

  # 기본적으로 생성되는 서비스 계정을 사용하지 않고, 위에서 생성한 서비스 계정을 사용
  set {
    name  = "serviceAccount.controller.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.controller.name"
    value = kubernetes_service_account.ebs_csi_controller_sa.metadata[0].name
  }
}

# EBS 스토리지 클래스를 생성하여 AWS EBS 볼륨을 Kubernetes에서 사용할 수 있게
resource "kubernetes_storage_class" "ebs_storage_class" {
  metadata {
    name = "amzdraw-ebs"
    # 기본 스토리지 클래스로 설정합니다.
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  # AWS EBS 볼륨 프로비저너를 지정
  storage_provisioner = "kubernetes.io/aws-ebs"

  # 스토리지 클래스의 파라미터를 설정. "gp3" 타입의 볼륨을 사용
  parameters = {
    type = "gp3"
  }  

  # 볼륨 삭제 시 복구 정책을 "Retain"으로 설정, 볼륨을 보존
  reclaim_policy = "Retain"
  # 볼륨 바인딩 모드를 "WaitForFirstConsumer"로 설정. 볼륨이 사용될 때까지 기다리게
  volume_binding_mode = "WaitForFirstConsumer"
  # 볼륨 확장을 허용
  allow_volume_expansion = true
}
