## 🧑🏻‍💻 AMZMall_Dev_GitOps

> 이 레포지토리는 AMZMall의 개발 환경을 위한 GitOps 구성 및 인프라 코드를 포함하고 있습니다. 

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
└── frontend
    ├── Chart.yaml
    ├── values.yaml
    └── templates
        ├── _helpers.tpl
        ├── deployment.yaml
        ├── service.yaml
        └── ingress.yaml
```
- `backend/`: 백엔드 애플리케이션에 대한 Kubernetes 차트 및 템플릿이 포함되어 있습니다.
- `frontend/`: 프론트엔드 애플리케이션에 대한 Kubernetes 차트 및 템플릿이 포함되어 있습니다.

각 디렉토리에는 다음과 같은 파일이 있습니다
- `Chart.yaml`: Helm 차트의 메타데이터를 정의하는 파일입니다.
- `values.yaml`: Helm 차트의 기본값을 설정하는 파일입니다.
- `templates/`: Kubernetes 매니페스트 및 설정 파일이 포함된 디렉토리입니다.

## ✒️기여 방법 및 규칙
1. 프로젝트 Fork하기: 프로젝트의 GitHub 페이지에서 Fork 버튼을 클릭하여, 자신의 GitHub 계정으로 프로젝트를 복사합니다. 이렇게 하면 자신의 저장소에서 자유롭게 변경사항을 실험하고 개발할 수 있습니다.
2. 로컬 환경에 클론하기: Fork한 프로젝트를 자신의 로컬 개발 환경으로 `git clone`을 수행합니다.
3. 변경사항 개발
새로운 브랜치 생성: 작업을 시작하기 전에, 새로운 기능이나 버그 수정을 위한 별도의 브랜치를 생성합니다. 이는 git checkout -b <브랜치명> 명령어로 수행할 수 있습니다.
개발 및 테스트: 필요한 변경사항을 개발하고, 로컬 환경에서 충분히 테스트합니다. 변경사항이 Kubernetes 매니페스트나 스크립트에 영향을 준다면, 제공된 스크립트를 사용하여 애플리케이션 컴포넌트를 로컬 환경에서 배포하거나 업데이트하여 테스트합니다.
4. 기여 제출
변경사항 커밋: 개발한 내용을 로컬 저장소에 커밋합니다. 커밋 메시지는 변경사항을 명확하게 설명해야 합니다.
GitHub로 푸시: 개발한 브랜치를 GitHub에 있는 Fork한 저장소로 푸시합니다.
풀 리퀘스트(PR) 생성: 원본 저장소로 풀 리퀘스트를 생성합니다. PR 설명란에는 변경사항의 개요, 변경의 이유, 테스트 방법 등을 자세히 기술합니다.
리뷰 대기 및 반영: 프로젝트 관리자 또는 다른 기여자들의 리뷰를 받게 됩니다. 리뷰 과정에서 제안된 변경사항이 있다면, 이를 반영하여 PR을 업데이트합니다.



