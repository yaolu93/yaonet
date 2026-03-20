# GKE 快速参考卡片（Google Kubernetes Engine）

## 📋 最快開始（3 步）

### 前置要求
```bash
# 安装工具（Debian/Linux）
sudo apt-get update && sudo apt-get install -y curl gnupg lsb-release

# 安装 Google Cloud SDK
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
sudo apt-get update && sudo apt-get install -y google-cloud-sdk

# 安装 kubectl
sudo apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin
# 或从官方 Kubernetes 仓库安装（推荐）
sudo mkdir -p /usr/share/keyrings
sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update && sudo apt-get install -y kubectl

# 验证安装
gcloud --version
kubectl version --client

# 登录 GCP
gcloud auth login
gcloud config set project yaonet-487821
```

### 一键部署
```bash
# 1. 设置你的项目 ID
export GCP_PROJECT_ID="yaonet-487821"
export GCP_REGION="asia-east1"  # 或其他区域

# 2. 执行自动部署脚本（5-15 分钟）
bash k8s/gke-setup.sh

# 3. 获取外部 IP 并访问
kubectl get svc -n yaonet web
# 打开： http://<EXTERNAL-IP>:80
```

## 🐳 手動部署（分步）

### 1. 创建 Artifact Registry
```bash
export REGION="asia-east1"
export PROJECT_ID="your-project-id"

gcloud services enable artifactregistry.googleapis.com

gcloud artifacts repositories create yaonet \
  --repository-format=docker \
  --location=$REGION

gcloud auth configure-docker ${REGION}-docker.pkg.dev
```

### 2. 构建并推送镜像
```bash
cd /home/yao/fromGithub/yaonet

export IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/yaonet/yaonet:latest"

docker build -t $IMAGE .
docker push $IMAGE
```

### 3. 创建 GKE 集群
```bash
export CLUSTER_NAME="yaonet-cluster"
export ZONE="asia-east1-a"

gcloud container clusters create $CLUSTER_NAME \
  --zone=$ZONE \
  --num-nodes=2 \
  --machine-type=n1-standard-2 \
  --enable-autoscaling \
  --min-nodes=1 \
  --max-nodes=5 \
  --workload-pool=${PROJECT_ID}.svc.id.goog

gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE
```

### 4. 部署应用
```bash
# 创建 namespace 和 secrets
kubectl apply -f k8s/1-namespace.yaml
kubectl apply -f k8s/2-configmap.yaml
kubectl apply -f k8s/3-secret.yaml

# 部署数据库、缓存和应用
kubectl apply -f k8s/4-postgres-gke.yaml
kubectl apply -f k8s/5-redis-gke.yaml

# 更新镜像 URL（用你的实际 URL）
sed -i "s|REGION-docker.pkg.dev/PROJECT_ID/REPOSITORY|$IMAGE|g" k8s/6-web-gke.yaml k8s/7-worker-gke.yaml

kubectl apply -f k8s/6-web-gke.yaml
kubectl apply -f k8s/7-worker-gke.yaml
kubectl apply -f k8s/8-hpa.yaml
```

## 🔍 常用命令速查

| 任務 | 命令 |
|------|------|
| 查看 Pod 列表 | `kubectl get pods -n yaonet` |
| 查看服務和 IP | `kubectl get svc -n yaonet` |
| 實時 Web 日誌 | `kubectl logs -f -n yaonet -l app=web` |
| 進入 Web Pod Shell | `kubectl exec -it -n yaonet deployment/web -- bash` |
| 檢查 Pod 詳情 | `kubectl describe pod <pod-name> -n yaonet` |
| 重啟 Web | `kubectl rollout restart deployment/web -n yaonet` |
| 查看資源使用 | `kubectl top pods -n yaonet` |
| 自動缩放状态 | `kubectl get hpa -n yaonet` |
| 删除所有资源 | `kubectl delete namespace yaonet` |

## 📊 GCP/GKE 特定命令

| 任務 | 命令 |
|------|------|
| 列出所有集群 | `gcloud container clusters list` |
| 获取集群凭据 | `gcloud container clusters get-credentials CLUSTER_NAME --zone ZONE` |
| 查看日志（Stackdriver） | `gcloud logging read "resource.type=k8s_container AND resource.labels.namespace_name=yaonet" --limit=50` |
| 升级集群 | `gcloud container clusters upgrade CLUSTER_NAME --zone ZONE` |
| 增加节点数 | `gcloud container clusters resize CLUSTER_NAME --num-nodes=5 --zone ZONE` |
| 删除集群 | `gcloud container clusters delete CLUSTER_NAME --zone ZONE` |
| 列出镜像 | `gcloud artifacts docker images list ${REGION}-docker.pkg.dev/${PROJECT_ID}/yaonet` |

## 🔐 Workload Identity 配置

```bash
# 创建 Google Service Account (GSA)
gcloud iam service-accounts create gke-yaonet-sa

# 授予权限
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:gke-yaonet-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.reader"

# 创建 Kubernetes Service Account (KSA)
kubectl create serviceaccount yaonet-ksa -n yaonet

# 绑定 GSA 和 KSA
gcloud iam service-accounts add-iam-policy-binding \
  gke-yaonet-sa@${PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:${PROJECT_ID}.svc.id.goog[yaonet/yaonet-ksa]"

# 标注 KSA
kubectl annotate serviceaccount yaonet-ksa -n yaonet \
  iam.gke.io/gcp-service-account=gke-yaonet-sa@${PROJECT_ID}.iam.gserviceaccount.com
```

## 🌐 访问应用

### 通过 LoadBalancer IP
```bash
# 等待 LoadBalancer 分配外部 IP（可能需要 1-2 分钟）
kubectl get svc -n yaonet web -w

# 一旦有 EXTERNAL-IP，访问：
# http://<EXTERNAL-IP>:80
```

### 通过 Ingress（自定义域名）
```bash
# 1. 配置 DNS 指向 Ingress 的 IP
kubectl get ingress -n yaonet

# 2. 编辑 9-ingress-gke.yaml，修改 host 为你的域名
# 3. 应用 Ingress
kubectl apply -f k8s/9-ingress-gke.yaml

# 4. 访问配置的域名
# https://yaonet.example.com
```

## 💾 数据备份和恢复

### 备份 PostgreSQL
```bash
# 导出备份
kubectl exec -n yaonet postgres-0 -- \
  pg_dump -U postgres yaonet | gzip > yaonet_backup.sql.gz

# 检查备份
gunzip -c yaonet_backup.sql.gz | head -20
```

### 从备份恢复
```bash
# 还原备份
gunzip -c yaonet_backup.sql.gz | \
  kubectl exec -i -n yaonet postgres-0 -- \
  psql -U postgres -d yaonet
```

## 📈 性能监控

### 查看资源使用
```bash
# Pod 级别
kubectl top pods -n yaonet

# 节点级别
kubectl top nodes

# HPA 状态
kubectl get hpa -n yaonet
kubectl describe hpa web -n yaonet
```

### 在 GCP 控制台查看
```bash
# Workloads
https://console.cloud.google.com/kubernetes/workloads?project=$PROJECT_ID

# 监控 (Monitoring)
https://console.cloud.google.com/monitoring?project=$PROJECT_ID

# 日志 (Logging)
https://console.cloud.google.com/logs?project=$PROJECT_ID
```

## 🔧 常見問題排查

### Pod 无法拉取镜像
```bash
# 检查 ImagePullSecret
kubectl describe pod <pod-name> -n yaonet | grep Pull

# 验证权限
kubectl get secret -n yaonet
```

### 数据库连接失败
```bash
# 检查 PostgreSQL Pod
kubectl get pod -n yaonet -l app=postgres

# 查看 PostgreSQL 日志
kubectl logs -n yaonet -l app=postgres

# 从 Web Pod 测试连接
kubectl exec -it -n yaonet deployment/web -- \
  psql -h postgres -U postgres -d yaonet -c "SELECT 1"
```

### 磁盘空间不足
```bash
# 查看 PersistentVolume 使用情况
kubectl get pvc -n yaonet
kubectl describe pvc postgres-storage-postgres-0 -n yaonet

# 扩展 PersistentVolume
kubectl patch pvc postgres-storage-postgres-0 -n yaonet -p '{"spec":{"resources":{"requests":{"storage":"50Gi"}}}}'
```

## 🎯 生产最佳实践

- ✅ 使用 Workload Identity（不用服务账户密钥）
- ✅ 配置 Resource Requests/Limits
- ✅ 启用 HPA（自动缩放）
- ✅ 使用 PersistentVolume 持久化数据
- ✅ 定期备份数据库
- ✅ 启用 GCP 监控和日志
- ✅ 使用 Ingress + TLS 证书
- ✅ 配置 Network Policy 限制流量
- ✅ 启用 Pod 安全策略
- ✅ 使用 Private GKE 集群（提高安全性）

## 💰 成本优化

```bash
# 使用 Preemptible VM（便宜 70%，但可被抢占）
gcloud container node-pools create preemptible-pool \
  --cluster=$CLUSTER_NAME \
  --zone=$ZONE \
  --preemptible \
  --num-nodes=2

# 使用 Committed Use Discounts（长期使用节省 25-52%）
# 进入 GCP 控制台 > Compute Engine > Committed Use Discounts
```

## 🗑️ 清理资源

```bash
# 删除应用（保留集群）
kubectl delete namespace yaonet

# 删除集群
gcloud container clusters delete $CLUSTER_NAME --zone=$ZONE

# 删除 Artifact Registry
gcloud artifacts repositories delete yaonet --location=$REGION

# 删除未使用的磁盘
gcloud compute disks list
gcloud compute disks delete <disk-name>
```

## 📚 更多資訊

- **GKE 文档**：https://cloud.google.com/kubernetes-engine/docs
- **Artifact Registry**：https://cloud.google.com/artifact-registry/docs
- **GKE 定价**：https://cloud.google.com/kubernetes-engine/pricing
- **Workload Identity**：https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity
- **自动缩放**：https://cloud.google.com/kubernetes-engine/docs/concepts/horizontalpodautoscaler
