# C:\Users\user\Documents\GitHub\AMZMall_Dev_GitOps\terraform\examples\complete\logging.tf
# IAM Policy for Fluent Bit to send logs to CloudWatch
resource "aws_iam_policy" "fluent_bit_cloudwatch_policy" {
  name        = "FluentBitCloudWatchPolicy-${var.cluster_name}"
  description = "Allow Fluent Bit to create and write to CloudWatch Logs"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      Effect   = "Allow",
      Resource = "*"
    }]
  })
}

# IAM Role for the Fluent Bit Service Account
resource "aws_iam_role" "fluent_bit_service_account_role" {
  name = "FluentBitServiceAccountRole-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity",
      Effect = "Allow",
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"
      },
      Condition = {
        StringEquals = {
          "${data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer}:sub": "system:serviceaccount:logging:fluent-bit-service-account"
        }
      }
    }]
  })

  tags = {
    "Name" = "FluentBitIAMRole-${var.cluster_name}"
  }
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "fluent_bit_cloudwatch_policy_attachment" {
  role       = aws_iam_role.fluent_bit_service_account_role.name
  policy_arn = aws_iam_policy.fluent_bit_cloudwatch_policy.arn
}

# Kubernetes Namespace for Logging
resource "kubernetes_namespace" "logging" {
  metadata {
    name = "logging"
  }
}

# Kubernetes Service Account for Fluent Bit
resource "kubernetes_service_account" "fluent_bit_service_account" {
  metadata {
    name      = "fluent-bit-service-account"
    namespace = kubernetes_namespace.logging.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.fluent_bit_service_account_role.arn
    }
  }
}

# Deploy Fluent Bit using Helm
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
