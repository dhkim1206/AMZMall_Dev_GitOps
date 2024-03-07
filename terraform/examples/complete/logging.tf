# C:\AMZMall_Dev_GitOps\terraform\examples\complete\logging.tf
resource "kubernetes_namespace" "logging" {
  metadata {
    name = "logging"
  }
}


resource "helm_release" "fluent_bit" {
  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  namespace  = "logging"

  set {
    name  = "output.cloudwatch.enabled"
    value = "true"
  }

  set {
    name  = "output.cloudwatch.region"
    value = "ap-northeast-2"
  }

  set {
    name  = "output.cloudwatch.log_group_name"
    value = "/aws/eks/fluentbit-logs"
  }

  set {
    name  = "output.cloudwatch.log_stream_prefix"
    value = "fluentbit-"
  }
}
