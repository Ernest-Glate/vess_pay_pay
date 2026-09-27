VESSPay Backend Specification - FINAL UNIFIED VERSION
TypeScript (NestJS) + Python (FastAPI)
Flutter-Model Aligned + Production-Grade

═══════════════════════════════════════════════════════════════
CRITICAL: FRONTEND DATA CONTRACT
═══════════════════════════════════════════════════════════════

The Flutter app expects EXACT JSON structures. Backend MUST return data
in these formats. Any deviation will break the mobile app.

App: VessPay Mobile
Type: Fintech / Digital Wallet  
Frontend: Flutter
Auth: Bearer Token (JWT)

═══════════════════════════════════════════════════════════════
CORE DATA MODELS (MANDATORY COMPLIANCE)
═══════════════════════════════════════════════════════════════

───────────────────────────────────────────────────────────────
1. USER MODEL
───────────────────────────────────────────────────────────────

TypeScript Interface:
interface User {
  id: string;                    // UUID
  email: string;
  fullName: string;
  phoneNumber?: string;          // Optional
  profilePictureUrl?: string;    // Optional, full URL
  isVerified: boolean;
  tierLevel: number;             // 1-3 (KYC tier)
}

Example JSON Response:
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "john.doe@example.com",
  "fullName": "John Doe",
  "phoneNumber": "+233241234567",
  "profilePictureUrl": "https://cdn.vesspay.com/profile/550e8400.jpg",
  "isVerified": true,
  "tierLevel": 1
}

Database Mapping:
- id → users.id
- email → users.email
- fullName → CONCAT(users.first_name, ' ', users.last_name)
- phoneNumber → users.phone
- profilePictureUrl → users.profile_picture_url
- isVerified → users.email_verified AND users.kyc_status = 'approved'
- tierLevel → users.kyc_tier

───────────────────────────────────────────────────────────────
2. WALLET MODEL
───────────────────────────────────────────────────────────────

TypeScript Interface:
interface Wallet {
  id: string;                    // UUID
  currency: string;              // ISO 4217 code (USD, GHS, EUR, GBP)
  symbol: string;                // Currency symbol ($, ₵, €, £)
  balance: number;               // Double, 2 decimal places
  accentColor: string;           // Hex color with alpha (0xFF42A5F5)
  isPrimary: boolean;
}

Example JSON Response:
{
  "id": "660e8400-e29b-41d4-a716-446655440001",
  "currency": "GHS",
  "symbol": "₵",
  "balance": 1250.50,
  "accentColor": "0xFF4CAF50",
  "isPrimary": true
}

Currency Symbol Mapping:
- USD → "$"
- GHS → "₵"
- EUR → "€"
- GBP → "£"

Accent Color Mapping (Flutter Color codes):
- GHS → "0xFF4CAF50" (Green)
- USD → "0xFF42A5F5" (Blue)
- EUR → "0xFF9C27B0" (Purple)
- GBP → "0xFFFF9800" (Orange)

Database Mapping:
- id → wallets.id
- currency → wallets.currency
- balance → wallets.balance
- isPrimary → wallets.currency = 'GHS' (primary is always GHS)

───────────────────────────────────────────────────────────────
3. TRANSACTION MODEL
───────────────────────────────────────────────────────────────

TypeScript Interface:
interface Transaction {
  id: string;                    // UUID
  type: 'credit' | 'debit' | 'exchange';
  amount: number;                // Double, always positive
  currency: string;              // ISO 4217 code
  description: string;
  createdAt: string;             // ISO 8601 format
  status: 'pending' | 'completed' | 'failed';
  reference?: string;            // Optional external reference
}

Example JSON Response:
{
  "id": "770e8400-e29b-41d4-a716-446655440002",
  "type": "debit",
  "amount": 50.00,
  "currency": "GHS",
  "description": "Payment to +233241234567",
  "createdAt": "2025-02-05T10:30:00.000Z",
  "status": "completed",
  "reference": "MTN-TXN-12345"
}

Type Mapping:
- credit: Deposits, incoming payments, refunds
- debit: Outgoing payments, withdrawals, fees
- exchange: Currency conversions

Database Mapping:
- id → transactions.id
- type → Derived from transaction_type ('deposit'/'refund' → 'credit', 'payment'/'fee' → 'debit', 'exchange' → 'exchange')
- amount → ABS(transactions.amount) (always positive in Flutter)
- currency → transactions.currency
- description → transactions.description
- createdAt → transactions.created_at (ISO 8601 format)
- status → transactions.status
- reference → transactions.external_transaction_id

═══════════════════════════════════════════════════════════════
API ENDPOINTS (FLUTTER-ALIGNED)
═══════════════════════════════════════════════════════════════

All endpoints return data matching the models above EXACTLY.

───────────────────────────────────────────────────────────────
AUTHENTICATION ENDPOINTS
───────────────────────────────────────────────────────────────

POST /api/v1/auth/register
Service: Python (FastAPI)
Request:
{
  "email": "john.doe@example.com",
  "password": "SecurePassword123!",
  "fullName": "John Doe",
  "phoneNumber": "+233241234567"  // Optional
}

Response 201:
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "john.doe@example.com",
    "fullName": "John Doe",
    "phoneNumber": "+233241234567",
    "profilePictureUrl": null,
    "isVerified": false,
    "tierLevel": 0
  }
}

Response 400:
{
  "error": "EMAIL_EXISTS",
  "message": "An account with this email already exists"
}

───────────────────────────────────────────────────────────────

POST /api/v1/auth/login
Service: Python (FastAPI)
Request:
{
  "email": "john.doe@example.com",
  "password": "SecurePassword123!"
}

Response 200:
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "john.doe@example.com",
    "fullName": "John Doe",
    "phoneNumber": "+233241234567",
    "profilePictureUrl": "https://cdn.vesspay.com/profile/550e8400.jpg",
    "isVerified": true,
    "tierLevel": 1
  }
}

Response 401:
{
  "error": "INVALID_CREDENTIALS",
  "message": "Email or password is incorrect"
}

───────────────────────────────────────────────────────────────

GET /api/v1/auth/me
Service: Python (FastAPI)
Headers:
  Authorization: Bearer {token}

Response 200:
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "john.doe@example.com",
  "fullName": "John Doe",
  "phoneNumber": "+233241234567",
  "profilePictureUrl": "https://cdn.vesspay.com/profile/550e8400.jpg",
  "isVerified": true,
  "tierLevel": 1
}

Response 401:
{
  "error": "INVALID_TOKEN",
  "message": "Token is invalid or expired"
}

───────────────────────────────────────────────────────────────
WALLET ENDPOINTS
───────────────────────────────────────────────────────────────

GET /api/v1/wallets
Service: TypeScript (NestJS)
Headers:
  Authorization: Bearer {token}

Response 200:
[
  {
    "id": "660e8400-e29b-41d4-a716-446655440001",
    "currency": "GHS",
    "symbol": "₵",
    "balance": 1250.50,
    "accentColor": "0xFF4CAF50",
    "isPrimary": true
  },
  {
    "id": "660e8400-e29b-41d4-a716-446655440002",
    "currency": "USD",
    "symbol": "$",
    "balance": 100.00,
    "accentColor": "0xFF42A5F5",
    "isPrimary": false
  }
]

Implementation Notes:
- Primary wallet is ALWAYS GHS (Ghana Cedi)
- Other currencies are virtual wallets showing equivalent balance
- Calculate non-primary balances using current FX rates
- User has ONE physical wallet (GHS) but multiple display currencies

───────────────────────────────────────────────────────────────

POST /api/v1/wallets/:id/fund
Service: TypeScript (NestJS)
Headers:
  Authorization: Bearer {token}

Path Params:
  id: wallet UUID (must be GHS wallet)

Request:
{
  "amount": 100.00,
  "source": "card_pm_1234567890"  // Stripe payment method ID
}

Response 200:
{
  "newBalance": 1350.50
}

Response 400:
{
  "error": "INVALID_WALLET",
  "message": "Can only fund GHS wallet directly"
}

Response 402:
{
  "error": "PAYMENT_FAILED",
  "message": "Card payment declined by issuer"
}

───────────────────────────────────────────────────────────────
TRANSACTION ENDPOINTS
───────────────────────────────────────────────────────────────

GET /api/v1/transactions
Service: TypeScript (NestJS)
Headers:
  Authorization: Bearer {token}

Query Params:
  limit: number (default 20, max 100)
  offset: number (default 0)
  type: 'credit' | 'debit' | 'exchange' (optional filter)
  status: 'pending' | 'completed' | 'failed' (optional filter)

Response 200:
[
  {
    "id": "770e8400-e29b-41d4-a716-446655440002",
    "type": "debit",
    "amount": 50.00,
    "currency": "GHS",
    "description": "Payment to +233241234567",
    "createdAt": "2025-02-05T10:30:00.000Z",
    "status": "completed",
    "reference": "MTN-TXN-12345"
  },
  {
    "id": "770e8400-e29b-41d4-a716-446655440003",
    "type": "credit",
    "amount": 200.00,
    "currency": "GHS",
    "description": "Card deposit",
    "createdAt": "2025-02-04T15:20:00.000Z",
    "status": "completed",
    "reference": "STRIPE-CH-67890"
  }
]

Pagination Headers (Optional but recommended):
X-Total-Count: 125
X-Page-Count: 7
X-Current-Page: 1
X-Per-Page: 20

───────────────────────────────────────────────────────────────

GET /api/v1/transactions/:id
Service: TypeScript (NestJS)
Headers:
  Authorization: Bearer {token}

Path Params:
  id: transaction UUID

Response 200:
{
  "id": "770e8400-e29b-41d4-a716-446655440002",
  "type": "debit",
  "amount": 50.00,
  "currency": "GHS",
  "description": "Payment to +233241234567",
  "createdAt": "2025-02-05T10:30:00.000Z",
  "status": "completed",
  "reference": "MTN-TXN-12345"
}

Response 404:
{
  "error": "TRANSACTION_NOT_FOUND",
  "message": "Transaction with ID 770e8400... not found"
}

───────────────────────────────────────────────────────────────
ACTIONS (TO BE IMPLEMENTED)
───────────────────────────────────────────────────────────────

POST /api/v1/transfers/send
Service: TypeScript (NestJS)
Headers:
  Authorization: Bearer {token}

Request:
{
  "recipientPhone": "+233241234567",
  "amount": 50.00,
  "currency": "GHS",
  "note": "Payment for lunch"
}

Response 200:
{
  "id": "770e8400-e29b-41d4-a716-446655440004",
  "type": "debit",
  "amount": 50.00,
  "currency": "GHS",
  "description": "Payment to +233241234567",
  "createdAt": "2025-02-05T11:00:00.000Z",
  "status": "pending",
  "reference": null
}

Response 400:
{
  "error": "INSUFFICIENT_BALANCE",
  "message": "Wallet balance insufficient for this transaction"
}

───────────────────────────────────────────────────────────────

POST /api/v1/transfers/request
Service: TypeScript (NestJS)
Headers:
  Authorization: Bearer {token}

Request:
{
  "amount": 100.00,
  "currency": "GHS",
  "note": "Payment for services"
}

Response 200:
{
  "requestId": "880e8400-e29b-41d4-a716-446655440005",
  "qrCode": "data:image/png;base64,iVBORw0KGgo...",
  "paymentLink": "https://pay.vesspay.com/r/880e8400",
  "expiresAt": "2025-02-05T12:00:00.000Z"
}

───────────────────────────────────────────────────────────────

POST /api/v1/exchange
Service: TypeScript (NestJS)
Headers:
  Authorization: Bearer {token}

Request:
{
  "fromCurrency": "USD",
  "toCurrency": "GHS",
  "amount": 100.00
}

Response 200:
{
  "id": "770e8400-e29b-41d4-a716-446655440006",
  "type": "exchange",
  "amount": 100.00,
  "currency": "USD",
  "description": "Exchanged 100.00 USD to 1219.00 GHS",
  "createdAt": "2025-02-05T11:30:00.000Z",
  "status": "completed",
  "reference": "FX-20250205-001"
}

Note: This creates TWO transactions:
1. Debit of USD (virtual)
2. Credit of GHS (actual wallet increase)

═══════════════════════════════════════════════════════════════
DATABASE SCHEMA (ALIGNED WITH FLUTTER MODELS)
═══════════════════════════════════════════════════════════════

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    profile_picture_url VARCHAR(500),
    email_verified BOOLEAN DEFAULT false,
    kyc_status VARCHAR(20) DEFAULT 'pending',
    kyc_tier INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Wallets table
CREATE TABLE wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    currency VARCHAR(3) NOT NULL DEFAULT 'GHS',
    balance DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT one_wallet_per_user UNIQUE(user_id)
);

-- Transactions table
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    wallet_id UUID NOT NULL REFERENCES wallets(id),
    transaction_type VARCHAR(50) NOT NULL,
    amount DECIMAL(18, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    external_transaction_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP,
    CONSTRAINT valid_status CHECK (status IN ('pending', 'completed', 'failed'))
);

-- Indexes
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_created_at ON transactions(created_at DESC);
CREATE INDEX idx_transactions_status ON transactions(status);

═══════════════════════════════════════════════════════════════
BACKEND RESPONSE TRANSFORMATION
═══════════════════════════════════════════════════════════════

Critical: Database schema differs from Flutter models. Transform on response.

User Transformation (Python):
```python
def transform_user_to_response(user_db):
    return {
        "id": str(user_db.id),
        "email": user_db.email,
        "fullName": f"{user_db.first_name} {user_db.last_name}",
        "phoneNumber": user_db.phone,
        "profilePictureUrl": user_db.profile_picture_url,
        "isVerified": user_db.email_verified and user_db.kyc_status == 'approved',
        "tierLevel": user_db.kyc_tier
    }
```

Wallet Transformation (TypeScript):
```typescript
function transformWalletToResponse(wallet: WalletEntity): Wallet {
  const currencySymbols = {
    'GHS': '₵',
    'USD': '$',
    'EUR': '€',
    'GBP': '£'
  };
  
  const accentColors = {
    'GHS': '0xFF4CAF50',
    'USD': '0xFF42A5F5',
    'EUR': '0xFF9C27B0',
    'GBP': '0xFFFF9800'
  };
  
  return {
    id: wallet.id,
    currency: wallet.currency,
    symbol: currencySymbols[wallet.currency] || '$',
    balance: parseFloat(wallet.balance.toFixed(2)),
    accentColor: accentColors[wallet.currency] || '0xFF9E9E9E',
    isPrimary: wallet.currency === 'GHS'
  };
}
```

Transaction Transformation (TypeScript):
```typescript
function transformTransactionToResponse(tx: TransactionEntity): Transaction {
  // Map transaction_type to Flutter's type
  const typeMapping = {
    'deposit': 'credit',
    'refund': 'credit',
    'payment': 'debit',
    'fee': 'debit',
    'withdrawal': 'debit',
    'exchange': 'exchange'
  };
  
  return {
    id: tx.id,
    type: typeMapping[tx.transaction_type] || 'debit',
    amount: Math.abs(parseFloat(tx.amount.toFixed(2))), // Always positive
    currency: tx.currency,
    description: tx.description,
    createdAt: tx.created_at.toISOString(),
    status: tx.status,
    reference: tx.external_transaction_id || undefined
  };
}
```

═══════════════════════════════════════════════════════════════
SCREEN-TO-ENDPOINT MAPPING (20 SCREENS)
═══════════════════════════════════════════════════════════════

Authentication Screens (5):
├─ splash_screen.dart → GET /api/v1/auth/me
├─ landing_screen.dart → No API (static content)
├─ login_screen.dart → POST /api/v1/auth/login
├─ mfa_screen.dart → POST /api/v1/auth/mfa/verify
└─ onboarding_screen.dart → POST /api/v1/auth/register

Dashboard (1):
└─ dashboard_screen.dart → GET /api/v1/wallets
                         → GET /api/v1/transactions?limit=5

Payment Screens (7):
├─ add_money_screen.dart → POST /api/v1/wallets/:id/fund
├─ currency_exchange_screen.dart → POST /api/v1/exchange
├─ exchange_success_screen.dart → GET /api/v1/transactions/:id
├─ pay_momo_screen.dart → POST /api/v1/transfers/send
├─ payment_success_screen.dart → GET /api/v1/transactions/:id
├─ request_money_screen.dart → POST /api/v1/transfers/request
├─ send_money_screen.dart → POST /api/v1/transfers/send
└─ transaction_details_screen.dart → GET /api/v1/transactions/:id

Profile Screens (4):
├─ profile_screen.dart → GET /api/v1/auth/me
├─ account_settings_screen.dart → PUT /api/v1/user/settings
├─ change_password_screen.dart → POST /api/v1/user/change-password
└─ security_screen.dart → GET /api/v1/user/security

Wallet Screens (3):
├─ wallet_screen.dart → GET /api/v1/wallets
├─ transactions_screen.dart → GET /api/v1/transactions
└─ transaction_history_screen.dart → GET /api/v1/transactions

═══════════════════════════════════════════════════════════════
ADDITIONAL ENDPOINTS NEEDED (BASED ON 20 SCREENS)
═══════════════════════════════════════════════════════════════

These endpoints were in the original spec but should return
Flutter-compatible data models:

POST /api/v1/auth/mfa/verify
PUT /api/v1/user/settings
POST /api/v1/user/change-password
GET /api/v1/user/security

All should use the same User model for consistency.

═══════════════════════════════════════════════════════════════
CRITICAL IMPLEMENTATION RULES
═══════════════════════════════════════════════════════════════

1. EXACT JSON STRUCTURE
   ✓ Field names MUST match exactly (camelCase)
   ✓ Data types MUST match (string vs number)
   ✓ Optional fields use null, not missing keys
   ✓ Arrays always return [], never null

2. ISO 8601 TIMESTAMPS
   ✓ Format: "2025-02-05T10:30:00.000Z"
   ✓ Always UTC timezone
   ✓ Include milliseconds

3. CURRENCY AMOUNTS
   ✓ Always 2 decimal places
   ✓ Type: number (not string)
   ✓ Positive values for transaction amounts

4. UUID FORMAT
   ✓ Lowercase with hyphens
   ✓ Example: "550e8400-e29b-41d4-a716-446655440000"

5. BOOLEAN VALUES
   ✓ Use true/false (not 1/0 or "true"/"false")

6. NULL HANDLING
   ✓ Optional fields that are empty use null
   ✓ Never use undefined in JSON responses

7. FLUTTER COLOR CODES
   ✓ Format: "0xFFRRGGBB" (string)
   ✓ Include alpha channel (FF)
   ✓ Example: "0xFF4CAF50"

═══════════════════════════════════════════════════════════════
ERROR RESPONSE FORMAT
═══════════════════════════════════════════════════════════════

All errors MUST follow this structure:

{
  "error": "ERROR_CODE",
  "message": "Human-readable description"
}

Common Error Codes:
- INVALID_CREDENTIALS: Login failed
- EMAIL_EXISTS: Registration duplicate
- INVALID_TOKEN: Auth token invalid/expired
- INSUFFICIENT_BALANCE: Not enough funds
- TRANSACTION_NOT_FOUND: Invalid transaction ID
- INVALID_WALLET: Wrong wallet for operation
- PAYMENT_FAILED: External provider error

HTTP Status Codes:
- 200: Success
- 201: Created
- 400: Bad Request (validation error)
- 401: Unauthorized (auth error)
- 402: Payment Required (payment failure)
- 404: Not Found
- 409: Conflict (duplicate)
- 429: Too Many Requests (rate limit)
- 500: Internal Server Error

═══════════════════════════════════════════════════════════════
AUTHENTICATION FLOW
═══════════════════════════════════════════════════════════════

1. User Registration:
   POST /api/v1/auth/register
   → Returns token + user object
   → User has tierLevel: 0 (unverified)

2. User Login:
   POST /api/v1/auth/login
   → Returns token + user object

3. Token Usage:
   All subsequent requests:
   Headers: Authorization: Bearer {token}

4. Token Refresh:
   When token expires (401 response):
   → Frontend handles re-login
   → Backend does NOT implement auto-refresh

5. Session Validation:
   On app launch:
   GET /api/v1/auth/me
   → If 401, redirect to login
   → If 200, proceed to dashboard

═══════════════════════════════════════════════════════════════
WALLET SYSTEM ARCHITECTURE
═══════════════════════════════════════════════════════════════

Single Physical Wallet:
- User has ONE wallet in database (GHS)
- Balance stored in GHS only
- All transactions in GHS

Multi-Currency Display:
- Frontend shows multiple "virtual wallets"
- GET /api/v1/wallets returns array with GHS + USD/EUR/GBP
- Non-GHS balances calculated using current FX rates
- Only GHS wallet has isPrimary: true

Example:
User has 1000 GHS in wallet.
GET /api/v1/wallets returns:
[
  { currency: "GHS", balance: 1000.00, isPrimary: true },
  { currency: "USD", balance: 80.00, isPrimary: false },  // 1000/12.5
  { currency: "EUR", balance: 72.50, isPrimary: false },  // 1000/13.8
  { currency: "GBP", balance: 62.89, isPrimary: false }   // 1000/15.9
]

Funding:
- Can ONLY fund GHS wallet directly
- POST /api/v1/wallets/:id/fund where :id is GHS wallet ID
- If user tries to fund USD wallet → return error

═══════════════════════════════════════════════════════════════
TRANSACTION TYPE MAPPING
═══════════════════════════════════════════════════════════════

Database → Flutter:

deposit → credit
refund → credit
incoming_payment → credit

payment → debit
withdrawal → debit
fee → debit
outgoing_payment → debit

exchange → exchange

Frontend Display:
- credit: Green, "+" prefix, "Received"
- debit: Red, "-" prefix, "Sent"
- exchange: Blue, "↔" icon, "Exchanged"

═══════════════════════════════════════════════════════════════
TESTING CHECKLIST
═══════════════════════════════════════════════════════════════

Before deployment, verify:

Data Model Compliance:
[ ] POST /api/v1/auth/register returns exact User model
[ ] POST /api/v1/auth/login returns exact User model
[ ] GET /api/v1/auth/me returns exact User model
[ ] GET /api/v1/wallets returns array of exact Wallet models
[ ] GET /api/v1/transactions returns array of exact Transaction models
[ ] All camelCase field names correct
[ ] All data types correct (number vs string)
[ ] ISO 8601 timestamps with milliseconds
[ ] Flutter color codes in correct format

Functional Tests:
[ ] Can register new user
[ ] Can login existing user
[ ] Token works for authenticated endpoints
[ ] Can get wallet balance
[ ] Can fund wallet
[ ] Can view transactions
[ ] Pagination works correctly
[ ] Error responses follow standard format

Edge Cases:
[ ] Invalid email returns EMAIL_EXISTS
[ ] Wrong password returns INVALID_CREDENTIALS
[ ] Expired token returns INVALID_TOKEN
[ ] Empty transaction list returns []
[ ] Optional fields use null when missing

═══════════════════════════════════════════════════════════════
DEPLOYMENT REQUIREMENTS
═══════════════════════════════════════════════════════════════

Environment Variables:
- DATABASE_URL: PostgreSQL connection string
- JWT_SECRET: For token signing
- STRIPE_SECRET_KEY: For card payments
- MOMO_API_KEY: For MoMo integration
- CORS_ORIGIN: Flutter app URL

CORS Configuration:
Allow-Origin: https://app.vesspay.com (or Flutter app domain)
Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Allow-Headers: Content-Type, Authorization
Allow-Credentials: true

Rate Limiting:
- Login: 5 attempts per 15 minutes per IP
- Registration: 3 per hour per IP
- Other endpoints: 100 per hour per user

═══════════════════════════════════════════════════════════════
IMPLEMENTATION PRIORITY
═══════════════════════════════════════════════════════════════

Phase 1 (Week 1): Core Authentication
[ ] POST /api/v1/auth/register
[ ] POST /api/v1/auth/login
[ ] GET /api/v1/auth/me
→ Enables: splash, login, onboarding screens

Phase 2 (Week 2): Wallet & Transactions
[ ] GET /api/v1/wallets
[ ] GET /api/v1/transactions
[ ] GET /api/v1/transactions/:id
→ Enables: dashboard, wallet, transaction screens

Phase 3 (Week 3): Payments
[ ] POST /api/v1/wallets/:id/fund
[ ] POST /api/v1/transfers/send
→ Enables: add_money, pay_momo, send_money screens

Phase 4 (Week 4): Advanced Features
[ ] POST /api/v1/transfers/request
[ ] POST /api/v1/exchange
[ ] Additional profile/security endpoints
→ Enables: All remaining screens

═══════════════════════════════════════════════════════════════
CRITICAL SUCCESS FACTORS
═══════════════════════════════════════════════════════════════

1. EXACT DATA MODEL MATCH
   - Any deviation breaks Flutter app
   - Field names, types, structure must be perfect

2. CONSISTENT ERROR HANDLING
   - All errors follow same format
   - HTTP status codes meaningful

3. PROPER AUTHENTICATION
   - JWT tokens work correctly
   - Token validation on every request

4. TRANSACTION INTEGRITY
   - Amounts always positive in responses
   - Types mapped correctly
   - Timestamps in ISO 8601

5. MULTI-CURRENCY LOGIC
   - Only one physical wallet (GHS)
   - Virtual wallets calculated correctly
   - Funding only on GHS wallet

═══════════════════════════════════════════════════════════════
CONTACT & SUPPORT
═══════════════════════════════════════════════════════════════

If backend deviates from this spec:
- Flutter app WILL break
- Coordinate any changes with frontend team
- Test with actual Flutter app before deployment

Questions about data models:
- Refer to "CORE DATA MODELS" section
- Do NOT modify field names or types
- Do NOT add/remove fields without frontend approval

═══════════════════════════════════════════════════════════════
END OF SPECIFICATION
═══════════════════════════════════════════════════════════════

This specification ensures 100% compatibility between Flutter frontend
and backend services. Follow it exactly for seamless integration.
