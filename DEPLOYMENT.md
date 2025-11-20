# FinCategorizer - Production Deployment Guide

## Table of Contents
1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Environment Setup](#environment-setup)
3. [Docker Deployment](#docker-deployment)
4. [Kubernetes Deployment](#kubernetes-deployment)
5. [AWS Deployment](#aws-deployment)
6. [Azure Deployment](#azure-deployment)
7. [GCP Deployment](#gcp-deployment)
8. [CI/CD Pipeline](#cicd-pipeline)
9. [Monitoring & Logging](#monitoring--logging)
10. [Security Hardening](#security-hardening)
11. [Backup & Disaster Recovery](#backup--disaster-recovery)
12. [Performance Tuning](#performance-tuning)

---

## Pre-Deployment Checklist

### Security
- [ ] Change default JWT secret (`JWT_SECRET` environment variable)
- [ ] Configure OAuth 2.0 with real Google credentials
- [ ] Enable TLS/SSL certificates (Let's Encrypt or commercial CA)
- [ ] Update database passwords (MySQL root and app user)
- [ ] Set Redis password for production
- [ ] Review and update CORS allowed origins
- [ ] Enable firewall rules (ports 80, 443, 8080 only)
- [ ] Set up API rate limiting per client/IP

### Database
- [ ] Set up automated backups (daily MySQL dumps)
- [ ] Configure MySQL replication (master-slave setup)
- [ ] Enable MySQL slow query log
- [ ] Optimize MySQL configuration (InnoDB buffer pool, connections)
- [ ] Create read-only replica for analytics queries

### Infrastructure
- [ ] Provision VMs or Kubernetes cluster
- [ ] Set up load balancer (AWS ALB/Azure LB/GCP LB)
- [ ] Configure CDN for frontend assets (CloudFront/Azure CDN)
- [ ] Set up DNS records (A/CNAME for api.yourdomain.com)
- [ ] Configure auto-scaling policies

### Monitoring
- [ ] Deploy Prometheus for metrics collection
- [ ] Deploy Grafana for dashboards
- [ ] Set up ELK stack (Elasticsearch, Logstash, Kibana) for logs
- [ ] Configure alerting (PagerDuty, Slack, email)
- [ ] Set up uptime monitoring (Pingdom, UptimeRobot)

### Performance
- [ ] Enable Redis persistence (AOF or RDB)
- [ ] Configure CDN caching rules
- [ ] Set up database connection pooling
- [ ] Enable gzip compression in Nginx
- [ ] Optimize Docker images (multi-stage builds)

---

## Environment Setup

### Production Environment Variables

Create `.env.production` file:

```bash
# Database
MYSQL_HOST=mysql-prod.example.com
MYSQL_PORT=3306
MYSQL_DATABASE=fincategorizer
MYSQL_USER=fincategorizer_app
MYSQL_PASSWORD=<STRONG_PASSWORD>
MYSQL_ROOT_PASSWORD=<STRONG_ROOT_PASSWORD>

# Redis
REDIS_HOST=redis-prod.example.com
REDIS_PORT=6379
REDIS_PASSWORD=<STRONG_REDIS_PASSWORD>

# JWT
JWT_SECRET=<GENERATE_STRONG_RANDOM_KEY>
JWT_EXPIRATION=3600000
JWT_REFRESH_EXPIRATION=604800000

# OAuth 2.0 (Google)
GOOGLE_CLIENT_ID=<YOUR_GOOGLE_CLIENT_ID>
GOOGLE_CLIENT_SECRET=<YOUR_GOOGLE_CLIENT_SECRET>

# Frontend
FRONTEND_URL=https://app.fincategorizer.com
REACT_APP_API_URL=https://api.fincategorizer.com

# Service URLs (Internal)
TRANSACTION_SERVICE_HOST=transaction-service
TRANSACTION_SERVICE_PORT=8081
ML_SERVICE_HOST=ml-inference-service
ML_SERVICE_PORT=8000
CATEGORY_SERVICE_HOST=category-service
CATEGORY_SERVICE_PORT=8082
ANALYTICS_SERVICE_HOST=analytics-service
ANALYTICS_SERVICE_PORT=8083

# Logging
LOG_LEVEL=INFO
SENTRY_DSN=<YOUR_SENTRY_DSN>

# Email (for notifications)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=noreply@fincategorizer.com
SMTP_PASSWORD=<EMAIL_PASSWORD>
```

### Generate Strong JWT Secret

```bash
# Linux/Mac
openssl rand -base64 64

# Or use Python
python -c "import secrets; print(secrets.token_urlsafe(64))"
```

---

## Docker Deployment

### Using Docker Compose (Recommended for Single Server)

1. **Clone Repository**:
```bash
git clone https://github.com/Jaikumar96/fincategorizer.git
cd FinCategorizer
```

2. **Create Production Config**:
```bash
cp .env.example .env.production
# Edit .env.production with your production values
```

3. **Build and Deploy**:
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
```

4. **Verify Deployment**:
```bash
# Check all services are running
docker-compose ps

# Check logs
docker-compose logs -f

# Test API
curl http://localhost:8080/actuator/health
```

### Production Docker Compose (`docker-compose.prod.yml`)

```yaml
version: '3.8'

services:
  mysql:
    restart: always
    volumes:
      - /data/mysql:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}

  redis:
    restart: always
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    volumes:
      - /data/redis:/data

  gateway-service:
    restart: always
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - JWT_SECRET=${JWT_SECRET}
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M

  frontend:
    restart: always
    volumes:
      - /etc/letsencrypt:/etc/letsencrypt:ro
```

### SSL Certificate Setup (Let's Encrypt)

```bash
# Install Certbot
sudo apt-get update
sudo apt-get install certbot

# Get certificate
sudo certbot certonly --standalone -d api.fincategorizer.com -d app.fincategorizer.com

# Update Nginx config to use certificates
# Certificates will be in /etc/letsencrypt/live/api.fincategorizer.com/

# Auto-renewal cron job
sudo crontab -e
# Add: 0 3 * * * certbot renew --quiet
```

---

## Kubernetes Deployment

### Prerequisites
- Kubernetes cluster (EKS, AKS, GKE, or self-hosted)
- kubectl configured
- Helm 3 installed

### 1. Create Namespace

```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: fincategorizer
```

```bash
kubectl apply -f namespace.yaml
```

### 2. Create Secrets

```bash
# Database credentials
kubectl create secret generic mysql-secret \
  --from-literal=root-password=<ROOT_PASSWORD> \
  --from-literal=user-password=<USER_PASSWORD> \
  -n fincategorizer

# JWT secret
kubectl create secret generic jwt-secret \
  --from-literal=secret=<JWT_SECRET> \
  -n fincategorizer

# Google OAuth
kubectl create secret generic oauth-secret \
  --from-literal=client-id=<GOOGLE_CLIENT_ID> \
  --from-literal=client-secret=<GOOGLE_CLIENT_SECRET> \
  -n fincategorizer
```

### 3. Deploy MySQL with StatefulSet

```yaml
# mysql-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
  namespace: fincategorizer
spec:
  serviceName: mysql
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: root-password
        - name: MYSQL_DATABASE
          value: fincategorizer
        ports:
        - containerPort: 3306
          name: mysql
        volumeMounts:
        - name: mysql-data
          mountPath: /var/lib/mysql
        - name: init-script
          mountPath: /docker-entrypoint-initdb.d
      volumes:
      - name: init-script
        configMap:
          name: mysql-init
  volumeClaimTemplates:
  - metadata:
      name: mysql-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 20Gi
---
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: fincategorizer
spec:
  ports:
  - port: 3306
  selector:
    app: mysql
  clusterIP: None
```

### 4. Deploy Microservices

```yaml
# gateway-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gateway-service
  namespace: fincategorizer
spec:
  replicas: 3
  selector:
    matchLabels:
      app: gateway-service
  template:
    metadata:
      labels:
        app: gateway-service
    spec:
      containers:
      - name: gateway
        image: fincategorizer/gateway-service:latest
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "k8s"
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: jwt-secret
              key: secret
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: gateway-service
  namespace: fincategorizer
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: gateway-service
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: gateway-hpa
  namespace: fincategorizer
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: gateway-service
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
```

### 5. Deploy Ingress (NGINX Ingress Controller)

```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: fincategorizer-ingress
  namespace: fincategorizer
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rate-limit: "1000"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - api.fincategorizer.com
    - app.fincategorizer.com
    secretName: fincategorizer-tls
  rules:
  - host: api.fincategorizer.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: gateway-service
            port:
              number: 80
  - host: app.fincategorizer.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
```

### 6. Deploy Complete Stack

```bash
# Apply all configurations
kubectl apply -f k8s/

# Check deployments
kubectl get pods -n fincategorizer
kubectl get services -n fincategorizer
kubectl get ingress -n fincategorizer

# View logs
kubectl logs -f deployment/gateway-service -n fincategorizer
```

---

## AWS Deployment

### Using EKS (Elastic Kubernetes Service)

1. **Create EKS Cluster**:
```bash
eksctl create cluster \
  --name fincategorizer \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 5 \
  --managed
```

2. **Deploy RDS MySQL**:
```bash
aws rds create-db-instance \
  --db-instance-identifier fincategorizer-db \
  --db-instance-class db.t3.medium \
  --engine mysql \
  --engine-version 8.0.35 \
  --master-username admin \
  --master-user-password <PASSWORD> \
  --allocated-storage 100 \
  --vpc-security-group-ids sg-xxxxx \
  --db-subnet-group-name fincategorizer-subnet \
  --backup-retention-period 7 \
  --multi-az
```

3. **Deploy ElastiCache Redis**:
```bash
aws elasticache create-replication-group \
  --replication-group-id fincategorizer-redis \
  --replication-group-description "Redis for FinCategorizer" \
  --engine redis \
  --cache-node-type cache.t3.medium \
  --num-cache-clusters 2 \
  --automatic-failover-enabled
```

4. **Deploy Application to EKS**:
```bash
# Update kubeconfig
aws eks update-kubeconfig --name fincategorizer --region us-east-1

# Deploy services
kubectl apply -f k8s/
```

5. **Set up Application Load Balancer**:
```bash
# Install AWS Load Balancer Controller
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=fincategorizer
```

---

## CI/CD Pipeline

### GitHub Actions Workflow

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches:
      - main

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up JDK 17
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'
      
      - name: Run Tests
        run: |
          cd backend/gateway-service
          mvn test

  build-and-push:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: Build and Push Docker Images
        run: |
          docker-compose build
          docker-compose push

  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure kubectl
        uses: azure/k8s-set-context@v3
        with:
          method: kubeconfig
          kubeconfig: ${{ secrets.KUBE_CONFIG }}
      
      - name: Deploy to Kubernetes
        run: |
          kubectl apply -f k8s/
          kubectl rollout status deployment/gateway-service -n fincategorizer
```

---

## Monitoring & Logging

### Prometheus + Grafana

1. **Deploy Prometheus**:
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace
```

2. **Import Grafana Dashboards**:
- Spring Boot Metrics: Dashboard ID 4701
- MySQL Metrics: Dashboard ID 7362
- Redis Metrics: Dashboard ID 11835

3. **Alert Rules**:
```yaml
# prometheus-alerts.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-alerts
data:
  alerts.yml: |
    groups:
    - name: fincategorizer
      rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
      
      - alert: HighResponseTime
        expr: histogram_quantile(0.95, http_request_duration_seconds_bucket) > 1
        for: 5m
        labels:
          severity: warning
```

---

## Security Hardening

### Network Security
- Use VPC with private subnets for databases
- Enable network policies in Kubernetes
- Use AWS Security Groups or Azure NSGs
- Implement WAF (Web Application Firewall)

### Application Security
- Enable HTTPS only (redirect HTTP to HTTPS)
- Use HSTS headers
- Implement Content Security Policy (CSP)
- Regular security scanning (OWASP ZAP, SonarQube)

### Database Security
- Enable SSL/TLS for MySQL connections
- Rotate database credentials regularly
- Encrypt data at rest
- Regular security patches

---

## Backup & Disaster Recovery

### MySQL Backup

```bash
# Daily automated backup
0 2 * * * mysqldump -u root -p<PASSWORD> fincategorizer | gzip > /backups/fincategorizer-$(date +\%Y\%m\%d).sql.gz

# Backup to S3
aws s3 cp /backups/fincategorizer-$(date +\%Y\%m\%d).sql.gz s3://fincategorizer-backups/mysql/
```

### Disaster Recovery Plan

1. **RTO (Recovery Time Objective)**: 1 hour
2. **RPO (Recovery Point Objective)**: 24 hours
3. **Backup Strategy**:
   - Daily MySQL dumps to S3
   - Redis snapshots every 6 hours
   - Docker image backups in registry
4. **Recovery Procedure**:
   - Restore MySQL from latest backup
   - Deploy services from Docker registry
   - Verify data integrity
   - Update DNS if necessary

---

**End of Deployment Guide**
