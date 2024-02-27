# C:\AMZMall_Dev_GitOps\terraform\examples\complete\argocd.tf
# argocd 네임스페이스 생성
resource "kubernetes_namespace" "argocd_namespace" {
  metadata {
    name = "argocd"
  }
  depends_on = [ helm_release.aws_load_balancer_controller ]
}

# argocd 배포
resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "6.4.0"

  set {
    name  = "server.extraArgs"
    value = "{--insecure}"
  }

  set {
    name  = "server.service.namedTargetPort"
    value = "false"
  }

  set {
    name  = "server.ingress.enabled"
    value = "true"
  }
    
    depends_on = [helm_release.aws_load_balancer_controller ]
}