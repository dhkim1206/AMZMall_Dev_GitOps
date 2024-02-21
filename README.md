## AMZMall_Dev_GitOps
🔍 이 레포지토리는 AMZMall의 개발 환경을 위한 GitOps 구성 및 인프라 코드를 포함하고 있습니다. 

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

## 기여 규칙
1. 이 레포지토리를 Fork 합니다.
3. 제공된 스크립트 및 Kubernetes 매니페스트를 사용하여 애플리케이션 컴포넌트를 배포하거나 업데이트합니다.
4. 필요한 변경사항을 수행하고 기여 가이드라인을 따라 풀 리퀘스트를 제출합니다.



