# C:\Users\user\Documents\GitHub\AMZMall_Dev_GitOps\terraform\examples\complete\logging.tf
# IAM 정책 문서 정의: Fluent Bit가 AWS CloudWatch Logs에 로그를 보낼 때 필요한 권한 부여
data "aws_iam_policy_document" "fluent_bit_cloudwatch_policy_doc" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups"
    ]
    effect   = "Allow"
    resources = ["*"]
  }
}

# IAM 정책 생성: 정책 문서를 기반으로 실제 IAM 정책 리소스 생성
resource "aws_iam_policy" "fluent_bit_cloudwatch_policy" {
  name        = "FluentBitCloudWatchPolicy-${var.cluster_name}"
  description = "Allow Fluent Bit to create and write to CloudWatch Logs"
  policy      = data.aws_iam_policy_document.fluent_bit_cloudwatch_policy_doc.json
}

# IAM 역할 생성: EKS 서비스 계정이 가정할 IAM 역할
resource "aws_iam_role" "fluent_bit_service_account_role" {
  name = "FluentBitServiceAccountRole-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect  = "Allow",
      Action  = "sts:AssumeRoleWithWebIdentity",
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"
      },
      Condition = {
        StringEquals = {
          "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub": "system:serviceaccount:logging:fluent-bit-service-account"
        }
      }
    }]
  })

  tags = {
    "Name" = "FluentBitIAMRole-${var.cluster_name}"
  }
}

# IAM 역할과 정책 연결
resource "aws_iam_role_policy_attachment" "fluent_bit_cloudwatch_policy_attachment" {
  role       = aws_iam_role.fluent_bit_service_account_role.name
  policy_arn = aws_iam_policy.fluent_bit_cloudwatch_policy.arn
}

# Kubernetes 네임스페이스 생성: 로깅용
resource "kubernetes_namespace" "logging" {
  metadata {
    name = "logging"
  }
}

# Kubernetes 서비스 계정 생성: Fluent Bit용, AWS IAM 역할과 연결됨
resource "kubernetes_service_account" "fluent_bit_service_account" {
  metadata {
    name      = "fluent-bit-service-account"
    namespace = kubernetes_namespace.logging.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.fluent_bit_service_account_role.arn
    }
  }
}

# Helm을 사용하여 Fluent Bit 배포
resource "helm_release" "fluent_bit" {
  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  namespace  = kubernetes_namespace.logging.metadata[0].name

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.fluent_bit_service_account.metadata[0].name
  }

  values = [templatefile("${path.module}/values/fluentbit-values.yaml", {
    log_group_name    = "/aws/eks/${var.cluster_name}/fluentbit-logs",
    log_stream_prefix = "fluentbit-"
  })]
}
