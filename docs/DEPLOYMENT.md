# Deployment Guide

This guide covers deploying BEIE Nexus across different environments.

## Environments

### Local Development

#### Prerequisites
- Node.js 22+
- Bun 1.0+
- Docker & Docker Compose
- Git

#### Setup
1. Clone the repository:
```bash
git clone https://github.com/affiliatedarchitecturegroupdev-cmyk/Bellwether-E-I-Engineering.git
cd Bellwether-E-I-Engineering
```

2. Install dependencies:
```bash
bun install
```

3. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your local configuration
```

4. Start development environment:
```bash
# Start all services
docker-compose -f docker-compose.dev.yml up -d

# Start Next.js app
bun run dev

# Start API Gateway
bun run dev:api
```

5. Access the application:
- Frontend: http://localhost:3000
- API: http://localhost:3001
- API Docs: http://localhost:3001/api/docs

### Development Environment (Coolify)

#### Prerequisites
- Coolify VPS instance
- Domain configured

#### Deployment Steps
1. Connect repository to Coolify
2. Create applications for each service:
   - `web-public`: Next.js app
   - `web-dashboard`: Angular app
   - `api-gateway`: NestJS app
   - `service-ai`: Python FastAPI
   - `service-chat`: Elixir Phoenix

3. Configure environment variables in Coolify
4. Set up databases:
   - PostgreSQL for core data
   - MongoDB for catalogue
   - Redis for caching

5. Configure reverse proxy and SSL

### Staging Environment (AWS EKS)

#### Prerequisites
- AWS account with appropriate permissions
- kubectl configured
- Helm 3.x

#### Deployment Steps
1. Set up EKS cluster:
```bash
# Using Terraform
cd infrastructure/terraform
terraform init
terraform plan
terraform apply
```

2. Configure kubectl:
```bash
aws eks update-kubeconfig --name beie-staging --region af-south-1
```

3. Install required Helm charts:
```bash
# cert-manager for SSL
helm install cert-manager cert-manager/cert-manager --namespace cert-manager --create-namespace

# External DNS
helm install external-dns external-dns/external-dns --namespace external-dns --create-namespace

# Ingress controller
helm install nginx-ingress ingress-nginx/ingress-nginx --namespace ingress --create-namespace
```

4. Deploy applications:
```bash
# Deploy to staging
helm upgrade --install api-gateway ./charts/api-gateway --namespace beie-core --set environment=staging
```

5. Set up monitoring:
```bash
# Prometheus + Grafana
helm install monitoring ./charts/monitoring --namespace monitoring --create-namespace
```

### Production Environment (AWS EKS)

#### Prerequisites
- Production EKS cluster
- Load balancer configured
- CDN (Cloudflare) set up

#### Deployment Steps
1. Deploy using GitOps (ArgoCD recommended)
2. Blue-green deployment strategy
3. Database migrations run before deployment
4. Smoke tests executed post-deployment
5. Rollback plan ready

#### High Availability Setup
- Multi-AZ deployment
- Load balancer with health checks
- Database read replicas
- Redis cluster
- CDN for static assets

## Configuration

### Environment Variables

#### Core Application
```bash
# Database
DATABASE_URL=postgresql://user:pass@host:5432/db

# Authentication
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
JWT_SECRET=your-jwt-secret

# External Services
REDIS_URL=redis://host:6379
KAFKA_BROKERS=broker1:9092,broker2:9092
```

#### AI Services
```bash
ANTHROPIC_API_KEY=your-anthropic-key
OPENAI_API_KEY=your-openai-key
PINECONE_API_KEY=your-pinecone-key
```

#### Blockchain
```bash
POLYGON_RPC_URL=https://polygon-rpc.com
BLOCKCHAIN_PRIVATE_KEY=encrypted-private-key
IPFS_API_URL=https://ipfs.infura.io:5001
```

### Secrets Management

Use HashiCorp Vault for production secrets:
- Database credentials
- API keys
- TLS certificates
- Blockchain keys

### Database Setup

#### PostgreSQL
```sql
-- Create databases
CREATE DATABASE beie_core;
CREATE DATABASE beie_auth;

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
```

#### MongoDB
```javascript
// Create collections
db.createCollection("products");
db.createCollection("categories");

// Create indexes
db.products.createIndex({ sku: 1 }, { unique: true });
db.products.createIndex({ "category.l1": 1, "category.l2": 1 });
```

#### Redis
```bash
# Configure persistence
save 60 1000  # Save every 60 seconds if 1000 keys changed
```

## Monitoring & Observability

### Application Monitoring
- **Prometheus**: Metrics collection
- **Grafana**: Dashboards and visualization
- **Jaeger**: Distributed tracing
- **ELK Stack**: Log aggregation

### Infrastructure Monitoring
- **AWS CloudWatch**: AWS service metrics
- **Datadog**: Comprehensive monitoring
- **New Relic**: Application performance

### Alerting
- **PagerDuty**: Incident response
- **Slack**: Team notifications
- **Email**: Client communications

## Backup & Recovery

### Database Backups
- **PostgreSQL**: Daily snapshots, WAL archiving
- **MongoDB**: Daily snapshots via Atlas
- **Redis**: RDB snapshots every 6 hours

### Recovery Procedures
1. Identify failure point
2. Restore from backup
3. Replay transactions if needed
4. Verify data integrity
5. Update monitoring

## Security Hardening

### Network Security
- VPC isolation
- Security groups with least privilege
- WAF rules (Cloudflare)
- DDoS protection

### Application Security
- Input validation
- Rate limiting
- CORS configuration
- Security headers

### Compliance
- SOC 2 Type II
- ISO 27001
- POPIA compliance
- Regular security audits

## Performance Optimization

### Frontend
- Code splitting
- Image optimization
- CDN delivery
- Service worker caching

### Backend
- Database query optimization
- Caching layers
- Horizontal scaling
- Load balancing

### Database
- Connection pooling
- Query optimization
- Index management
- Read replicas

## Troubleshooting

### Common Issues

#### Application Won't Start
- Check environment variables
- Verify database connectivity
- Check logs for errors
- Ensure dependencies are installed

#### High CPU Usage
- Profile application performance
- Check for memory leaks
- Optimize database queries
- Scale horizontally

#### Database Connection Issues
- Check connection limits
- Verify credentials
- Monitor connection pool
- Check network connectivity

### Logs & Debugging
- Application logs: `/var/log/beie/`
- Database logs: PostgreSQL/MongoDB logs
- Infrastructure logs: CloudWatch/Kubernetes logs

## Support

For deployment assistance:
- Email: devops@beie.co.za
- Documentation: https://docs.beie.co.za/deployment
- Chat: #devops Slack channel