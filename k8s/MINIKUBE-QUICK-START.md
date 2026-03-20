# Minikube 快速參考卡片

## 📋 安裝依賴

```bash
# macOS (Homebrew)
brew install minikube kubectl

# Linux (apt)
sudo apt-get install -y minikube kubectl

# 驗證
minikube version
kubectl version --client
```

## 🚀 一鍵部署（推薦）

```bash
# 1. 啟動 Minikube
minikube start --driver=docker --cpus=4 --memory=4096 --disk-size=20GB

# 2. 运行自动部署脚本
bash k8s/minikube-setup.sh

# 3. 访问应用
kubectl port-forward -n yaonet svc/web 8000:8000
# 打开浏览器: http://localhost:8000
```

## 🐳 手動部署（如果不使用脚本）

```bash
# 配置本地 Docker
eval $(minikube docker-env)

# 构建镜像
docker build -t yaonet:latest .

# 部署资源
kubectl apply -f k8s/1-namespace.yaml
kubectl apply -f k8s/2-configmap.yaml
kubectl apply -f k8s/3-secret.yaml
kubectl apply -f k8s/4-postgres.yaml
kubectl apply -f k8s/5-redis.yaml
kubectl apply -f k8s/6-web-minikube.yaml
kubectl apply -f k8s/7-worker-minikube.yaml

# 等待就绪
kubectl wait --for=condition=ready pod -l app=postgres -n yaonet --timeout=120s
kubectl wait --for=condition=ready pod -l app=web -n yaonet --timeout=120s
```

## 🔍 常用命令速查

| 任務 | 命令 |
|------|------|
| 查看 Pod 列表 | `kubectl get pods -n yaonet` |
| 查看服務 | `kubectl get svc -n yaonet` |
| 即時日誌 | `kubectl logs -f -n yaonet -l app=web` |
| 進入 Shell | `kubectl exec -it -n yaonet deployment/web -- bash` |
| 檢查 Pod 詳情 | `kubectl describe pod <pod-name> -n yaonet` |
| 重啟 Web | `kubectl rollout restart deployment/web -n yaonet` |
| 端口轉發 | `kubectl port-forward -n yaonet svc/web 8000:8000` |
| 自動打開服務 | `minikube service web -n yaonet` |
| 查看資源使用 | `kubectl top pods -n yaonet` |
| 刪除所有資源 | `kubectl delete namespace yaonet` |

## 📝 代碼編輯後的快速重部署

```bash
# 1. 重新構建鏡像（minikube docker-env 仍在）
docker build -t yaonet:latest .

# 2. 重啟 Pod（會自動拉取新鏡像）
kubectl rollout restart deployment/web -n yaonet

# 3. 監控部署
kubectl rollout status deployment/web -n yaonet

# 4. 查看新日誌
kubectl logs -f -n yaonet -l app=web
```

## 🐛 故障排查

### Pod 卡在 Pending/CrashLoopBackOff

```bash
# 查看詳細信息
kubectl describe pod <pod-name> -n yaonet

# 查看日誌（包括前面的容器日誌）
kubectl logs <pod-name> -n yaonet --previous
kubectl logs <pod-name> -n yaonet
```

### 無法連接數據庫

```bash
# 檢查 PostgreSQL Pod
kubectl get pod -n yaonet -l app=postgres

# 查看 PostgreSQL 日誌
kubectl logs -n yaonet -l app=postgres --tail=50

# 從 Web Pod 測試連接
kubectl exec -it -n yaonet deployment/web -- \
  psql -h postgres -U postgres -d yaonet -c "SELECT 1"
```

### Web 無法訪問

```bash
# 驗證服務存在
kubectl get svc -n yaonet web

# 驗證 Pod 健康
kubectl get pods -n yaonet -l app=web
kubectl describe pod -n yaonet -l app=web

# 測試端口轉發
kubectl port-forward -n yaonet svc/web 8000:8000
# 在另一個終端：curl http://localhost:8000
```

## 📊 資源監控

```bash
# 啟用 metrics-server（如果上面沒有）
minikube addons enable metrics-server

# 查看節點資源使用
kubectl top nodes

# 查看 Pod 資源使用
kubectl top pods -n yaonet
```

## 🔧 調整 Minikube 資源

```bash
# 停止 Minikube
minikube stop

# 更新配置
minikube config set cpus 8
minikube config set memory 8192

# 重新啟動
minikube start

# 或一次性指定
minikube start --cpus=8 --memory=8192
```

## 🌐 訪問應用

### 方式 1：Port Forward（推薦用於開發）
```bash
kubectl port-forward -n yaonet svc/web 8000:8000
# 瀏覽器: http://localhost:8000
```

### 方式 2：自動 Minikube 服務
```bash
minikube service web -n yaonet
# 自動打開瀏覽器
```

### 方式 3：NodePort 直接訪問
```bash
# 獲取 Minikube IP 和 Port
MINIKUBE_IP=$(minikube ip)
NODEPORT=$(kubectl get svc -n yaonet web -o jsonpath='{.spec.ports[0].nodePort}')
echo "http://$MINIKUBE_IP:$NODEPORT"
```

## 🗑️ 清理

```bash
# 刪除整個 yaonet 命名空間（所有資源）
kubectl delete namespace yaonet

# 停止 Minikube（資源保留，下次可快速啟動）
minikube stop

# 完全清除 Minikube（包括所有 VM 和數據）
minikube delete
```

## 📚 更多資訊

- 完整指南：`k8s/README-minikube.md`
- Minikube 官文：https://minikube.sigs.k8s.io/
- Kubectl Cheatsheet：https://kubernetes.io/docs/reference/kubectl/cheatsheet/
