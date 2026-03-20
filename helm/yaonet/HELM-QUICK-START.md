# Helm 快速参考卡片

## 🚀 最快开始（3 步）

```bash
# 1. 安装 Helm（如果还没安装）
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 2. Minikube 部署
helm install yaonet ./helm/yaonet \
  -f helm/yaonet/values-minikube.yaml \
  -n yaonet --create-namespace

# 3. 获取服务 URL
kubectl get svc -n yaonet web
minikube service web -n yaonet
```

## 📋 命令速查表

### 安装和部署

| 任務 | 命令 |
|------|------|
| **Minikube 安装** | `helm install yaonet ./helm/yaonet -f helm/yaonet/values-minikube.yaml -n yaonet --create-namespace` |
| **GKE 安装** | `helm install yaonet ./helm/yaonet -f helm/yaonet/values-gke.yaml -n yaonet --create-namespace` |
| **验证语法** | `helm lint ./helm/yaonet` |
| **生成 YAML** | `helm template yaonet ./helm/yaonet -f helm/yaonet/values-gke.yaml` |
| **查看状态** | `helm status yaonet -n yaonet` |
| **查看值** | `helm get values yaonet -n yaonet` |

### 更新和升级

| 任務 | 命令 |
|------|------|
| **升级应用** | `helm upgrade yaonet ./helm/yaonet -f helm/yaonet/values-gke.yaml -n yaonet` |
| **修改副本数** | `helm upgrade yaonet ./helm/yaonet -f helm/yaonet/values-gke.yaml --set web.replicaCount=5 -n yaonet` |
| **查看版本历史** | `helm history yaonet -n yaonet` |
| **回滚上一版本** | `helm rollback yaonet -n yaonet` |
| **回滚特定版本** | `helm rollback yaonet 2 -n yaonet` |

### 卸载

| 任務 | 命令 |
|------|------|
| **卸载应用** | `helm uninstall yaonet -n yaonet` |
| **删除 Namespace** | `kubectl delete namespace yaonet` |

### Kubernetes 监控

| 任務 | 命令 |
|------|------|
| **查看 Pod 列表** | `kubectl get pods -n yaonet` |
| **实时监控 Pod** | `kubectl get pods -n yaonet -w` |
| **查看服務和 IP** | `kubectl get svc -n yaonet` |
| **查看 Pod 日誌** | `kubectl logs -f -n yaonet deployment/web` |
| **查看 Pod 詳情** | `kubectl describe pod <pod-name> -n yaonet` |
| **進入 Pod 命令行** | `kubectl exec -it -n yaonet deployment/web -- bash` |
| **查看 HPA 狀態** | `kubectl get hpa -n yaonet` |
| **查看資源使用** | `kubectl top pods -n yaonet` |

## 🔧 常见配置

### 修改密码和密钥

```bash
# 编辑 values 文件
vim helm/yaonet/values-gke.yaml

# 修改以下部分：
secrets:
  secretKey: "YOUR-RANDOM-STRING-HERE"
  postgres:
    password: "YOUR-PASSWORD-HERE"

# 升级应用
helm upgrade yaonet ./helm/yaonet \
  -f helm/yaonet/values-gke.yaml -n yaonet
```

### 快速生成强密钥

```bash
# 方法 1: Python
python3 -c "import secrets; print(secrets.token_urlsafe(32))"

# 方法 2: OpenSSL
openssl rand -base64 32

# 方法 3: Linux/macOS
head -c 32 /dev/urandom | base64
```

### 修改副本数

```bash
# 通过 Helm 命令直接修改
helm upgrade yaonet ./helm/yaonet \
  -f helm/yaonet/values-gke.yaml \
  --set web.replicaCount=5 \
  --set worker.replicaCount=3 \
  -n yaonet

# 或编辑 values 文件后再 upgrade
vim helm/yaonet/values-gke.yaml
helm upgrade yaonet ./helm/yaonet \
  -f helm/yaonet/values-gke.yaml \
  -n yaonet
```

### 修改镜像

```bash
# GKE 推送新镜像后
export IMAGE="asia-east1-docker.pkg.dev/PROJECT_ID/yaonet/yaonet:v2"

helm upgrade yaonet ./helm/yaonet \
  -f helm/yaonet/values-gke.yaml \
  --set image.repository="${REGION}-docker.pkg.dev/${PROJECT_ID}/yaonet/yaonet" \
  --set image.tag="v2" \
  -n yaonet
```

## 📊 自动缩放配置

### 启用 HPA

```bash
helm upgrade yaonet ./helm/yaonet \
  -f helm/yaonet/values-gke.yaml \
  --set autoscaling.enabled=true \
  --set webAutoscaling.minReplicas=2 \
  --set webAutoscaling.maxReplicas=10 \
  -n yaonet

# 查看 HPA 状态
kubectl get hpa -n yaonet
kubectl describe hpa web-hpa -n yaonet
```

### 修改 CPU 阈值

```bash
helm upgrade yaonet ./helm/yaonet \
  -f helm/yaonet/values-gke.yaml \
  --set webAutoscaling.targetCPUUtilizationPercentage=70 \
  -n yaonet
```

## 🌐 Ingress 和自定义域名 (GKE)

### 启用 Ingress

```bash
helm upgrade yaonet ./helm/yaonet \
  -f helm/yaonet/values-gke.yaml \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host="yaonet.example.com" \
  -n yaonet

# 获取 Ingress IP
kubectl get ingress -n yaonet
```

### 设置自定义域名

```bash
# 编辑 values 文件
vim helm/yaonet/values-gke.yaml

# 修改 ingress 部分：
ingress:
  enabled: true
  hosts:
    - host: my-yaonet.example.com
      paths:
        - path: /
          pathType: Prefix

helm upgrade yaonet ./helm/yaonet \
  -f helm/yaonet/values-gke.yaml -n yaonet
```

## 🔐 Workload Identity (GKE)

### 启用 Workload Identity

```bash
helm upgrade yaonet ./helm/yaonet \
  -f helm/yaonet/values-gke.yaml \
  --set workloadIdentity.enabled=true \
  --set workloadIdentity.googleServiceAccount="gke-yaonet-sa@PROJECT_ID.iam.gserviceaccount.com" \
  -n yaonet
```

## 🐛 故障排查命令

```bash
# 查看最近的错误
kubectl get events -n yaonet --sort-by='.lastTimestamp'

# 检查 Pod 的完整日志
kubectl logs <pod-name> -n yaonet --all-containers=true --timestamps=true

# 进入 Pod 调试
kubectl debug pod <pod-name> -n yaonet -it -- bash

# 测试数据库连接
kubectl exec -it -n yaonet postgres-0 -- \
  psql -U postgres -d yaonet -c "SELECT 1"

# 查看 PersistentVolumeClaim 状态
kubectl get pvc -n yaonet
kubectl describe pvc postgres-storage-postgres-0 -n yaonet
```

## 📚 快速參考文件

| 文件 | 說明 |
|------|------|
| `HELM-DEPLOYMENT.md` | 詳細部署指南 |
| `helm/yaonet/README.md` | Chart 文檔 |
| `helm/yaonet/values.yaml` | 默認配置值 |
| `helm/yaonet/values-minikube.yaml` | Minikube 覆蓋值 |
| `helm/yaonet/values-gke.yaml` | GKE 覆蓋值 |
| `helm/yaonet/Chart.yaml` | Chart 元數據 |

## 🎯 实用链接

- [Helm 官方文档](https://helm.sh/docs/)
- [Kubernetes 文档](https://kubernetes.io/docs/)
- [Chart 最佳实践](https://helm.sh/docs/chart_best_practices/)
- [Helm Hub](https://artifacthub.io/)
