# # C:\Users\user\Documents\GitHub\AMZMall_Dev_GitOps\terraform\examples\complete\monitoring.


resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}
# resource "helm_release" "kube_prometheus_stack" {
#   name       = "kube-prometheus-stack"
#   repository = "https://prometheus-community.github.io/helm-charts"
#   chart      = "kube-prometheus-stack"
#   namespace  = "monitoring"

#   set {
#     name  = "grafana.enabled"
#     value = "true"
#   }

#   set {
#     name  = "prometheus.enabled"
#     value = "true"
#   }
#     set {
#     name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
#     value = "gp3"
#   }

#   set {
#     name  = "grafana.persistence.storageClassName"
#     value = "gp3"
#   }
#     set {
#     name  = "grafana.persistence.size"
#     value = "1Gi"
#   }
#     set {
#     name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
#     value = "1Gi"
#   }

# }

# prometheus, grafana 설치
resource "helm_release" "kube-prometheus-stack" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"

  depends_on = [ null_resource.update_storageclass ]
}
