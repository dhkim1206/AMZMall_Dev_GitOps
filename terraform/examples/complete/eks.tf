#C:\AMZMall_Dev_GitOps\terraform\examples\complete\eks.tf
################################################################################
# EKS Module
################################################################################
data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}
# EKS 모듈 
module "eks" {

  # 모듈 디렉토리
  source = "../.."

  # 클러스터 버전 1.28
  cluster_version = "1.28"

  # 클러스터 이름
  cluster_name = var.cluster_name
  

  # 퍼블릭에서 클러스터 엔드포인트 연결 허용
  cluster_endpoint_public_access = true

  # 클러스터 에드온 설정
  cluster_addons = {
    # Kubernetes 클러스터 내에서 DNS 서비스를 제공
    # 클러스터 내의 서비스 이름을 IP 주소로 변환하여, 
    # 컨테이너가 서비스 이름을 사용하여 서로를 찾고 통신할 수 있게 한다
    coredns = {
      preserve    = true # 클러스터 업그레이드 시 coredns의 설정이 보존됩니다.
      most_recent = true
    }
    # Kubernetes 클러스터 내의 네트워킹을 관리합니다.
    # 각 노드에 실행되며, TCP, UDP, SCTP 스트림을 포드 간에
    # 또는 클러스터 외부와 포드 사이에서 라우팅하는 역할
    kube-proxy = {
      most_recent = true
    }
    #  네트워크 인터페이스
    # 각 Kubernetes 팟에 VPC 네트워크 내의 IP 주소를 할당하여,
    # 팟이 VPC의 자원과  통신
    vpc-cni = {
      most_recent = true
    }
  }

  # 외부 암호화 키 사용 설정

  #  AWS에서 생성한 KMS 키 대신 사용자가 지정한
  # KMS 키를 사용하겠다는 것을 나타냅니다.
  create_kms_key = false 

  cluster_encryption_config = {
    resources        = ["secrets"] # 암호화할 리소스 유형을 지정 여기서는 Kubernetes 시크릿을 암호화
  provider_key_arn = module.kms.key_arn # 사용할 KMS 키의 ARN 지정. 이 키는 module.kms에서 생성, 지정
}

# 추가 IAM 역할 정책 설정
# 이 설정은 EKS 클러스터에 필요한 추가적인 IAM 정책을 연결할 때 사용
iam_role_additional_policies = {
  additional = aws_iam_policy.additional.arn # 추가 정책의 ARN을 지정. 이 정책은 aws_iam_policy 리소스를 통해 생성
}

  # VPC 설정 - EKS 클러스터를 위한 VPC와 서브넷 설정
  vpc_id = aws_vpc.amz_draw_vpc.id
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id] # 프라이빗 서브넷 ID들

  # 클러스터 보안 그룹 규칙 확장 - EKS 클러스터의 보안을 강화하기 위한 추가 규칙
  cluster_security_group_additional_rules = {
    # 모든 인바운드 트래픽 허용
    ingress_allow_all = {
        description = "Allow all inbound traffic"
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        type        = "ingress"
        cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # 노드 간 보안 그룹 규칙 확장 - 노드 간 통신 보안 강화
  node_security_group_additional_rules = {
    # 모든 인바운드 트래픽 허용
    ingress_self_all = {
        description = "Allow all inbound traffic from self"
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        type        = "ingress"
        self        = true
    }
  }

  # EKS 관리형 노드 그룹 설정
  eks_managed_node_groups = {
    # 서비스용 노드 그룹
    service_node_group = {
      name = "service_node_group"

      # iam_role_attach_cni_policy 옵션을 true로 설정하면, Amazon EKS 클러스터를 위한 Amazon VPC CNI 플러그인에 필요한 IAM 정책이 자동으로 노드 그룹에 연결
      iam_role_attach_cni_policy = true

      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
      min_size     = 2
      max_size     = 4
      desired_size = 2
      subnet_ids     = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]# 프라이빗 서브넷 ID
      tags = {
        ExtraTag = "service_node_group"
      }
      labels = {
        node_group = "service_node_group"
      }
    }
    # 에코 시스템용 노드 그룹
    eco_system_node_group = {
      iam_role_attach_cni_policy = true
      name = "eco_system_node_group"
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
      min_size     = 1
      max_size     = 1
      desired_size = 1
      subnet_ids     = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id] #[aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id] # 프라이빗 서브넷 ID
      tags = {
        ExtraTag = "eco_system_node_group"
      }
      labels = {
        node_group = "eco_system_node_group"
      }
    }
  }

  # aws-auth configmap 관리 설정 - 클러스터 접근 권한 관리
  manage_aws_auth_configmap = true

  # 클러스터 사용자 설정 - 클러스터 접근을 위한 IAM 사용자 설정
  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::009946608368:user/DOHYUNG"
      username = "DOHYUNG"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::009946608368:user/DOHYUNG2"
      username = "DOHYUNG2"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::009946608368:user/JUNYONG"
      username = "JUNYONG"
      groups   = ["system:masters"]
    },
  ]
  aws_auth_accounts = [
    "009946608368"
  ]

  # 클러스터 태그 설정
  tags = {
    "Name" = var.infra_name
    "karpenter.sh/discovery" = var.cluster_name
  }
  # Fargate 프로필과 동시에 생성하려고 하면 출동 발생 할 수 있음
  # # OIDC Identity provider
  cluster_identity_providers = {
    sts = {
      client_id = "sts.amazonaws.com"
    }
  }
  
}

################################################################################
# Supporting resources
################################################################################
# 추가 보안 그룹 설정 - 클러스터와 관련된 추가적인 보안 정의
resource "aws_security_group" "additional" {

    name_prefix = "${var.cluster_name}-additional" 
    vpc_id      = aws_vpc.amz_draw_vpc.id    # 보안 그룹이 속할 VPC의 ID

    # 모든 인바운드 트래픽 허용
    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # 모든 아웃바운드 트래픽 허용 (기본 설정이므로 생략 가능)
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
    "Name" = var.infra_name
    }
}

# 추가 IAM 정책 설정 - 클러스터 관리에 필요한 추가적인 IAM 정책을 정의
resource "aws_iam_policy" "additional" {
  name   = "${var.infra_name}-additional"
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action   = ["ec2:Describe*"],
        Effect   = "Allow",
        Resource = "*"
      },
    ]
  })
}

# KMS 모듈 설정 - 클러스터 암호화에 사용될 KMS 키를 생성 및 관리
module "kms" { 
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 1.5"

  aliases               = ["amzdraw-eks/${var.infra_name}"]
  description           = "${var.infra_name} cluster encryption key"
  enable_default_policy = true
  key_owners            = [data.aws_caller_identity.current.arn]

  tags = {
    "Name" = var.infra_name
  }
}
resource "aws_iam_policy" "kms_delete_alias_policy" {
  name        = "KMSDeleteAliasPolicy"
  description = "Allows deletion of KMS alias"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "kms:DeleteAlias"
        Resource = "*" # 보안상의 이유로, 가능하다면 특정 리소스에 대한 권한을 제한해야 합니다.
      },
    ]
  })
}

resource "aws_iam_user_policy_attachment" "attach_kms_delete_alias_policy" {
  user       = "DOHYUNG"
  policy_arn = aws_iam_policy.kms_delete_alias_policy.arn
}
