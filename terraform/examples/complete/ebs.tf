# # C:\Users\user\Documents\GitHub\AMZMall_Dev_GitOps\terraform\examples\complete\ebs.tf
# resource "aws_iam_policy" "ebs_csi_policy" {
#   name        = "ebs-csi-policy"
#   description = "Policy for EBS CSI driver"
#   policy      = data.aws_iam_policy_document.ebs_csi_policy.json
# }

# data "aws_iam_policy_document" "ebs_csi_policy" {
#   statement {
#     actions   = ["ec2:CreateSnapshot", "ec2:AttachVolume", "ec2:DetachVolume", "ec2:ModifyVolume", "ec2:DescribeVolumes", "ec2:DeleteSnapshot", "ec2:CreateVolume", "ec2:DescribeSnapshots", "ec2:DeleteVolume"]
#     resources = ["*"]
#   }
# }

# resource "aws_iam_role" "ebs_csi_role" {
#   name = "ebs-csi-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       },
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ebs_csi_policy_attach" {
#   policy_arn = aws_iam_policy.ebs_csi_policy.arn
#   role       = aws_iam_role.ebs_csi_role.name
# }

# resource "helm_release" "ebs_csi_driver" {
#   name       = "aws-ebs-csi-driver"
#   repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver/"
#   chart      = "aws-ebs-csi-driver"
#   version    = "2.28.1"

#   set {
#     name  = "enableVolumeScheduling"
#     value = "true"
#   }

#   set {
#     name  = "enableVolumeResizing"
#     value = "true"
#   }

#   set {
#     name  = "enableVolumeSnapshot"
#     value = "true"
#   }

#   set {
#     name  = "serviceAccount.controller.create"
#     value = "false"
#   }

#   set {
#     name  = "serviceAccount.controller.name"
#     value = aws_iam_role.ebs_csi_role.name
#   }
# }