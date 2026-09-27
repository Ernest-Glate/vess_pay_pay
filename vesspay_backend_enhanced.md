VESSPay Backend Development Prompt (ENHANCED VERSION)
TypeScript (NestJS) + Python (Django/FastAPI)

═══════════════════════════════════════════════════════════════
ROLE & CONTEXT
═══════════════════════════════════════════════════════════════

You are a senior fintech backend engineer building the production-grade backend for VESSPay 
(Visitor Easy Spend Secure), a wallet-based payment platform for tourists and diaspora in Ghana. 

CRITICAL: This system will handle REAL MONEY and must be:
✓ Bank-grade secure
✓ Regulator-ready (Bank of Ghana)
✓ Audit-compliant
✓ Fraud-resistant
✓ 99.9% uptime SLA

Build as if real money, real regulators, and real attackers exist.

═══════════════════════════════════════════════════════════════
SYSTEM ARCHITECTURE
═══════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────┐
│                      MOBILE APP (Flutter)                     │
│  - Wallet UI      - Payments      - KYC Forms      - History │
└─────────────┬───────────────────────────────────┬────────────┘
              │                                   │
              │ REST/GraphQL                      │ REST
              │                                   │
   ┌──────────▼─────────────┐         ┌──────────▼──────────┐
   │   TYPESCRIPT (NestJS)  │◄────────┤  PYTHON (FastAPI)   │
   │   MONEY CORE           │  Async  │  KYC & INTELLIGENCE │
   │   (System of Record)   │  Queue  │  (Risk & Identity)  │
   └────────┬───────────────┘         └──────────┬──────────┘
            │                                    │
   ┌────────▼────────────┐           ┌──────────▼──────────┐
   │  PostgreSQL (Money) │           │ PostgreSQL (KYC)    │
   │  - Wallets          │           │ - Users             │
   │  - Ledger           │           │ - Documents         │
   │  - Transactions     │           │ - Risk Scores       │
   └─────────────────────┘           └─────────────────────┘

CRITICAL RULES:
✗ NO shared database between services
✗ NO direct balance updates without ledger entry
✗ NO auto-approval of KYC without scoring
✗ NO hardcoded FX rates or fees
✗ NO mock payment logic in production

═══════════════════════════════════════════════════════════════
PART A: TYPESCRIPT (NESTJS) — MONEY CORE
═══════════════════════════════════════════════════════════════

RESPONSIBILITIES:
✓ Wallet creation and balance management
✓ Double-entry ledger accounting (immutable)
✓ FX conversion with configurable markup (default 2.5%)
✓ Card deposits (Stripe, Flutterwave, Paystack)
✓ MoMo payments (MTN, Vodafone, AirtelTigo) with provider abstraction
✓ Idempotent webhook handling
✓ Transaction lifecycle state machine
✓ Audit logs and daily reconciliation
✓ Master wallet float management

TECHNOLOGY STACK:
- NestJS (TypeScript)
- PostgreSQL 14+
- TypeORM or Prisma
- Redis (caching, rate limiting, queues)
- Bull Queue (async jobs)
- Winston (structured logging)
- Jest (testing)

POWERED MOBILE SCREENS:
✓ add_money_screen.dart
✓ wallet_screen.dart
✓ transactions_screen.dart
✓ transaction_history_screen.dart
✓ send_money_screen.dart
✓ request_money_screen.dart
✓ pay_momo_screen.dart
✓ currency_exchange_screen.dart
✓ exchange_success_screen.dart
✓ payment_success_screen.dart
✓ transaction_details_screen.dart
✓ dashboard_screen.dart

───────────────────────────────────────────────────────────────
DATABASE SCHEMA (PostgreSQL)
───────────────────────────────────────────────────────────────

-- Wallets
CREATE TABLE wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE,
    balance DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    currency VARCHAR(3) NOT NULL DEFAULT 'GHS',
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT positive_balance CHECK (balance >= 0),
    CONSTRAINT valid_status CHECK (status IN ('active', 'frozen', 'closed'))
);

-- Ledger Entries (Immutable Double-Entry)
CREATE TABLE ledger_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL REFERENCES wallets(id),
    transaction_id UUID NOT NULL,
    entry_type VARCHAR(10) NOT NULL,
    amount DECIMAL(18, 2) NOT NULL,
    balance_before DECIMAL(18, 2) NOT NULL,
    balance_after DECIMAL(18, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    description TEXT,
    metadata JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT valid_entry_type CHECK (entry_type IN ('DEBIT', 'CREDIT')),
    CONSTRAINT positive_amount CHECK (amount > 0)
);
CREATE INDEX idx_ledger_wallet_id ON ledger_entries(wallet_id);
CREATE INDEX idx_ledger_transaction_id ON ledger_entries(transaction_id);
CREATE INDEX idx_ledger_created_at ON ledger_entries(created_at DESC);

-- Transactions (State Machine)
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    idempotency_key VARCHAR(255) UNIQUE NOT NULL,
    user_id UUID NOT NULL,
    wallet_id UUID NOT NULL REFERENCES wallets(id),
    type VARCHAR(50) NOT NULL,
    amount DECIMAL(18, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    recipient_phone VARCHAR(20),
    recipient_network VARCHAR(50),
    external_transaction_id VARCHAR(255),
    fx_rate DECIMAL(18, 6),
    fx_spread_percent DECIMAL(5, 2),
    fee_amount DECIMAL(18, 2) DEFAULT 0.00,
    failure_reason TEXT,
    retry_count INT DEFAULT 0,
    max_retries INT DEFAULT 3,
    metadata JSONB,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP,
    expires_at TIMESTAMP,
    CONSTRAINT valid_transaction_type CHECK (type IN ('deposit', 'withdrawal', 'payment', 'refund', 'fee')),
    CONSTRAINT valid_status CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'refunded', 'expired'))
);
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_idempotency_key ON transactions(idempotency_key);
CREATE INDEX idx_transactions_created_at ON transactions(created_at DESC);

-- FX Rates (Historical)
CREATE TABLE fx_rates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_currency VARCHAR(3) NOT NULL,
    to_currency VARCHAR(3) NOT NULL,
    base_rate DECIMAL(18, 6) NOT NULL,
    spread_percent DECIMAL(5, 2) NOT NULL,
    effective_rate DECIMAL(18, 6) NOT NULL,
    source VARCHAR(100) NOT NULL,
    valid_from TIMESTAMP NOT NULL DEFAULT NOW(),
    valid_until TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_fx_rates_currencies ON fx_rates(from_currency, to_currency);
CREATE INDEX idx_fx_rates_valid_from ON fx_rates(valid_from DESC);

-- Audit Logs (Immutable)
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id VARCHAR(255),
    ip_address INET,
    user_agent TEXT,
    request_method VARCHAR(10),
    request_path VARCHAR(500),
    status_code INT,
    metadata JSONB,
    previous_hash VARCHAR(64),
    current_hash VARCHAR(64),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);

───────────────────────────────────────────────────────────────
CORE SERVICES IMPLEMENTATION
───────────────────────────────────────────────────────────────

1. WALLET SERVICE
   ✓ Create wallet on user registration
   ✓ Get balance (with pending amounts)
   ✓ Lock/unlock funds for pending transactions
   ✓ Freeze/unfreeze wallet
   ✓ Transaction history with pagination

2. LEDGER SERVICE
   ✓ Record double-entry (always DEBIT + CREDIT pair)
   ✓ Calculate new balance atomically
   ✓ Never allow ledger entry without balance update
   ✓ Verify ledger integrity (sum of all entries = current balance)

3. PAYMENT SERVICE
   ✓ Initiate payment (with idempotency)
   ✓ Process payment (state machine)
   ✓ Retry failed payments (exponential backoff)
   ✓ Refund failed payments
   ✓ Provider abstraction layer
   ✓ Webhook handling

4. FUNDING SERVICE
   ✓ Create deposit intent
   ✓ Process card payment (Stripe/Flutterwave)
   ✓ Apply FX conversion
   ✓ Credit wallet on success
   ✓ Webhook reconciliation

5. FX SERVICE
   ✓ Fetch real-time rates (cache 5 minutes)
   ✓ Apply configurable spread
   ✓ Store historical rates
   ✓ Lock rate for transaction duration

───────────────────────────────────────────────────────────────
TRANSACTION STATE MACHINE
───────────────────────────────────────────────────────────────

PENDING ──────► PROCESSING ──────► COMPLETED
   │                │                   │
   │                │                   │
   └──► EXPIRED     └──► FAILED ──► REFUNDING ──► REFUNDED
                          │
                          └──► RETRY (max 3x, exponential backoff)

State Transitions:
1. PENDING → PROCESSING: Payment initiated, funds locked
2. PROCESSING → COMPLETED: Provider confirms success
3. PROCESSING → FAILED: Provider error or timeout
4. FAILED → RETRY: Retry count < max_retries
5. FAILED → REFUNDING: Max retries exceeded, initiate refund
6. REFUNDING → REFUNDED: Funds returned to wallet
7. PENDING → EXPIRED: Transaction expires (24 hours)

───────────────────────────────────────────────────────────────
PAYMENT PROVIDER ABSTRACTION
───────────────────────────────────────────────────────────────

interface MoMoProvider {
  name: string;
  priority: number;
  
  disburse(params: DisburseParams): Promise<TransactionResult>;
  checkStatus(externalId: string): Promise<TransactionStatus>;
  getBalance(): Promise<ProviderBalance>;
  validateRecipient(phone: string): Promise<RecipientInfo>;
}

class MTNMoMoProvider implements MoMoProvider {
  // MTN-specific implementation
}

class VodafoneCashProvider implements MoMoProvider {
  // Vodafone-specific implementation
}

class AirtelTigoMoneyProvider implements MoMoProvider {
  // AirtelTigo-specific implementation
}

class MoMoAggregator {
  private providers: MoMoProvider[];
  
  async disburse(params: DisburseParams): Promise<TransactionResult> {
    // Try providers in priority order
    for (const provider of this.sortByPriority(this.providers)) {
      try {
        return await provider.disburse(params);
      } catch (error) {
        this.logFailure(provider, error);
        // Try next provider
      }
    }
    throw new AllProvidersFailedError();
  }
}

───────────────────────────────────────────────────────────────
IDEMPOTENCY & DEDUPLICATION
───────────────────────────────────────────────────────────────

Rule: ALL external operations MUST be idempotent (24-hour window)

Implementation:
1. Client generates idempotency_key (UUID)
2. Server checks for existing transaction with same key
3. If found, return existing result (no new processing)
4. If not found, create transaction and process
5. Store idempotency_key in database with UNIQUE constraint

Example:
async initiatePayment(data: PaymentDTO): Promise<Transaction> {
  const { idempotencyKey } = data;
  
  // Check for duplicate
  const existing = await this.transactionRepo.findOne({
    where: { idempotencyKey }
  });
  
  if (existing) {
    return existing; // Return cached result
  }
  
  // Process new transaction
  return this.createTransaction(data);
}

───────────────────────────────────────────────────────────────
WEBHOOK SECURITY & VALIDATION
───────────────────────────────────────────────────────────────

ALL webhooks MUST:
✓ Verify signature (HMAC-SHA256)
✓ Check timestamp (reject > 5 minutes old)
✓ Validate payload schema
✓ Be idempotent (process multiple times safely)
✓ Return 200 immediately, process async

Example:
async handleWebhook(
  payload: string,
  signature: string,
  timestamp: string
): Promise<void> {
  // 1. Verify timestamp
  if (Date.now() - parseInt(timestamp) > 300000) {
    throw new WebhookExpiredError();
  }
  
  // 2. Verify signature
  const expectedSignature = crypto
    .createHmac('sha256', WEBHOOK_SECRET)
    .update(timestamp + payload)
    .digest('hex');
    
  if (!crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature)
  )) {
    throw new InvalidSignatureError();
  }
  
  // 3. Parse and validate
  const event = JSON.parse(payload);
  this.validateWebhookSchema(event);
  
  // 4. Queue for async processing
  await this.webhookQueue.add('process-webhook', event);
  
  // 5. Return 200 immediately
}

───────────────────────────────────────────────────────────────
RECONCILIATION & AUDIT
───────────────────────────────────────────────────────────────

Daily Reconciliation Process:
1. Sum all ledger entries per wallet
2. Compare with current wallet balance
3. Flag discrepancies for manual review
4. Generate reconciliation report

Ledger Integrity Check:
SELECT 
  wallet_id,
  SUM(CASE WHEN entry_type = 'CREDIT' THEN amount ELSE 0 END) as total_credits,
  SUM(CASE WHEN entry_type = 'DEBIT' THEN amount ELSE 0 END) as total_debits,
  (total_credits - total_debits) as calculated_balance
FROM ledger_entries
GROUP BY wallet_id
HAVING calculated_balance != (
  SELECT balance FROM wallets WHERE id = wallet_id
);

Audit Log Integrity (Hash Chain):
Each audit log entry contains:
- previous_hash: SHA-256 of previous log entry
- current_hash: SHA-256 of (previous_hash + current_data)

This creates a tamper-evident chain.

═══════════════════════════════════════════════════════════════
PART B: PYTHON (FASTAPI) — KYC & INTELLIGENCE
═══════════════════════════════════════════════════════════════

RESPONSIBILITIES:
✓ Passport OCR & MRZ parsing
✓ Face verification & liveness detection
✓ KYC decisioning with tiered limits
✓ AML risk scoring
✓ Fraud pattern detection
✓ Manual review workflows
✓ Sanctions screening (OFAC, UN)
✓ User authentication (JWT)
✓ MFA management

TECHNOLOGY STACK:
- FastAPI (Python 3.11+)
- PostgreSQL 14+
- SQLAlchemy ORM
- Celery (async tasks)
- Redis (caching, queues)
- OpenCV / Tesseract (OCR)
- Face Recognition library
- pytest (testing)

POWERED MOBILE SCREENS:
✓ onboarding_screen.dart
✓ mfa_screen.dart
✓ profile_screen.dart
✓ security_screen.dart
✓ account_settings_screen.dart

───────────────────────────────────────────────────────────────
DATABASE SCHEMA (PostgreSQL - Separate DB)
───────────────────────────────────────────────────────────────

-- Users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    nationality VARCHAR(3),
    passport_number VARCHAR(50),
    kyc_tier INT DEFAULT 0,
    kyc_status VARCHAR(20) DEFAULT 'pending',
    risk_score INT DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active',
    mfa_enabled BOOLEAN DEFAULT false,
    mfa_secret VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    last_login_at TIMESTAMP,
    CONSTRAINT valid_kyc_status CHECK (kyc_status IN ('pending', 'approved', 'review', 'rejected')),
    CONSTRAINT valid_kyc_tier CHECK (kyc_tier BETWEEN 0 AND 3)
);

-- KYC Documents
CREATE TABLE kyc_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    document_type VARCHAR(50) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    encrypted_data BYTEA,
    verification_status VARCHAR(20) DEFAULT 'pending',
    ocr_data JSONB,
    face_encoding BYTEA,
    liveness_score DECIMAL(5, 2),
    verified_at TIMESTAMP,
    verified_by UUID,
    rejection_reason TEXT,
    uploaded_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT valid_verification_status CHECK (verification_status IN ('pending', 'verified', 'rejected', 'expired'))
);

-- Risk Assessments
CREATE TABLE risk_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    assessment_type VARCHAR(50) NOT NULL,
    risk_score INT NOT NULL,
    risk_level VARCHAR(20) NOT NULL,
    factors JSONB NOT NULL,
    decision VARCHAR(20) NOT NULL,
    reviewer_id UUID,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT valid_risk_level CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
    CONSTRAINT valid_decision CHECK (decision IN ('approve', 'review', 'reject'))
);

───────────────────────────────────────────────────────────────
KYC TIER SYSTEM
───────────────────────────────────────────────────────────────

TIER 0 (Unverified):
- Max transaction: GHS 0
- Daily limit: GHS 0
- Required: Email verification only
- Use case: Registration only

TIER 1 (Basic):
- Max transaction: GHS 500
- Daily limit: GHS 2,000
- Monthly limit: GHS 10,000
- Required: Passport + Selfie
- Auto-approve if risk_score > 700

TIER 2 (Standard):
- Max transaction: GHS 5,000
- Daily limit: GHS 20,000
- Monthly limit: GHS 100,000
- Required: Passport + Selfie + Proof of Address
- Auto-approve if risk_score > 800

TIER 3 (Premium):
- Max transaction: Unlimited
- Daily limit: Unlimited
- Monthly limit: Unlimited
- Required: Full KYC + Video verification
- Always requires manual review

───────────────────────────────────────────────────────────────
RISK SCORING ALGORITHM
───────────────────────────────────────────────────────────────

Base Score: 500

RISK FACTORS (Deductions):
- Sanctioned country: -1000 (auto-reject)
- High-risk country: -100
- Failed liveness detection: -50
- Document inconsistency: -30
- Age below 18: -1000 (auto-reject)
- Duplicate passport: -200
- Suspicious activity pattern: -50
- VPN/Proxy detected: -20
- Multiple failed verification attempts: -10 per attempt

POSITIVE FACTORS (Additions):
- Document quality high: +50
- Face match confidence > 95%: +30
- Long-term visitor visa: +20
- Verified phone number: +10
- Verified email: +10

DECISION MATRIX:
- Score < 300: Auto-reject
- Score 300-700: Manual review required
- Score > 700: Auto-approve (Tier 1)
- Score > 800: Auto-approve (Tier 2)

───────────────────────────────────────────────────────────────
CORE KYC SERVICES
───────────────────────────────────────────────────────────────

1. OCR SERVICE
   ✓ Extract text from passport MRZ
   ✓ Parse passport data (name, number, nationality, DOB, expiry)
   ✓ Validate MRZ checksum
   ✓ Detect document tampering

2. FACE VERIFICATION SERVICE
   ✓ Extract face encoding from selfie
   ✓ Compare with passport photo
   ✓ Liveness detection (blink, head movement)
   ✓ Return confidence score

3. RISK SCORING SERVICE
   ✓ Calculate weighted risk score
   ✓ Check sanctions lists (OFAC, UN)
   ✓ Verify nationality against high-risk countries
   ✓ Detect duplicate documents
   ✓ Return decision + reasoning

4. KYC WORKFLOW SERVICE
   ✓ Orchestrate verification steps
   ✓ Store results securely
   ✓ Trigger manual review if needed
   ✓ Notify user of decision
   ✓ Update user tier

───────────────────────────────────────────────────────────────
SANCTIONS SCREENING
───────────────────────────────────────────────────────────────

Check against:
- OFAC (Office of Foreign Assets Control)
- UN Consolidated List
- EU Sanctions List
- Local Ghana sanctions (if any)

Implementation:
def check_sanctions(name: str, nationality: str, passport: str) -> bool:
    # Fuzzy name matching
    # Check nationality against sanctioned countries
    # Check passport number against watchlist
    # Return True if any match found

───────────────────────────────────────────────────────────────
MANUAL REVIEW WORKFLOW
───────────────────────────────────────────────────────────────

When risk_score between 300-700:
1. Create review task
2. Assign to compliance officer
3. Display user documents
4. Show risk factors
5. Officer makes decision (approve/reject)
6. System applies decision
7. Notify user

═══════════════════════════════════════════════════════════════
INTER-SERVICE COMMUNICATION
═══════════════════════════════════════════════════════════════

SYNC (REST API):
- NestJS → Python: Check KYC status before payment
- Python → NestJS: None (Python never touches money)

ASYNC (Message Queue):
- User registered (NestJS) → Start KYC (Python)
- KYC approved (Python) → Upgrade wallet tier (NestJS)
- Suspicious transaction (NestJS) → Risk assessment (Python)

Message Format:
{
  "event_type": "user.kyc.approved",
  "user_id": "uuid",
  "tier": 1,
  "timestamp": "2025-01-01T00:00:00Z",
  "signature": "hmac-sha256-signature"
}

Queue Implementation:
- Use Redis Streams or RabbitMQ
- Each service subscribes to relevant events
- Idempotent message processing
- Dead letter queue for failures

═══════════════════════════════════════════════════════════════
SECURITY & COMPLIANCE
═══════════════════════════════════════════════════════════════

AUTHENTICATION:
✓ JWT with RS256 (asymmetric keys)
✓ Access token: 15 minutes
✓ Refresh token: 7 days
✓ Rotate refresh tokens on use
✓ Device fingerprinting
✓ IP-based anomaly detection

AUTHORIZATION:
✓ Role-based access control (RBAC)
✓ Roles: user, admin, compliance_officer, support
✓ Permissions per endpoint
✓ Audit all access attempts

DATA PROTECTION:
✓ Encrypt PII at rest (AES-256)
✓ Encrypt data in transit (TLS 1.3)
✓ Hash passwords (bcrypt, 12 rounds)
✓ Mask sensitive data in logs
✓ GDPR-compliant data deletion

RATE LIMITING:
✓ Global: 1000 req/min per IP
✓ Per user: 100 req/min
✓ Payment endpoints: 10 req/min
✓ Auth endpoints: 5 req/min
✓ 429 status code on limit

ABUSE PREVENTION:
✓ Progressive delays on failed login
✓ Account lockout after 5 failed attempts
✓ CAPTCHA on suspicious activity
✓ Geo-blocking high-risk countries
✓ Velocity checks on transactions

═══════════════════════════════════════════════════════════════
OBSERVABILITY & MONITORING
═══════════════════════════════════════════════════════════════

LOGGING:
✓ Structured JSON logs (Winston/Python logging)
✓ Correlation IDs across services
✓ Log levels: DEBUG, INFO, WARN, ERROR, CRITICAL
✓ Centralized log aggregation (ELK stack)

METRICS:
✓ Response times (p50, p95, p99)
✓ Error rates
✓ Payment success rates
✓ KYC approval rates
✓ Queue depths
✓ Database connection pool usage

TRACING:
✓ Distributed tracing (OpenTelemetry)
✓ Trace payments end-to-end
✓ Identify bottlenecks

ALERTING:
✓ Payment failure rate > 5%
✓ API response time > 500ms (p95)
✓ Database connection errors
✓ Failed webhook deliveries
✓ Suspicious activity patterns
✓ Low master wallet balance

DASHBOARDS:
✓ Real-time transaction volume
✓ Revenue metrics
✓ System health
✓ KYC funnel
✓ Fraud detection stats

═══════════════════════════════════════════════════════════════
TESTING REQUIREMENTS
═══════════════════════════════════════════════════════════════

NESTJS (Money Core):
✓ Unit tests: >90% coverage
✓ Integration tests: All payment flows
✓ Idempotency tests: Duplicate requests
✓ Ledger integrity tests
✓ Load tests: 1000 concurrent payments
✓ Chaos tests: DB failures, provider timeouts

PYTHON (KYC):
✓ Unit tests: >85% coverage
✓ OCR accuracy tests: >95%
✓ Face match threshold tests
✓ Risk scoring edge cases
✓ Sanctions screening tests
✓ Manual review workflow tests

E2E TESTS:
✓ User registration → KYC → Fund wallet → Payment
✓ Failed payment → Retry → Refund
✓ Webhook reconciliation
✓ Multi-currency conversion

═══════════════════════════════════════════════════════════════
API SPECIFICATIONS
═══════════════════════════════════════════════════════════════

GENERATE:
✓ OpenAPI 3.0 spec for NestJS
✓ OpenAPI 3.0 spec for Python
✓ Postman collections
✓ API versioning: /v1/, /v2/
✓ Deprecation policy: 6 months notice

ERROR RESPONSES:
{
  "error": {
    "code": "VES-1001",
    "message": "Insufficient balance",
    "details": {
      "required": 100.00,
      "available": 50.00
    },
    "timestamp": "2025-01-01T00:00:00Z",
    "request_id": "uuid"
  }
}

ERROR CODES:
VES-1001: Insufficient balance
VES-1002: Invalid recipient
VES-2001: KYC not approved
VES-2002: KYC tier limit exceeded
VES-3001: Duplicate transaction
VES-4001: Rate limit exceeded
VES-5001: External provider error
VES-6001: Webhook signature invalid
VES-7001: Invalid FX rate

═══════════════════════════════════════════════════════════════
DISASTER RECOVERY
═══════════════════════════════════════════════════════════════

BACKUPS:
✓ Automated daily backups
✓ Point-in-time recovery (7 days)
✓ Cross-region replication
✓ Backup encryption
✓ Monthly restore tests

FAILOVER:
✓ Database read replicas
✓ Automatic failover (< 30 seconds)
✓ Health checks every 30 seconds
✓ Circuit breakers on external APIs

ROLLBACK:
✓ Blue-green deployments
✓ Database migration rollback scripts
✓ Feature flags for instant disable
✓ Canary deployments (5% → 50% → 100%)

═══════════════════════════════════════════════════════════════
PERFORMANCE TARGETS
═══════════════════════════════════════════════════════════════

API Response Times:
- GET /wallet/balance: < 100ms (p95)
- POST /payment/initiate: < 200ms (p95)
- POST /kyc/verify: < 500ms (p95)
- Webhook processing: < 50ms (respond), < 5s (complete)

Database:
- Query response: < 50ms (p95)
- Connection pool: 20-100 connections
- Replication lag: < 1 second

System:
- Uptime: 99.9% (43 minutes downtime/month)
- Concurrent users: 10,000+
- Payments per second: 100+

═══════════════════════════════════════════════════════════════
DELIVERABLES
═══════════════════════════════════════════════════════════════

✓ Fully implemented NestJS backend (production-ready)
✓ Fully implemented Python KYC service (production-ready)
✓ PostgreSQL schemas & migrations (both databases)
✓ OpenAPI specifications (both services)
✓ Docker Compose for local development
✓ Kubernetes manifests for production
✓ Environment configuration templates
✓ Unit & integration tests (>85% coverage)
✓ Load testing scripts
✓ Monitoring dashboard configs
✓ API documentation (Swagger UI)
✓ README with setup instructions
✓ Architecture diagrams
✓ Deployment guide
✓ Troubleshooting guide

✗ NO mock payment logic
✗ NO TODOs or placeholders
✗ NO hardcoded credentials
✗ NO shared databases
✗ NO direct balance updates

═══════════════════════════════════════════════════════════════
VALIDATION CHECKLIST
═══════════════════════════════════════════════════════════════

Before accepting deliverables, verify:

[ ] All ledger entries have corresponding balance updates
[ ] No shared database between NestJS and Python
[ ] Idempotency keys on all payment operations
[ ] Webhook signatures verified
[ ] FX rates fetched from external API (not hardcoded)
[ ] KYC auto-approval uses risk scoring (not default approve)
[ ] All secrets in environment variables
[ ] Tests pass with >85% coverage
[ ] API documentation complete
[ ] Health check endpoints functional
[ ] Logging includes correlation IDs
[ ] Rate limiting configured
[ ] Error codes standardized
[ ] Database indexes on foreign keys
[ ] Migration rollback scripts exist

═══════════════════════════════════════════════════════════════
FAILURE CONDITIONS (AUTOMATIC REJECTION)
═══════════════════════════════════════════════════════════════

❌ Direct balance update without ledger entry
❌ Shared database between services
❌ Missing idempotency on payments
❌ Hardcoded FX rates or fees
❌ Auto-approving KYC without risk scoring
❌ Unencrypted PII storage
❌ Missing webhook signature verification
❌ No audit logging
❌ Incomplete error handling
❌ Credentials in code
❌ Mock payment logic in production code

═══════════════════════════════════════════════════════════════
BUILD THIS AS IF:
═══════════════════════════════════════════════════════════════

✓ Real money is at stake
✓ Real regulators will audit
✓ Real attackers will try to exploit
✓ Real users depend on uptime
✓ Real compliance officers will scrutinize
✓ Real auditors will verify every ledger entry

NO SHORTCUTS. PRODUCTION-GRADE ONLY.
