# Architecture
![aws3-03 drawio](https://github.com/dhkim1206/AMZMall_Dev_GitOps/assets/69470424/2a5c61a9-b31d-4341-b301-89a7bae50fca)


## 🧑🏻‍💻 AMZMall_Dev_GitOps  
GitOps test version 1.0
> **이 레포지토리는 AMZMall의 개발 환경을 위한 GitOps 구성 및 인프라 코드를 정의합니다.  

### 🗂️ directory
```

├── backend
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates
│       ├── _helpers.tpl
│       ├── deployment.yaml
│       ├── service.yaml
│       └── ingress.yaml 
├── frontend
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates
│       ├── _helpers.tpl
│       ├── deployment.yaml
│       ├── service.yaml
│       └── ingress.yaml
└── terraform
    └── examples
        └── complete
            ├── policy
            ├── values
            ├── README.md
            ├── alb.tf
            ├── argocd.tf
            ├── ca.tf
            ├── cdn.tf
            ├── ebs.tf
            ├── eks.tf
            ├── karpenter.tf
            ├── monitoring.tf
            ├── outputs.tf
            ├── provider.tf
            ├── rds.tf
            ├── terraform.tfvars
            ├── var.tf
            └── versions.tf

```
- `backend/`: 백엔드 애플리케이션에 대한 Kubernetes 차트 및 템플릿이 포함되어 있습니다.
- `frontend/`: 프론트엔드 애플리케이션에 대한 Kubernetes 차트 및 템플릿이 포함되어 있으나 s3외 CloudFront로 프론트엔드 어플리케이션에 대한 배포 방식을 바꿨기에 사용되지 않는 코드입니다.

각 디렉토리에는 다음과 같은 파일이 있습니다

- `Chart.yaml`: Helm 차트의 메타데이터를 정의하는 파일입니다.
- `values.yaml`: Helm 차트의 기본값을 설정하는 파일입니다.
- `templates/`: Kubernetes 매니페스트 및 설정 파일이 포함된 디렉토리입니다.

---
### ✒️기여 방법
1. 프로젝트 Fork: 프로젝트의 GitHub 페이지에서 Fork 버튼을 클릭하여, 자신의 GitHub 계정으로 프로젝트를 복사합니다.
2. 로컬 환경 clone: Fork한 프로젝트를 자신의 로컬 개발 환경으로 `git clone`을 수행합니다.
3. 새로운 브랜치 생성 : 개발을 위한 별도의 브랜치를 생성합니다. `git checkout -b <브랜치명>` 명령어로 수행할 수 있습니다.
4. 변경사항 커밋: 개발한 내용을 로컬 저장소에 커밋합니다. 단, **커밋 메시지 규칙**에 밎춰 커밋합니다.
5. GitHub로 푸시: 개발한 브랜치를 GitHub에 있는 Fork한 저장소로 푸시합니다.
6. 풀 리퀘스트(PR) 생성: 원본 저장소로 풀 리퀘스트를 생성합니다.
7. 리뷰 대기 및 반영: 이를 검증하고 반영하여 PR을 업데이트합니다.

---
### 💡 커밋 메시지 규칙
- **[FIX]**
  - 버그 수정에 사용됩니다. 변경된 사항을 간결하게 설명해야 합니다.
  - 예시: "[FIX] 로그인 기능에서 발생한 인증 오류 수정"
- **[UPDATE]**
  - 기존 코드의 수정이나 업데이트를 나타냅니다.
  - 코드 개선이나 리팩토링과 같은 변경 사항을 포함합니다.
  - 예시: "[UPDATE] 사용자 프로필 페이지 디자인 업데이트"
- **[ADD/CREATE]**
  - 새로운 모듈, 기능, 또는 파일을 프로젝트에 추가하는 경우에 사용됩니다.
  - 예시: "[ADD] 회원가입 양식 유효성 검사 기능 추가"
- **[REFACTOR]**
  - 코드 리팩토링에 사용됩니다.
  - 코드의 구조를 변경하거나 가독성을 향상시키는 작업을 포함합니다.
  - 예시: "[REFACTOR] 데이터베이스 쿼리 메서드를 클래스로 분리"
- **[DOC]**
  - 문서화 작업을 나타냅니다.
  - 주로 문서의 추가, 업데이트, 또는 수정을 의미합니다.
  - 예시: "[DOC] API 엔드포인트 설명 추가"

