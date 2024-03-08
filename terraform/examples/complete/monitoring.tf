# # C:\Users\user\Documents\GitHub\AMZMall_Dev_GitOps\terraform\examples\complete\monitoring.


resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# prometheus, grafana 설치
resource "helm_release" "kube-prometheus-stack" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"

}

