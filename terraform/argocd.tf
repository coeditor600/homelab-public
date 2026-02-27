resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

# 2. Deploy ArgoCD via Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  # Ensure Helm waits for all pods to be ready before reporting success
  wait    = true
  timeout = 600

  # Disable HA Redis to save memory on the single node
  set {
    name  = "redis-ha.enabled"
    value = "false"
  }

  # Disable Dex (SSO) since we don't need it right now (saves RAM)
  set {
    name  = "dex.enabled"
    value = "false"
  }

  # Ensure the application controller doesn't consume excessive resources
  set {
    name  = "controller.replicas"
    value = "1"
  }

  set {
    name  = "server.replicas"
    value = "1"
  }

  set {
    name  = "repoServer.replicas"
    value = "1"
  }

  #enable reachability of argocd server outside of cluster
  set {
    name  = "server.service.type"
    value = "NodePort"
  }

  set {
    name  = "server.service.nodePorts.https"
    value = "30443"
  }
}
