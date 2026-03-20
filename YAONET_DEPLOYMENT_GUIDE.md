# 🚀 Yaonet 项目部署指南

> **项目名称已从 microblog 成功重构为 yaonet**

## 📋 快速开始

### 1️⃣ Docker Compose 部署（推荐用于开发/测试）

```bash
cd /home/yao/fromGithub/yaonet

# 构建镜像
docker compose build

# 启动服务
docker compose up -d

# 检查服务状态
docker compose ps

# 访问应用
curl http://localhost:8000

# 停止服务
docker compose down
```

**包含的服务**:
- Web 应用 (Gunicorn） - 端口 8000
- RQ Worker - 后台任务处理
- PostgreSQL - 数据库
- Redis - 缓存和消息队列
- Elasticsearch - 搜索引擎
- Kibana & Logstash - 日志管理

---

### 2️⃣ Ansible 部署（推荐用于生产服务器）

#### 前置条件
- 目标服务器已安装 Python 3.8+
- SSH 密钥已配置
- Ansible 已安装

#### 部署步骤

```bash
cd /home/yao/fromGithub/yaonet/ansible

# 1. 编辑 inventory 文件，配置目标服务器
vim inventory

# 2. 编辑 group_vars/all.yml，配置部署参数
vim group_vars/all.yml

# 3. 验证库存配置
ansible all -i inventory -m ping

# 4. 执行完整部署
ansible-playbook site.yml -i inventory

# 5. 验证部署
./verify-setup.sh

# 6. 查看部署信息
./post-deployment-guide.sh
```

#### 可用的 Playbooks

| Playbook | 用途 |
|----------|------|
| `site.yml` | 完整初始化部署 |
| `app-deploy.yml` | 只部署应用代码 |
| `quick-deploy.yml` | 快速部署（跳过某些步骤） |
| `restart.yml` | 重启所有服务 |
| `health-check.yml` | 运行健康检查 |
| `undeploy.yml` | 卸载应用（保留数据库） |

---

### 3️⃣ Kubernetes 部署

#### A. 使用 Minikube（本地开发）

```bash
# 启动 Minikube
minikube start

# 构建镜像到 Minikube
eval $(minikube docker-env)
docker compose build

# 部署应用
kubectl apply -f k8s/1-namespace.yaml
kubectl apply -f k8s/2-configmap.yaml
kubectl apply -f k8s/3-secret.yaml
kubectl apply -f k8s/4-postgres.yaml
kubectl apply -f k8s/5-redis.yaml
kubectl apply -f k8s/6-web-minikube.yaml
kubectl apply -f k8s/7-worker-minikube.yaml

# 检查部署
kubectl get pods -n yaonet
kubectl describe svc -n yaonet

# 访问应用（端口转发）
kubectl port-forward -n yaonet svc/web 8000:8000
# 访问 http://localhost:8000
```

#### B. 使用 Helm（推荐）

```bash
# 添加 Helm chart
helm repo add yaonet-repo file:///home/yao/fromGithub/yaonet/helm

# 安装（开发环境）
helm install yaonet helm/yaonet/ -n yaonet --create-namespace

# 安装（Minikube 环境）
helm install yaonet helm/yaonet/ -n yaonet --create-namespace \
  -f helm/yaonet/values-minikube.yaml

# 安装（GKE 环境）
helm install yaonet helm/yaonet/ -n yaonet --create-namespace \
  -f helm/yaonet/values-gke.yaml

# 升级部署
helm upgrade yaonet helm/yaonet/ -n yaonet

# 卸载
helm uninstall yaonet -n yaonet
```

#### C. 使用 GKE（Google Kubernetes Engine）

```bash
# 1. 配置 GKE 集群（参考 k8s/GKE-DEPLOYMENT.md）
gcloud container clusters create yaonet-cluster

# 2. 配置 kubectl
gcloud container clusters get-credentials yaonet-cluster

# 3. 使用 Helm 部署
helm install yaonet helm/yaonet/ -n yaonet --create-namespace \
  -f helm/yaonet/values-gke.yaml

# 4. 获取负载均衡器的外部IP
kubectl get svc ingress-nginx -n yaonet
```

---

## 🔧 配置详解

### 环境变量

关键环境变量（在 `.env` 或部署时设置）：

```bash
# Flask
FLASK_APP=yaonet.py
FLASK_ENV=production
SECRET_KEY=your-secret-key-here

# Database
DATABASE_URL=postgresql://yaonet_user:password@db:5432/yaonet_db

# Redis
REDIS_URL=redis://redis:6379/0

# Elasticsearch
ELASTICSEARCH_URL=http://elasticsearch:9200

# 日志
LOG_TO_STDOUT=1
```

### 数据库初始化

```bash
# 使用 Docker Compose
docker compose exec web flask db upgrade
docker compose exec web flask shell

# 使用 Kubernetes
kubectl exec -it deployment/web -n yaonet -- flask db upgrade

# 使用 Ansible（自动执行）
# 部署时自动处理
```

---

## 📊 监控和日志

### Docker Compose

```bash
# 查看日志
docker compose logs -f web
docker compose logs -f worker

# 进入容器
docker compose exec web bash
```

### Kubernetes

```bash
# 查看 Pod 日志
kubectl logs -f deployment/web -n yaonet

# 进入 Pod
kubectl exec -it pod/web-xxx -n yaonet -- bash

# Prometheus 指标
kubectl port-forward -n yaonet svc/prometheus 9090:9090
```

### Ansible

```bash
# 应用日志
tail -f /var/log/yaonet/error.log
tail -f /var/log/yaonet/nginx/access.log

# 数据库日志
sudo -u postgres psql -d yaonet_db -c "SELECT 1;"
```

---

## 🚨 故障排查

### Docker Compose

```bash
# 重建镜像
docker compose build --no-cache

# 清理所有容器/卷
docker compose down -v

# 检查容器日志
docker compose logs --tail=100 web
```

### Kubernetes

```bash
# 检查 Pod 状态
kubectl describe pod pod-name -n yaonet

# 查看事件
kubectl get events -n yaonet

# 检查 Service
kubectl get svc -n yaonet
kubectl describe svc web -n yaonet
```

### Ansible

```bash
# 测试 SSH 连接
ansible all -i inventory -m ping

# 测试数据库连接
./ansible/test-db-connection.sh

# 验证部署后配置
./ansible/verify-setup.sh
```

---

## 📚 更多信息

- [Ansible 部署指南](./ansible/MANAGEMENT_GUIDE.md)
- [Kubernetes 部署指南](./k8s/README-minikube.md)
- [Kubernetes GKE 部署](./k8s/GKE-DEPLOYMENT.md)
- [Helm 部署集成](./helm/yaonet/HELM-INTEGRATION.md)
- [云部署指南](./cloud-deployment/README.md)
- [监控设置](./MONITORING.md)

---

## 📝 关键改变（从 microblog 到 yaonet）

| 组件 | 旧值 | 新值 |
|------|------|------|
| 应用文件 | microblog.py | yaonet.py |
| Docker 镜像 | microblog | yaonet-web/yaonet-worker |
| 数据库 | microblog_db | yaonet_db |
| 数据库用户 | microblog_user | yaonet_user |
| 任务队列 | microblog-tasks | yaonet-tasks |
| K8s 命名空间 | - | yaonet |
| Helm Chart | microblog | yaonet |

---

## ✅ 部署检查清单

- [ ] 环境变量已配置
- [ ] 数据库凭证已设置
- [ ] SSH 密钥已配置（Ansible 部署）
- [ ] 网络/防火墙规则已配置
- [ ] 备份策略已制定
- [ ] 监控告警已配置
- [ ] SSL/TLS 证书已准备
- [ ] 灾难恢复计划已制定

---

## 🎉 恭喜！

你的 Yaonet 项目现在已准备好进行部署。选择适合你的部署方法，开始使用吧！

如有问题，请参考相应的部署指南或查看项目文档。
