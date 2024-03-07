# # C:\Users\user\Documents\GitHub\AMZMall_Dev_GitOps\terraform\examples\complete\ebs.tf
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller"]
    }
  }
}

resource "kubernetes_service_account" "ebs_csi_controller_sa" {
  metadata {
    name        = "ebs-csi-controller"
    namespace   = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.ebs_csi_role.arn
    }
  }
}
resource "aws_iam_role" "ebs_csi_role" {
  name = "${var.cluster_name}-ebs-csi-role"

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  tags = {
    "Name" = "${var.cluster_name}-ebs-csi-role"
  }
}

resource "aws_iam_policy" "ebs_csi_policy" {
  name        = "${var.cluster_name}-ebs-csi-policy"
  description = "Policy for EBS CSI driver"

  policy = file("${path.module}/policy/ebs_csi_policy.json")
}

resource "aws_iam_role_policy_attachment" "ebs_csi_policy_attachment" {
  role       = aws_iam_role.ebs_csi_role.name
  policy_arn = aws_iam_policy.ebs_csi_policy.arn
}

resource "helm_release" "ebs_csi_driver" {
  name       = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver/"
  chart      = "aws-ebs-csi-driver"
  namespace  = "kube-system"

  set {
    name  = "serviceAccount.controller.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.controller.name"
    value = kubernetes_service_account.ebs_csi_controller_sa.metadata[0].name
  }
}

resource "kubernetes_storage_class" "ebs_storage_class" {
  metadata {
    name = "amzdraw-ebs"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "kubernetes.io/aws-ebs"

  parameters = {
    type = "gp3"
  }  
  reclaim_policy = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
  allow_volume_expansion = true

}

resource "null_resource" "update_storageclass" {
  triggers = {
    always_run = "${timestamp()}"
  }

  # provisioner "local-exec" {
  #   command = "sh ./update-sc.sh"
  # }
}