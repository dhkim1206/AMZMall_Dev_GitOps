# C:\AMZMall_Dev_GitOps\terraform\examples\complete\terraform.tfvars
aws_region           = "ap-northeast-2"
vpc_cidr             = "192.168.0.0/16"
public_subnet_cidrs  = ["192.168.1.0/24", "192.168.2.0/24"]
private_subnet_cidrs =  ["192.168.3.0/24", "192.168.4.0/24"]
infra_name           = "amzdraw-dev-infra"
azs                  = ["ap-northeast-2a", "ap-northeast-2c"]

cluster_name = "amz-draw-dev-cluster"
