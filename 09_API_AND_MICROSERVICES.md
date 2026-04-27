# BEIE Nexus — API Gateway & Microservices Specification
**Document:** API-001 | **Version:** 1.0.0

---

## 1. API Gateway Architecture (NestJS)

### 1.1 Gateway Responsibilities

The NestJS API Gateway is the **single entry point** for all client traffic. It:
- Authenticates every inbound request (JWT validation)
- Enforces rate limiting per client and endpoint
- Routes requests to the correct downstream microservice
- Aggregates responses from multiple services (BFF pattern)
- Handles request/response transformation and validation
- Emits distributed traces (Jaeger) and metrics (Prometheus)
- Manages WebSocket upgrades for real-time features

### 1.2 Gateway Project Structure

```
apps/api-gateway/
├── src/
│   ├── main.ts                     # Bootstrap, global pipes, interceptors
│   ├── app.module.ts
│   ├── config/
│   │   ├── configuration.ts        # Env validation with Zod
│   │   └── throttle.config.ts
│   ├── auth/
│   │   ├── auth.guard.ts           # JWT validation guard
│   │   ├── roles.guard.ts          # RBAC guard
│   │   ├── auth.middleware.ts      # Request enrichment
│   │   └── supabase.strategy.ts
│   ├── common/
│   │   ├── interceptors/
│   │   │   ├── logging.interceptor.ts
│   │   │   ├── transform.interceptor.ts  # Response envelope
│   │   │   └── timeout.interceptor.ts
│   │   ├── filters/
│   │   │   └── all-exceptions.filter.ts
│   │   ├── pipes/
│   │   │   └── validation.pipe.ts        # class-validator global pipe
│   │   └── decorators/
│   │       ├── current-user.decorator.ts
│   │       └── public.decorator.ts       # Bypass auth for public routes
│   ├── modules/
│   │   ├── projects/               # Proxy to project service
│   │   ├── ecommerce/              # Proxy to e-commerce service
│   │   ├── clients/                # Proxy to CRM service
│   │   ├── erp/                    # Proxy to ERP service
│   │   ├── ai/                     # Proxy to AI service
│   │   ├── chat/                   # WebSocket proxy to Elixir
│   │   ├── blockchain/             # Proxy to Rust bridge
│   │   └── notifications/
│   └── health/
│       └── health.controller.ts    # /health, /ready, /metrics
```

### 1.3 Global Middleware Stack

```typescript
// main.ts — applied in order
async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // 1. Helmet (security headers)
  app.use(helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'", "'nonce-{nonce}'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", "data:", "https://cdn.beie.co.za"],
        connectSrc: ["'self'", "https://api.beie.co.za", "wss://chat.beie.co.za"],
      },
    },
    hsts: { maxAge: 31536000, includeSubDomains: true, preload: true },
  }));

  // 2. CORS (allowlist only)
  app.enableCors({
    origin: [
      'https://beie.co.za',
      'https://app.beie.co.za',
      'https://portal.beie.co.za',
      ...(isDev ? ['http://localhost:3000', 'http://localhost:4200'] : []),
    ],
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-ID'],
    credentials: true,
    maxAge: 86400,
  });

  // 3. Global validation pipe
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,           // Strip unknown properties
    forbidNonWhitelisted: true,
    transform: true,           // Auto-transform primitives
    transformOptions: { enableImplicitConversion: true },
  }));

  // 4. Global response transform
  app.useGlobalInterceptors(new TransformInterceptor());

  // 5. Global exception filter
  app.useGlobalFilters(new AllExceptionsFilter());

  // 6. Compression
  app.use(compression());

  // 7. Request ID (for tracing)
  app.use((req, res, next) => {
    req.id = req.headers['x-request-id'] || uuidv7();
    res.setHeader('X-Request-ID', req.id);
    next();
  });

  await app.listen(3000);
}
```

---

## 2. Microservice Communication Patterns

### 2.1 Synchronous (REST/gRPC)

Used for: request-response patterns requiring immediate data

```typescript
// NestJS microservice client configuration
@Module({
  imports: [
    ClientsModule.registerAsync([
      {
        name: 'PROJECT_SERVICE',
        useFactory: (config: ConfigService) => ({
          transport: Transport.GRPC,
          options: {
            url: config.get('PROJECT_SERVICE_URL'),
            package: 'project',
            protoPath: join(__dirname, '../proto/project.proto'),
            channelOptions: {
              'grpc.keepalive_time_ms': 30000,
              'grpc.max_receive_message_length': 10 * 1024 * 1024, // 10MB
            },
          },
        }),
        inject: [ConfigService],
      },
    ]),
  ],
})
export class ProjectsModule {}
```

### 2.2 Asynchronous (Kafka via Upstash)

Used for: events, notifications, audit anchoring, AI tasks

```typescript
// Topic naming convention: beie.[domain].[entity].[action]
const KAFKA_TOPICS = {
  // Projects
  PROJECT_CREATED:       'beie.projects.project.created',
  PROJECT_MILESTONE:     'beie.projects.milestone.completed',
  PROJECT_CLOSED:        'beie.projects.project.closed',
  
  // E-Commerce
  ORDER_PLACED:          'beie.ecommerce.order.placed',
  ORDER_PAID:            'beie.ecommerce.order.paid',
  INVENTORY_LOW:         'beie.ecommerce.inventory.low',
  
  // Finance
  INVOICE_ISSUED:        'beie.erp.invoice.issued',
  PAYMENT_RECEIVED:      'beie.erp.payment.received',
  
  // AI
  AI_TASK_REQUESTED:     'beie.ai.task.requested',
  AI_TASK_COMPLETED:     'beie.ai.task.completed',
  AI_APPROVAL_REQUIRED:  'beie.ai.approval.required',
  
  // Blockchain
  BLOCKCHAIN_QUEUE:      'beie.blockchain.anchor.queued',
  BLOCKCHAIN_CONFIRMED:  'beie.blockchain.anchor.confirmed',
  
  // Notifications
  NOTIFICATION_SEND:     'beie.notifications.notification.send',
} as const;

// Producer (NestJS)
@Injectable()
export class EventPublisher {
  constructor(
    @Inject('KAFKA_CLIENT') private kafka: ClientKafka,
  ) {}

  async publish<T>(topic: string, payload: NexusEvent<T>): Promise<void> {
    await this.kafka.emit(topic, {
      key: payload.aggregateId,    // Partition by entity for ordering
      value: JSON.stringify(payload),
      headers: {
        'correlation-id': payload.metadata.correlationId,
        'tenant-id': payload.tenantId,
        'event-version': payload.version,
      },
    });
  }
}
```

### 2.3 WebSocket (Real-Time)

```typescript
// NestJS WebSocket Gateway (delegates to Elixir for chat)
@WebSocketGateway({
  namespace: '/realtime',
  cors: { origin: ALLOWED_ORIGINS },
  transports: ['websocket'],
})
export class RealtimeGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() server: Server;

  async handleConnection(client: Socket) {
    const user = await this.authService.validateSocketToken(
      client.handshake.auth.token
    );
    if (!user) { client.disconnect(); return; }
    
    client.join(`tenant:${user.tenantId}`);
    client.join(`user:${user.id}`);
    
    // Join project rooms for subscribed projects
    const projectIds = await this.projectService.getUserProjectIds(user.id);
    projectIds.forEach(id => client.join(`project:${id}`));
  }

  // Broadcast project update to all project members
  broadcastProjectUpdate(projectId: string, event: ProjectEvent) {
    this.server.to(`project:${projectId}`).emit('project:update', event);
  }
}
```

---

## 3. GraphQL Federation (Phase 2)

### 3.1 Subgraph Architecture

```
Apollo Router (Federation Gateway)
├── Projects Subgraph    (NestJS)
├── E-Commerce Subgraph  (NestJS)
├── ERP Subgraph         (Kotlin/GraphQL)
├── AI Subgraph          (Python/Strawberry)
└── Users Subgraph       (NestJS)
```

### 3.2 Federation Type Extension Pattern

```graphql
# In Projects subgraph — extend User type defined in Users subgraph
extend type User @key(fields: "id") {
  id: ID! @external
  assignedProjects: [Project!]!
  taskLoad: TaskLoadSummary!
}

type Project @key(fields: "id") {
  id: ID!
  code: String!
  name: String!
  status: ProjectStatus!
  team: ProjectTeam!
  financials: ProjectFinancials!
  milestones: [Milestone!]!
  tasks(filter: TaskFilter, pagination: PaginationInput): TaskConnection!
  blockchainVerification: BlockchainRecord
}
```

---

## 4. Service Specifications

### 4.1 E-Commerce Service (NestJS)

```
apps/service-ecommerce/
├── src/
│   ├── catalogue/
│   │   ├── catalogue.service.ts    # MongoDB queries, search
│   │   ├── catalogue.controller.ts
│   │   ├── search/
│   │   │   └── search.service.ts   # Full-text + vector search
│   │   └── dto/
│   ├── pricing/
│   │   └── pricing.engine.ts       # Tier, discount, tax calculations
│   ├── cart/
│   │   └── cart.service.ts         # Redis-backed cart
│   ├── orders/
│   │   ├── orders.service.ts
│   │   ├── orders.saga.ts          # Distributed order saga
│   │   └── payment/
│   │       ├── peach.adapter.ts    # Peach Payments integration
│   │       └── stripe.adapter.ts   # Stripe fallback
│   ├── inventory/
│   │   └── inventory.service.ts
│   └── suppliers/
│       └── supplier-portal.service.ts
```

**Key Endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/v1/catalogue/products` | List products (paginated, filtered) |
| GET | `/api/v1/catalogue/products/:sku` | Single product detail |
| GET | `/api/v1/catalogue/search?q=` | Full-text + semantic search |
| GET | `/api/v1/catalogue/categories` | Category tree |
| POST | `/api/v1/cart/items` | Add to cart |
| PUT | `/api/v1/cart/items/:sku` | Update quantity |
| DELETE | `/api/v1/cart/items/:sku` | Remove from cart |
| GET | `/api/v1/cart` | Get current cart |
| POST | `/api/v1/orders` | Place order |
| GET | `/api/v1/orders/:id` | Order detail |
| GET | `/api/v1/orders` | Order history (paginated) |
| POST | `/api/v1/orders/:id/payment` | Initiate payment |
| POST | `/api/v1/webhooks/peach` | Peach Payments webhook |

### 4.2 AI Orchestration Service (Python + FastAPI)

```
apps/service-ai/
├── src/
│   ├── main.py                     # FastAPI app
│   ├── agents/
│   │   ├── base_agent.py           # Abstract agent with HITL logic
│   │   ├── estimating_agent.py     # LangGraph workflow
│   │   ├── compliance_agent.py
│   │   ├── tender_agent.py         # CrewAI crew
│   │   ├── document_agent.py
│   │   ├── maintenance_agent.py
│   │   ├── support_agent.py
│   │   ├── catalogue_agent.py      # LlamaIndex RAG
│   │   └── scheduling_agent.py
│   ├── graphs/
│   │   └── *.py                    # LangGraph state graphs
│   ├── crews/
│   │   └── *.py                    # CrewAI crews
│   ├── tools/
│   │   ├── supabase_tool.py        # DB queries
│   │   ├── document_tool.py        # PDF/DOCX generation
│   │   ├── pricing_tool.py
│   │   └── compliance_tool.py
│   ├── rag/
│   │   ├── catalogue_index.py      # LlamaIndex product catalogue
│   │   ├── standards_index.py      # SANS standards RAG
│   │   └── ingestion.py
│   ├── hitl/
│   │   └── hitl_manager.py         # HITL gate logic
│   ├── audit/
│   │   └── audit_logger.py         # All agent actions logged
│   └── models/
│       └── schemas.py              # Pydantic models
```

**Key Endpoints:**

| Method | Path | Description |
|--------|------|-------------|
| POST | `/ai/v1/estimate` | Generate project estimate |
| POST | `/ai/v1/compliance/check` | Check design for SANS compliance |
| POST | `/ai/v1/tender/generate` | Multi-agent tender document |
| POST | `/ai/v1/document/generate` | Generate report/document |
| POST | `/ai/v1/support/draft` | Draft client support reply |
| GET | `/ai/v1/tasks/:id` | Get async task status |
| POST | `/ai/v1/tasks/:id/approve` | Human approval of AI proposal |
| POST | `/ai/v1/tasks/:id/reject` | Human rejection of AI proposal |
| GET | `/ai/v1/audit` | Agent audit log (paginated) |

### 4.3 Chat Service (Elixir/Phoenix)

```
apps/service-chat/
├── lib/
│   ├── nexus_chat/
│   │   ├── application.ex
│   │   ├── accounts/               # User presence, status
│   │   ├── messaging/
│   │   │   ├── message.ex
│   │   │   ├── channel.ex
│   │   │   ├── thread.ex
│   │   │   └── reaction.ex
│   │   ├── workspaces/
│   │   └── notifications/
│   └── nexus_chat_web/
│       ├── channels/
│       │   ├── room_channel.ex     # Per-channel WebSocket
│       │   ├── presence.ex         # Phoenix Presence
│       │   └── user_socket.ex
│       ├── controllers/
│       └── router.ex
├── priv/
│   └── repo/migrations/
└── test/
```

### 4.4 Blockchain Bridge Service (Rust)

```
apps/service-blockchain/
├── src/
│   ├── main.rs                     # Tokio async runtime
│   ├── config.rs
│   ├── consumer/
│   │   └── kafka_consumer.rs       # Consume BLOCKCHAIN_QUEUE topic
│   ├── contracts/
│   │   ├── project_registry.rs     # ethers-rs contract bindings
│   │   ├── compliance_registry.rs
│   │   └── financial_registry.rs
│   ├── ipfs/
│   │   └── ipfs_client.rs          # Pin documents to IPFS
│   ├── hasher/
│   │   └── payload_hasher.rs       # SHA-256 payload hashing
│   ├── signer/
│   │   └── vault_signer.rs         # Vault transit engine signing
│   └── storage/
│       └── ref_store.rs            # Store blockchain refs back in Supabase
```

**Processing Flow:**

```rust
// For each Kafka message on BLOCKCHAIN_QUEUE:
async fn process_anchor_event(event: NexusEvent) -> Result<BlockchainRef> {
    // 1. Validate event schema
    let validated = validate_event(&event)?;
    
    // 2. Pin full payload to IPFS
    let ipfs_cid = ipfs_client.pin_json(&validated.payload).await?;
    
    // 3. Hash the payload
    let payload_hash = sha256_hash(&validated.payload);
    
    // 4. Select correct contract based on event type
    let contract = select_contract(&validated.event_type)?;
    
    // 5. Sign and submit transaction
    let tx_hash = contract
        .record_event(
            validated.aggregate_id,
            payload_hash,
            ipfs_cid.clone(),
            validated.event_type,
        )
        .send()
        .await?
        .await?
        .transaction_hash;
    
    // 6. Store reference back in Supabase
    supabase_client
        .update_blockchain_ref(&validated.aggregate_id, &tx_hash.to_string())
        .await?;
    
    // 7. Publish confirmation event
    kafka_producer
        .publish(BLOCKCHAIN_CONFIRMED, BlockchainConfirmation { tx_hash, ipfs_cid })
        .await?;
    
    Ok(BlockchainRef { tx_hash, ipfs_cid })
}
```

---

## 5. Inter-Service Contracts (Proto Definitions)

### 5.1 Project Service Proto

```protobuf
syntax = "proto3";
package beie.project.v1;

service ProjectService {
  rpc GetProject (GetProjectRequest) returns (Project);
  rpc ListProjects (ListProjectsRequest) returns (ListProjectsResponse);
  rpc CreateProject (CreateProjectRequest) returns (Project);
  rpc UpdateProjectStatus (UpdateStatusRequest) returns (Project);
  rpc GetUserProjectIds (GetUserProjectIdsRequest) returns (ProjectIdsResponse);
}

message Project {
  string id = 1;
  string code = 2;
  string name = 3;
  string status = 4;
  string tenant_id = 5;
  ProjectTeam team = 6;
  ProjectFinancials financials = 7;
  google.protobuf.Timestamp created_at = 8;
  google.protobuf.Timestamp updated_at = 9;
}

message ProjectTeam {
  string project_manager_id = 1;
  string engineer_id = 2;
  repeated string technician_ids = 3;
}

message ProjectFinancials {
  double contract_value = 1;
  double invoiced_to_date = 2;
  double received_to_date = 3;
  string currency = 4;
}
```

---

## 6. Health & Observability

### 6.1 Health Check Endpoints (All Services)

```
GET /health        → 200 if service is up (used by K8s liveness probe)
GET /ready         → 200 if service can handle traffic (readiness probe)
GET /metrics       → Prometheus metrics endpoint
```

### 6.2 Standard Prometheus Metrics (All Services)

```
# HTTP
http_requests_total{method, path, status}
http_request_duration_seconds{method, path, quantile}

# Business metrics (per service)
beie_projects_created_total
beie_orders_placed_total
beie_orders_value_zar_total
beie_ai_tasks_total{agent, status}
beie_blockchain_anchors_total{event_type, status}
beie_chat_messages_total
beie_invoice_value_zar_total
```

### 6.3 Distributed Tracing

Every request carries `X-Request-ID` and `X-Correlation-ID` headers.
All services emit OpenTelemetry spans to Jaeger.
Trace sampling: 100% in dev/staging, 10% in production (100% for errors).

---

*This document governs all inter-service communication contracts. Breaking changes require a versioning bump and migration plan.*
