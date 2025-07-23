# 🚀 Deployment & Operations Guide

## 📋 Table of Contents
- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Local Development](#local-development)
- [Staging Deployment](#staging-deployment)
- [Production Deployment](#production-deployment)
- [Monitoring & Observability](#monitoring--observability)
- [Troubleshooting](#troubleshooting)
- [Security Hardening](#security-hardening)
- [Backup & Recovery](#backup--recovery)
- [Scaling](#scaling)

## 🔧 Prerequisites

### **System Requirements**
- **Kubernetes**: 1.28+ (AKS, EKS, or GKE)
- **Docker**: 20.10+
- **Helm**: 3.12+
- **kubectl**: 1.28+
- **Terraform**: 1.5+
- **Git**: 2.30+

### **Cloud Accounts**
- **Azure**: Active subscription with AKS permissions
- **AWS**: IAM roles for EKS deployment
- **GCP**: Service account with GKE permissions

### **Required Tools**
```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Install Helm
curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz | tar xz
sudo mv linux-amd64/helm /usr/local/bin/

# Install Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs)"
sudo apt-get update && sudo apt-get install terraform
```

## 🌍 Environment Setup

### **Environment Variables**
Create environment-specific configuration files:

```bash
# .env.production
export ENVIRONMENT=production
export KUBERNETES_CLUSTER=fintech-ai-prod
export AZURE_SUBSCRIPTION_ID=your-subscription-id
export AZURE_TENANT_ID=your-tenant-id
export AZURE_CLIENT_ID=your-client-id
export AZURE_CLIENT_SECRET=your-client-secret

# Database
export POSTGRES_HOST=fintech-ai-postgres.postgres.database.azure.com
export POSTGRES_DB=fintech_ai_prod
export POSTGRES_USER=fintech_ai_user
export POSTGRES_PASSWORD=your-secure-password

# Redis
export REDIS_HOST=fintech-ai-redis.redis.cache.windows.net
export REDIS_PORT=6380
export REDIS_PASSWORD=your-redis-password

# Kafka
export KAFKA_BOOTSTRAP_SERVERS=fintech-ai-kafka.servicebus.windows.net:9093
export KAFKA_USERNAME=your-kafka-username
export KAFKA_PASSWORD=your-kafka-password

# ML Models
export ML_MODEL_REGISTRY=fintech-ai-models.azurecr.io
export ML_MODEL_VERSION=v1.2.0

# Monitoring
export PROMETHEUS_URL=https://prometheus.fintech-ai-platform.com
export GRAFANA_URL=https://grafana.fintech-ai-platform.com
export JAEGER_URL=https://jaeger.fintech-ai-platform.com
```

### **Secrets Management**
```bash
# Create Kubernetes secrets
kubectl create secret generic fintech-ai-secrets \
  --from-literal=postgres-password="$POSTGRES_PASSWORD" \
  --from-literal=redis-password="$REDIS_PASSWORD" \
  --from-literal=kafka-password="$KAFKA_PASSWORD" \
  --from-literal=jwt-secret="your-jwt-secret-key" \
  --from-literal=api-key="your-api-key"

# Create TLS secrets for HTTPS
kubectl create secret tls fintech-ai-tls \
  --cert=path/to/certificate.crt \
  --key=path/to/private.key
```

## 🏠 Local Development

### **Quick Start**
```bash
# Clone repository
git clone https://github.com/your-org/fintech-ai-platform
cd fintech-ai-platform

# Set up environment
cp .env.example .env
# Edit .env with your local settings

# Start infrastructure
docker-compose up -d postgres redis kafka

# Start services
make start-local

# Verify deployment
make health-check
```

### **Service-Specific Setup**

#### **API Gateway**
```bash
cd api-gateway
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt

# Run database migrations
alembic upgrade head

# Start service
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

#### **ML Service**
```bash
cd ml-service
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Download ML models
python scripts/download_models.py

# Start service
uvicorn main:app --reload --host 0.0.0.0 --port 8001
```

#### **Frontend**
```bash
cd frontend
npm install

# Start development server
npm start
```

## 🧪 Staging Deployment

### **Infrastructure Setup**
```bash
# Navigate to terraform directory
cd terraform

# Initialize for staging
terraform init -backend-config=environments/staging/backend.tf

# Plan deployment
terraform plan -var-file=environments/staging/terraform.tfvars

# Apply infrastructure
terraform apply -var-file=environments/staging/terraform.tfvars
```

### **Application Deployment**
```bash
# Deploy to staging
./scripts/deploy-platform.sh staging

# Verify deployment
kubectl get pods -n fintech-ai-staging
kubectl get services -n fintech-ai-staging
```

### **Staging Configuration**
```yaml
# k8s/namespaces/staging.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: fintech-ai-staging
  labels:
    environment: staging
    team: fintech-ai

---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: staging-quota
  namespace: fintech-ai-staging
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
```

## 🏭 Production Deployment

### **Infrastructure Deployment**
```bash
# Production infrastructure
cd terraform
terraform init -backend-config=environments/prod/backend.tf
terraform plan -var-file=environments/prod/terraform.tfvars
terraform apply -var-file=environments/prod/terraform.tfvars
```

### **Application Deployment**
```bash
# Deploy to production
./scripts/deploy-platform.sh production

# Run database migrations
kubectl exec -n fintech-ai-prod deployment/api-gateway -- alembic upgrade head

# Verify deployment
./scripts/verify-deployment.sh production
```

### **Production Configuration**
```yaml
# k8s/namespaces/production.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: fintech-ai-prod
  labels:
    environment: production
    team: fintech-ai

---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: production-quota
  namespace: fintech-ai-prod
spec:
  hard:
    requests.cpu: "16"
    requests.memory: 32Gi
    limits.cpu: "32"
    limits.memory: 64Gi
    persistentvolumeclaims: "10"
```

### **High Availability Setup**
```yaml
# k8s/deployments/api-gateway.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: fintech-ai-prod
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: api-gateway
  template:
    metadata:
      labels:
        app: api-gateway
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - api-gateway
              topologyKey: kubernetes.io/hostname
      containers:
      - name: api-gateway
        image: fintech-ai/api-gateway:latest
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
```

## 📊 Monitoring & Observability

### **Prometheus Configuration**
```yaml
# monitoring/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_pod_name]
        action: replace
        target_label: kubernetes_pod_name

  - job_name: 'api-gateway'
    static_configs:
      - targets: ['api-gateway:8000']
    metrics_path: /metrics

  - job_name: 'ml-service'
    static_configs:
      - targets: ['ml-service:8001']
    metrics_path: /metrics
```

### **Grafana Dashboards**
```json
{
  "dashboard": {
    "title": "FinTech AI Platform - Production Overview",
    "panels": [
      {
        "title": "API Gateway - Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total{service=\"api-gateway\"}[5m])",
            "legendFormat": "{{method}} {{endpoint}}"
          }
        ]
      },
      {
        "title": "ML Service - Processing Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(ml_processing_duration_seconds_bucket[5m]))",
            "legendFormat": "P95 Processing Time"
          }
        ]
      },
      {
        "title": "Document Processing Pipeline",
        "type": "stat",
        "targets": [
          {
            "expr": "documents_processed_total",
            "legendFormat": "Total Documents Processed"
          }
        ]
      }
    ]
  }
}
```

### **Alerting Rules**
```yaml
# monitoring/prometheus/alert_rules.yml
groups:
  - name: fintech-ai-alerts
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value }} errors per second"

      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.service }} is down"

      - alert: HighMemoryUsage
        expr: (container_memory_usage_bytes / container_spec_memory_limit_bytes) > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.pod }}"

      - alert: HighCPUUsage
        expr: (rate(container_cpu_usage_seconds_total[5m]) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.pod }}"
```

## 🔧 Troubleshooting

### **Common Issues**

#### **Service Not Starting**
```bash
# Check pod status
kubectl get pods -n fintech-ai-prod

# Check pod logs
kubectl logs -n fintech-ai-prod deployment/api-gateway

# Check pod events
kubectl describe pod -n fintech-ai-prod <pod-name>

# Check resource usage
kubectl top pods -n fintech-ai-prod
```

#### **Database Connection Issues**
```bash
# Test database connectivity
kubectl exec -n fintech-ai-prod deployment/api-gateway -- \
  python -c "from app.database.connection import get_db; print(get_db())"

# Check database logs
kubectl logs -n fintech-ai-prod deployment/postgres
```

#### **ML Model Loading Issues**
```bash
# Check model registry connectivity
kubectl exec -n fintech-ai-prod deployment/ml-service -- \
  python -c "from app.models.prediction import load_models; load_models()"

# Check model storage
kubectl exec -n fintech-ai-prod deployment/ml-service -- ls -la /models
```

### **Debugging Commands**
```bash
# Port forward for local debugging
kubectl port-forward -n fintech-ai-prod svc/api-gateway 8000:8000
kubectl port-forward -n fintech-ai-prod svc/ml-service 8001:8001

# Access service shell
kubectl exec -it -n fintech-ai-prod deployment/api-gateway -- /bin/bash

# Check service health
curl http://localhost:8000/health
curl http://localhost:8001/health

# Monitor logs in real-time
kubectl logs -f -n fintech-ai-prod deployment/api-gateway
```

## 🔒 Security Hardening

### **Network Policies**
```yaml
# k8s/network-policies/api-gateway-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-gateway-policy
  namespace: fintech-ai-prod
spec:
  podSelector:
    matchLabels:
      app: api-gateway
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8000
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: ml-service
    ports:
    - protocol: TCP
      port: 8001
  - to:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - protocol: TCP
      port: 5432
```

### **Pod Security Standards**
```yaml
# k8s/pod-security/api-gateway.yaml
apiVersion: v1
kind: Pod
metadata:
  name: api-gateway
  namespace: fintech-ai-prod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
  containers:
  - name: api-gateway
    image: fintech-ai/api-gateway:latest
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
    volumeMounts:
    - name: tmp
      mountPath: /tmp
    - name: varlog
      mountPath: /var/log
  volumes:
  - name: tmp
    emptyDir: {}
  - name: varlog
    emptyDir: {}
```

### **RBAC Configuration**
```yaml
# k8s/rbac/api-gateway-rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: api-gateway-sa
  namespace: fintech-ai-prod

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: api-gateway-role
  namespace: fintech-ai-prod
rules:
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: api-gateway-rolebinding
  namespace: fintech-ai-prod
subjects:
- kind: ServiceAccount
  name: api-gateway-sa
  namespace: fintech-ai-prod
roleRef:
  kind: Role
  name: api-gateway-role
  apiGroup: rbac.authorization.k8s.io
```

## 💾 Backup & Recovery

### **Database Backup**
```bash
#!/bin/bash
# scripts/backup-database.sh

# Set variables
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="fintech_ai_prod"

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup PostgreSQL
kubectl exec -n fintech-ai-prod deployment/postgres -- \
  pg_dump -U $POSTGRES_USER -d $DB_NAME > $BACKUP_DIR/postgres_$DATE.sql

# Backup Redis
kubectl exec -n fintech-ai-prod deployment/redis -- \
  redis-cli --rdb $BACKUP_DIR/redis_$DATE.rdb

# Compress backups
tar -czf $BACKUP_DIR/backup_$DATE.tar.gz \
  $BACKUP_DIR/postgres_$DATE.sql \
  $BACKUP_DIR/redis_$DATE.rdb

# Upload to cloud storage
az storage blob upload \
  --account-name fintech-ai-backups \
  --container-name database-backups \
  --name backup_$DATE.tar.gz \
  --file $BACKUP_DIR/backup_$DATE.tar.gz

# Clean up local files
rm $BACKUP_DIR/postgres_$DATE.sql
rm $BACKUP_DIR/redis_$DATE.rdb
rm $BACKUP_DIR/backup_$DATE.tar.gz
```

### **Application Backup**
```bash
#!/bin/bash
# scripts/backup-application.sh

# Backup Kubernetes resources
kubectl get all -n fintech-ai-prod -o yaml > backup_$(date +%Y%m%d_%H%M%S).yaml

# Backup persistent volumes
kubectl get pvc -n fintech-ai-prod -o yaml > pvc_backup_$(date +%Y%m%d_%H%M%S).yaml

# Backup secrets and configmaps
kubectl get secrets -n fintech-ai-prod -o yaml > secrets_backup_$(date +%Y%m%d_%H%M%S).yaml
kubectl get configmaps -n fintech-ai-prod -o yaml > configmaps_backup_$(date +%Y%m%d_%H%M%S).yaml
```

### **Recovery Procedures**
```bash
#!/bin/bash
# scripts/recover-database.sh

# Restore PostgreSQL
kubectl exec -i -n fintech-ai-prod deployment/postgres -- \
  psql -U $POSTGRES_USER -d $DB_NAME < backup_20240115_103000.sql

# Restore Redis
kubectl cp backup_20240115_103000.rdb fintech-ai-prod/redis-0:/data/dump.rdb
kubectl exec -n fintech-ai-prod deployment/redis -- redis-cli BGREWRITEAOF
```

## 📈 Scaling

### **Horizontal Pod Autoscaling**
```yaml
# k8s/hpa/api-gateway-hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-gateway-hpa
  namespace: fintech-ai-prod
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-gateway
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
```

### **Vertical Pod Autoscaling**
```yaml
# k8s/vpa/api-gateway-vpa.yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: api-gateway-vpa
  namespace: fintech-ai-prod
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-gateway
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: '*'
      minAllowed:
        cpu: 100m
        memory: 50Mi
      maxAllowed:
        cpu: 1
        memory: 500Mi
      controlledValues: RequestsAndLimits
```

### **Cluster Autoscaling**
```yaml
# k8s/cluster-autoscaler/cluster-autoscaler.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-autoscaler
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cluster-autoscaler
  template:
    metadata:
      labels:
        app: cluster-autoscaler
    spec:
      serviceAccountName: cluster-autoscaler
      containers:
      - image: k8s.gcr.io/autoscaling/cluster-autoscaler:v1.28.0
        name: cluster-autoscaler
        resources:
          limits:
            cpu: 100m
            memory: 300Mi
          requests:
            cpu: 100m
            memory: 300Mi
        command:
        - ./cluster-autoscaler
        - --v=4
        - --stderrthreshold=info
        - --cloud-provider=azure
        - --skip-nodes-with-local-storage=false
        - --expander=least-waste
        - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/fintech-ai-prod
        - --max-nodes-total=20
        - --scale-down-delay-after-add=10m
        - --scale-down-unneeded=10m
        - --scale-down-delay-after-delete=10s
        - --scale-down-delay-after-failure=3m
        - --unremovable-node-recheck-timeout=5m
        volumeMounts:
        - name: ssl-certs
          mountPath: /etc/ssl/certs/ca-certificates.crt
          readOnly: true
      volumes:
      - name: ssl-certs
        hostPath:
          path: "/etc/ssl/certs/ca-bundle.crt"
```

---

**For additional support**, check our [Operations Wiki](https://wiki.fintech-ai-platform.com/ops) or contact the DevOps team at devops@fintech-ai-platform.com 