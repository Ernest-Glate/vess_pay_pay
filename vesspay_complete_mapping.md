VESSPay Complete System Mapping
Database ↔ Backend ↔ Flutter Models ↔ Screens

═══════════════════════════════════════════════════════════════
SYSTEM OVERVIEW
═══════════════════════════════════════════════════════════════

This document maps the COMPLETE data flow:
Database Tables → Backend API → Flutter Models → Mobile Screens

Legend:
📊 Database Table
🔌 Backend Endpoint
📱 Flutter Screen
🎨 Flutter Data Model

═══════════════════════════════════════════════════════════════
1. USER DATA FLOW
═══════════════════════════════════════════════════════════════

📊 DATABASE TABLE: users
┌────────────────────────────────────────────────────────────┐
│ Column Name          │ Type         │ Description          │
├────────────────────────────────────────────────────────────┤
│ id                   │ UUID         │ Primary key          │
│ email                │ VARCHAR(255) │ User email           │
│ password_hash        │ VARCHAR(255) │ Hashed password      │
│ first_name           │ VARCHAR(100) │ First name           │
│ last_name            │ VARCHAR(100) │ Last name            │
│ phone                │ VARCHAR(20)  │ Phone number         │
│ profile_picture_url  │ VARCHAR(500) │ Profile image URL    │
│ email_verified       │ BOOLEAN      │ Email confirmed      │
│ kyc_status           │ VARCHAR(20)  │ KYC status           │
│ kyc_tier             │ INTEGER      │ KYC tier level       │
│ created_at           │ TIMESTAMP    │ Created date         │
│ updated_at           │ TIMESTAMP    │ Updated date         │
└────────────────────────────────────────────────────────────┘

                              ↓

🔌 BACKEND TRANSFORMATION (Python/TypeScript):
```python
def transform_user_to_flutter_model(user_db):
    return {
        "id": str(user_db.id),                                    # UUID → string
        "email": user_db.email,                                   # Direct
        "fullName": f"{user_db.first_name} {user_db.last_name}",  # COMBINE
        "phoneNumber": user_db.phone,                             # Direct
        "profilePictureUrl": user_db.profile_picture_url,         # Direct
        "isVerified": (                                           # COMBINE
            user_db.email_verified and 
            user_db.kyc_status == 'approved'
        ),
        "tierLevel": user_db.kyc_tier                             # Direct
    }
```

                              ↓

🎨 FLUTTER DATA MODEL: User
```dart
class User {
  final String id;
  final String email;
  final String fullName;           // ← Combined from first + last
  final String? phoneNumber;       // ← Optional
  final String? profilePictureUrl; // ← Optional
  final bool isVerified;           // ← Combined from email_verified + kyc_status
  final int tierLevel;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.profilePictureUrl,
    required this.isVerified,
    required this.tierLevel,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    email: json['email'],
    fullName: json['fullName'],
    phoneNumber: json['phoneNumber'],
    profilePictureUrl: json['profilePictureUrl'],
    isVerified: json['isVerified'],
    tierLevel: json['tierLevel'],
  );
}
```

                              ↓

🔌 BACKEND ENDPOINTS USING User MODEL:

┌─────────────────────────────────────────────────────────────┐
│ Endpoint                  │ Method │ Returns               │
├─────────────────────────────────────────────────────────────┤
│ /api/v1/auth/register     │ POST   │ { token, user }       │
│ /api/v1/auth/login        │ POST   │ { token, user }       │
│ /api/v1/auth/me           │ GET    │ user                  │
│ /api/v1/user/profile      │ GET    │ user                  │
│ /api/v1/user/profile      │ PUT    │ user                  │
└─────────────────────────────────────────────────────────────┘

                              ↓

📱 FLUTTER SCREENS USING User MODEL:

┌─────────────────────────────────────────────────────────────┐
│ Screen                      │ Endpoint(s) Used              │
├─────────────────────────────────────────────────────────────┤
│ splash_screen.dart          │ GET /api/v1/auth/me           │
│ login_screen.dart           │ POST /api/v1/auth/login       │
│ onboarding_screen.dart      │ POST /api/v1/auth/register    │
│ dashboard_screen.dart       │ GET /api/v1/auth/me           │
│ profile_screen.dart         │ GET /api/v1/user/profile      │
│                             │ PUT /api/v1/user/profile      │
│ account_settings_screen.dart│ GET /api/v1/user/profile      │
└─────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════
2. WALLET DATA FLOW
═══════════════════════════════════════════════════════════════

📊 DATABASE TABLE: wallets
┌────────────────────────────────────────────────────────────┐
│ Column Name          │ Type         │ Description          │
├────────────────────────────────────────────────────────────┤
│ id                   │ UUID         │ Primary key          │
│ user_id              │ UUID         │ Foreign key → users  │
│ currency             │ VARCHAR(3)   │ ISO code (GHS, USD)  │
│ balance              │ DECIMAL(18,2)│ Current balance      │
│ status               │ VARCHAR(20)  │ active/frozen/closed │
│ created_at           │ TIMESTAMP    │ Created date         │
│ updated_at           │ TIMESTAMP    │ Updated date         │
└────────────────────────────────────────────────────────────┘

IMPORTANT: User has ONE row (currency='GHS'). Other currencies are virtual!

                              ↓

🔌 BACKEND TRANSFORMATION (TypeScript):
```typescript
async function transformWalletsToFlutterModel(user_id: string): Promise<Wallet[]> {
  // Get user's GHS wallet from database
  const ghsWallet = await db.wallets.findOne({ user_id, currency: 'GHS' });
  
  // Get current FX rates
  const fxRates = {
    'USD': 12.50,  // GHS to USD
    'EUR': 13.80,  // GHS to EUR
    'GBP': 15.90   // GHS to GBP
  };
  
  const currencySymbols = {
    'GHS': '₵',
    'USD': '$',
    'EUR': '€',
    'GBP': '£'
  };
  
  const accentColors = {
    'GHS': '0xFF4CAF50',  // Green
    'USD': '0xFF42A5F5',  // Blue
    'EUR': '0xFF9C27B0',  // Purple
    'GBP': '0xFFFF9800'   // Orange
  };
  
  // Create array with GHS + virtual wallets
  const wallets: Wallet[] = [
    // Physical GHS wallet
    {
      id: ghsWallet.id,
      currency: 'GHS',
      symbol: '₵',
      balance: parseFloat(ghsWallet.balance.toFixed(2)),
      accentColor: '0xFF4CAF50',
      isPrimary: true
    },
    // Virtual USD wallet
    {
      id: `${ghsWallet.id}-usd`,
      currency: 'USD',
      symbol: '$',
      balance: parseFloat((ghsWallet.balance / fxRates.USD).toFixed(2)),
      accentColor: '0xFF42A5F5',
      isPrimary: false
    },
    // Virtual EUR wallet
    {
      id: `${ghsWallet.id}-eur`,
      currency: 'EUR',
      symbol: '€',
      balance: parseFloat((ghsWallet.balance / fxRates.EUR).toFixed(2)),
      accentColor: '0xFF9C27B0',
      isPrimary: false
    },
    // Virtual GBP wallet
    {
      id: `${ghsWallet.id}-gbp`,
      currency: 'GBP',
      symbol: '£',
      balance: parseFloat((ghsWallet.balance / fxRates.GBP).toFixed(2)),
      accentColor: '0xFFFF9800',
      isPrimary: false
    }
  ];
  
  return wallets;
}
```

Example:
Database: { id: "abc-123", currency: "GHS", balance: 1000.00 }
Returns:  [
  { id: "abc-123", currency: "GHS", balance: 1000.00, isPrimary: true },
  { id: "abc-123-usd", currency: "USD", balance: 80.00, isPrimary: false },
  { id: "abc-123-eur", currency: "EUR", balance: 72.50, isPrimary: false },
  { id: "abc-123-gbp", currency: "GBP", balance: 62.89, isPrimary: false }
]

                              ↓

🎨 FLUTTER DATA MODEL: Wallet
```dart
class Wallet {
  final String id;
  final String currency;
  final String symbol;
  final double balance;
  final String accentColor;  // Flutter Color format: "0xFFRRGGBB"
  final bool isPrimary;

  Wallet({
    required this.id,
    required this.currency,
    required this.symbol,
    required this.balance,
    required this.accentColor,
    required this.isPrimary,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
    id: json['id'],
    currency: json['currency'],
    symbol: json['symbol'],
    balance: json['balance'].toDouble(),
    accentColor: json['accentColor'],
    isPrimary: json['isPrimary'],
  );
  
  Color get color => Color(int.parse(accentColor));
}
```

                              ↓

🔌 BACKEND ENDPOINTS USING Wallet MODEL:

┌─────────────────────────────────────────────────────────────┐
│ Endpoint                  │ Method │ Returns               │
├─────────────────────────────────────────────────────────────┤
│ /api/v1/wallets           │ GET    │ Wallet[]              │
│ /api/v1/wallets/:id/fund  │ POST   │ { newBalance: num }   │
└─────────────────────────────────────────────────────────────┘

                              ↓

📱 FLUTTER SCREENS USING Wallet MODEL:

┌─────────────────────────────────────────────────────────────┐
│ Screen                      │ Endpoint(s) Used              │
├─────────────────────────────────────────────────────────────┤
│ dashboard_screen.dart       │ GET /api/v1/wallets           │
│ wallet_screen.dart          │ GET /api/v1/wallets           │
│ add_money_screen.dart       │ POST /api/v1/wallets/:id/fund │
│ currency_exchange_screen.dart│ GET /api/v1/wallets          │
└─────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════
3. TRANSACTION DATA FLOW
═══════════════════════════════════════════════════════════════

📊 DATABASE TABLE: transactions
┌────────────────────────────────────────────────────────────┐
│ Column Name              │ Type         │ Description       │
├────────────────────────────────────────────────────────────┤
│ id                       │ UUID         │ Primary key       │
│ user_id                  │ UUID         │ FK → users        │
│ wallet_id                │ UUID         │ FK → wallets      │
│ transaction_type         │ VARCHAR(50)  │ Type of txn       │
│ amount                   │ DECIMAL(18,2)│ Amount (signed)   │
│ currency                 │ VARCHAR(3)   │ ISO code          │
│ description              │ TEXT         │ Description       │
│ status                   │ VARCHAR(20)  │ Status            │
│ external_transaction_id  │ VARCHAR(255) │ Provider ref      │
│ created_at               │ TIMESTAMP    │ Created date      │
│ completed_at             │ TIMESTAMP    │ Completed date    │
└────────────────────────────────────────────────────────────┘

transaction_type values: 'deposit', 'payment', 'refund', 'fee', 'withdrawal', 'exchange'
amount: Negative for debits, Positive for credits (in database)

                              ↓

🔌 BACKEND TRANSFORMATION (TypeScript):
```typescript
function transformTransactionToFlutterModel(tx: TransactionEntity): Transaction {
  // Map database transaction_type to Flutter's simplified types
  const typeMapping: Record<string, 'credit' | 'debit' | 'exchange'> = {
    'deposit': 'credit',
    'refund': 'credit',
    'incoming_payment': 'credit',
    'payment': 'debit',
    'withdrawal': 'debit',
    'fee': 'debit',
    'outgoing_payment': 'debit',
    'exchange': 'exchange'
  };
  
  return {
    id: tx.id,
    type: typeMapping[tx.transaction_type] || 'debit',
    amount: Math.abs(parseFloat(tx.amount.toFixed(2))), // ALWAYS POSITIVE!
    currency: tx.currency,
    description: tx.description,
    createdAt: tx.created_at.toISOString(), // ISO 8601 with milliseconds
    status: tx.status as 'pending' | 'completed' | 'failed',
    reference: tx.external_transaction_id || undefined
  };
}
```

Example Database Row:
{
  id: "txn-123",
  transaction_type: "payment",
  amount: -50.00,              // Negative in DB
  currency: "GHS",
  description: "Payment to +233241234567",
  status: "completed",
  external_transaction_id: "MTN-TXN-12345",
  created_at: "2025-02-05 10:30:00.000"
}

Transforms To:
{
  id: "txn-123",
  type: "debit",               // Mapped from "payment"
  amount: 50.00,               // Positive in Flutter
  currency: "GHS",
  description: "Payment to +233241234567",
  createdAt: "2025-02-05T10:30:00.000Z",  // ISO 8601
  status: "completed",
  reference: "MTN-TXN-12345"
}

                              ↓

🎨 FLUTTER DATA MODEL: Transaction
```dart
class Transaction {
  final String id;
  final String type;          // 'credit', 'debit', or 'exchange'
  final double amount;        // ALWAYS positive
  final String currency;
  final String description;
  final String createdAt;     // ISO 8601 string
  final String status;        // 'pending', 'completed', 'failed'
  final String? reference;    // Optional external reference

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.description,
    required this.createdAt,
    required this.status,
    this.reference,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    type: json['type'],
    amount: json['amount'].toDouble(),
    currency: json['currency'],
    description: json['description'],
    createdAt: json['createdAt'],
    status: json['status'],
    reference: json['reference'],
  );
  
  // Helper methods
  bool get isCredit => type == 'credit';
  bool get isDebit => type == 'debit';
  bool get isExchange => type == 'exchange';
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  
  DateTime get date => DateTime.parse(createdAt);
}
```

                              ↓

🔌 BACKEND ENDPOINTS USING Transaction MODEL:

┌─────────────────────────────────────────────────────────────┐
│ Endpoint                     │ Method │ Returns            │
├─────────────────────────────────────────────────────────────┤
│ /api/v1/transactions         │ GET    │ Transaction[]      │
│ /api/v1/transactions/:id     │ GET    │ Transaction        │
│ /api/v1/transfers/send       │ POST   │ Transaction        │
│ /api/v1/transfers/request    │ POST   │ { ... }            │
│ /api/v1/exchange             │ POST   │ Transaction        │
└─────────────────────────────────────────────────────────────┘

                              ↓

📱 FLUTTER SCREENS USING Transaction MODEL:

┌─────────────────────────────────────────────────────────────┐
│ Screen                        │ Endpoint(s) Used            │
├─────────────────────────────────────────────────────────────┤
│ dashboard_screen.dart         │ GET /api/v1/transactions    │
│                               │   ?limit=5                  │
│ transactions_screen.dart      │ GET /api/v1/transactions    │
│                               │   ?limit=20&offset=0        │
│ transaction_history_screen.dart│ GET /api/v1/transactions   │
│                               │   (with filters)            │
│ transaction_details_screen.dart│ GET /api/v1/transactions/:id│
│ payment_success_screen.dart   │ GET /api/v1/transactions/:id│
│ exchange_success_screen.dart  │ GET /api/v1/transactions/:id│
│ pay_momo_screen.dart          │ POST /api/v1/transfers/send │
│ send_money_screen.dart        │ POST /api/v1/transfers/send │
└─────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════
4. COMPLETE SCREEN-TO-DATA-MODEL MAPPING
═══════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────┐
│ AUTHENTICATION SCREENS (5)                                   │
├─────────────────────────────────────────────────────────────┤
│ Screen               │ Models Used    │ Endpoints           │
├─────────────────────────────────────────────────────────────┤
│ splash_screen.dart   │ User           │ GET /auth/me        │
│ landing_screen.dart  │ -              │ -                   │
│ login_screen.dart    │ User           │ POST /auth/login    │
│ mfa_screen.dart      │ User           │ POST /auth/mfa      │
│ onboarding_screen.dart│ User          │ POST /auth/register │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ DASHBOARD SCREEN (1)                                         │
├─────────────────────────────────────────────────────────────┤
│ Screen               │ Models Used    │ Endpoints           │
├─────────────────────────────────────────────────────────────┤
│ dashboard_screen.dart│ User           │ GET /auth/me        │
│                      │ Wallet[]       │ GET /wallets        │
│                      │ Transaction[]  │ GET /transactions   │
│                      │                │   ?limit=5          │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ PAYMENT SCREENS (7)                                          │
├─────────────────────────────────────────────────────────────┤
│ Screen                    │ Models      │ Endpoints         │
├─────────────────────────────────────────────────────────────┤
│ add_money_screen.dart     │ Wallet      │ GET /wallets      │
│                           │             │ POST /wallets/:id/│
│                           │             │   fund            │
├─────────────────────────────────────────────────────────────┤
│ currency_exchange_screen  │ Wallet[]    │ GET /wallets      │
│   .dart                   │             │ POST /exchange    │
├─────────────────────────────────────────────────────────────┤
│ exchange_success_screen   │ Transaction │ GET /transactions/│
│   .dart                   │             │   :id             │
├─────────────────────────────────────────────────────────────┤
│ pay_momo_screen.dart      │ Wallet      │ GET /wallets      │
│                           │ Transaction │ POST /transfers/  │
│                           │             │   send            │
├─────────────────────────────────────────────────────────────┤
│ payment_success_screen    │ Transaction │ GET /transactions/│
│   .dart                   │             │   :id             │
├─────────────────────────────────────────────────────────────┤
│ request_money_screen.dart │ -           │ POST /transfers/  │
│                           │             │   request         │
├─────────────────────────────────────────────────────────────┤
│ send_money_screen.dart    │ Wallet      │ GET /wallets      │
│                           │ Transaction │ POST /transfers/  │
│                           │             │   send            │
├─────────────────────────────────────────────────────────────┤
│ transaction_details_screen│ Transaction │ GET /transactions/│
│   .dart                   │             │   :id             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ PROFILE SCREENS (4)                                          │
├─────────────────────────────────────────────────────────────┤
│ Screen                    │ Models      │ Endpoints         │
├─────────────────────────────────────────────────────────────┤
│ profile_screen.dart       │ User        │ GET /user/profile │
│                           │             │ PUT /user/profile │
├─────────────────────────────────────────────────────────────┤
│ account_settings_screen   │ User        │ GET /user/settings│
│   .dart                   │             │ PUT /user/settings│
├─────────────────────────────────────────────────────────────┤
│ change_password_screen    │ -           │ POST /user/change-│
│   .dart                   │             │   password        │
├─────────────────────────────────────────────────────────────┤
│ security_screen.dart      │ User        │ GET /user/security│
│                           │             │ POST /user/mfa    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ WALLET SCREENS (3)                                           │
├─────────────────────────────────────────────────────────────┤
│ Screen                    │ Models      │ Endpoints         │
├─────────────────────────────────────────────────────────────┤
│ wallet_screen.dart        │ Wallet[]    │ GET /wallets      │
├─────────────────────────────────────────────────────────────┤
│ transactions_screen.dart  │ Transaction[]│ GET /transactions│
│                           │             │   ?limit=20&      │
│                           │             │   offset=0        │
├─────────────────────────────────────────────────────────────┤
│ transaction_history_screen│ Transaction[]│ GET /transactions│
│   .dart                   │             │   (with filters)  │
└─────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════
5. DATABASE-TO-FLUTTER FIELD MAPPING CHEAT SHEET
═══════════════════════════════════════════════════════════════

USER MODEL:
┌───────────────────────┬─────────────────────┬──────────────┐
│ Database Field        │ Flutter Field       │ Transform    │
├───────────────────────┼─────────────────────┼──────────────┤
│ id                    │ id                  │ UUID→string  │
│ email                 │ email               │ Direct       │
│ first_name + last_name│ fullName            │ Concatenate  │
│ phone                 │ phoneNumber         │ Direct       │
│ profile_picture_url   │ profilePictureUrl   │ Direct       │
│ email_verified +      │ isVerified          │ AND logic    │
│   kyc_status          │                     │              │
│ kyc_tier              │ tierLevel           │ Direct       │
└───────────────────────┴─────────────────────┴──────────────┘

WALLET MODEL:
┌───────────────────────┬─────────────────────┬──────────────┐
│ Database Field        │ Flutter Field       │ Transform    │
├───────────────────────┼─────────────────────┼──────────────┤
│ id                    │ id                  │ UUID→string  │
│ currency              │ currency            │ Direct       │
│ -                     │ symbol              │ Map from curr│
│ balance               │ balance             │ DECIMAL→float│
│ -                     │ accentColor         │ Map from curr│
│ currency=='GHS'       │ isPrimary           │ Boolean      │
└───────────────────────┴─────────────────────┴──────────────┘

TRANSACTION MODEL:
┌───────────────────────┬─────────────────────┬──────────────┐
│ Database Field        │ Flutter Field       │ Transform    │
├───────────────────────┼─────────────────────┼──────────────┤
│ id                    │ id                  │ UUID→string  │
│ transaction_type      │ type                │ Map to 3 vals│
│ amount                │ amount              │ ABS + format │
│ currency              │ currency            │ Direct       │
│ description           │ description         │ Direct       │
│ created_at            │ createdAt           │ ISO 8601     │
│ status                │ status              │ Direct       │
│ external_transaction_id│ reference          │ Direct       │
└───────────────────────┴─────────────────────┴──────────────┘

═══════════════════════════════════════════════════════════════
6. DATA TYPE CONVERSION RULES
═══════════════════════════════════════════════════════════════

Database → JSON → Flutter

UUID:
  Database: uuid                    (PostgreSQL UUID type)
  JSON:     "550e8400-e29b-41d4..." (string, lowercase, with hyphens)
  Flutter:  String                  (no special UUID type)

DECIMAL:
  Database: 1250.50                 (DECIMAL(18,2))
  JSON:     1250.50                 (number, not string)
  Flutter:  double                  (1250.50)

BOOLEAN:
  Database: TRUE                    (PostgreSQL BOOLEAN)
  JSON:     true                    (boolean, not "true")
  Flutter:  bool                    (true)

TIMESTAMP:
  Database: 2025-02-05 10:30:00.000 (TIMESTAMP)
  JSON:     "2025-02-05T10:30:00.000Z" (ISO 8601 string, UTC)
  Flutter:  String → DateTime.parse()

VARCHAR:
  Database: "John Doe"              (VARCHAR)
  JSON:     "John Doe"              (string)
  Flutter:  String                  ("John Doe")

INTEGER:
  Database: 1                       (INTEGER)
  JSON:     1                       (number)
  Flutter:  int                     (1)

NULL VALUES:
  Database: NULL
  JSON:     null                    (not omitted!)
  Flutter:  String? / int?          (nullable types)

═══════════════════════════════════════════════════════════════
7. SPECIAL TRANSFORMATION LOGIC
═══════════════════════════════════════════════════════════════

FULL NAME COMBINATION:
```sql
-- Database query
SELECT 
  CONCAT(first_name, ' ', last_name) as full_name
FROM users;
```
```json
// JSON response
{ "fullName": "John Doe" }
```

IS VERIFIED LOGIC:
```sql
-- Database logic (pseudo-SQL)
SELECT 
  (email_verified = TRUE AND kyc_status = 'approved') as is_verified
FROM users;
```
```json
// JSON response
{ "isVerified": true }
```

TRANSACTION AMOUNT ABSOLUTE VALUE:
```sql
-- Database: amount can be negative
SELECT amount FROM transactions; -- Returns -50.00
```
```typescript
// Backend transformation
const amount = Math.abs(transaction.amount); // Returns 50.00
```
```json
// JSON response
{ "amount": 50.00 }
```

TRANSACTION TYPE MAPPING:
```typescript
// Backend logic
const typeMap = {
  'deposit': 'credit',
  'refund': 'credit',
  'payment': 'debit',
  'fee': 'debit',
  'withdrawal': 'debit',
  'exchange': 'exchange'
};
const flutterType = typeMap[db_transaction_type];
```

MULTI-WALLET GENERATION:
```typescript
// Backend: One DB row → Multiple JSON objects
const ghsWallet = await getWallet(userId); // One DB row
const wallets = [
  generateWallet('GHS', ghsWallet.balance, true),
  generateWallet('USD', ghsWallet.balance / 12.50, false),
  generateWallet('EUR', ghsWallet.balance / 13.80, false),
  generateWallet('GBP', ghsWallet.balance / 15.90, false)
];
```

FLUTTER COLOR FORMAT:
```typescript
// Backend: Currency code → Flutter Color string
const colorMap = {
  'GHS': '0xFF4CAF50',  // Must include alpha channel (0xFF)
  'USD': '0xFF42A5F5',
  'EUR': '0xFF9C27B0',
  'GBP': '0xFFFF9800'
};
```

ISO 8601 TIMESTAMP:
```typescript
// Backend transformation
const createdAt = transaction.created_at.toISOString();
// Returns: "2025-02-05T10:30:00.000Z"
// Format: YYYY-MM-DDTHH:mm:ss.sssZ
```

═══════════════════════════════════════════════════════════════
8. VALIDATION RULES
═══════════════════════════════════════════════════════════════

Before sending to Flutter, validate:

USER:
✓ id is valid UUID string
✓ email is valid email format
✓ fullName is not empty
✓ tierLevel is 0-3
✓ isVerified is boolean

WALLET:
✓ id is valid UUID string
✓ currency is ISO 4217 code (USD, GHS, EUR, GBP)
✓ symbol matches currency
✓ balance is non-negative number with 2 decimals
✓ accentColor is "0xFFRRGGBB" format
✓ isPrimary is boolean
✓ Exactly ONE wallet has isPrimary: true

TRANSACTION:
✓ id is valid UUID string
✓ type is 'credit' | 'debit' | 'exchange'
✓ amount is ALWAYS positive
✓ currency is valid ISO code
✓ createdAt is valid ISO 8601 string
✓ status is 'pending' | 'completed' | 'failed'

═══════════════════════════════════════════════════════════════
9. COMMON MISTAKES TO AVOID
═══════════════════════════════════════════════════════════════

❌ WRONG: Separate first/last name fields
{
  "firstName": "John",
  "lastName": "Doe"
}

✅ CORRECT: Combined fullName
{
  "fullName": "John Doe"
}

───────────────────────────────────────────────────────────────

❌ WRONG: Snake_case field names
{
  "profile_picture_url": "https://..."
}

✅ CORRECT: camelCase field names
{
  "profilePictureUrl": "https://..."
}

───────────────────────────────────────────────────────────────

❌ WRONG: Negative transaction amounts
{
  "amount": -50.00
}

✅ CORRECT: Always positive, type indicates direction
{
  "amount": 50.00,
  "type": "debit"
}

───────────────────────────────────────────────────────────────

❌ WRONG: Missing ISO 8601 format
{
  "createdAt": "2025-02-05 10:30:00"
}

✅ CORRECT: Full ISO 8601 with timezone
{
  "createdAt": "2025-02-05T10:30:00.000Z"
}

───────────────────────────────────────────────────────────────

❌ WRONG: Color without alpha channel
{
  "accentColor": "#4CAF50"
}

✅ CORRECT: Flutter Color format with alpha
{
  "accentColor": "0xFF4CAF50"
}

───────────────────────────────────────────────────────────────

❌ WRONG: Single wallet object
{
  "wallet": { "currency": "GHS", "balance": 1000.00 }
}

✅ CORRECT: Array with virtual wallets
{
  "wallets": [
    { "currency": "GHS", "balance": 1000.00, "isPrimary": true },
    { "currency": "USD", "balance": 80.00, "isPrimary": false }
  ]
}

───────────────────────────────────────────────────────────────

❌ WRONG: Omitting optional fields
{
  "id": "abc-123",
  "email": "user@example.com",
  "fullName": "John Doe"
  // phoneNumber missing
}

✅ CORRECT: Include with null value
{
  "id": "abc-123",
  "email": "user@example.com",
  "fullName": "John Doe",
  "phoneNumber": null
}

═══════════════════════════════════════════════════════════════
10. QUICK REFERENCE: BACKEND CHECKLIST
═══════════════════════════════════════════════════════════════

When implementing each endpoint:

[ ] Field names in camelCase (not snake_case)
[ ] UUIDs converted to lowercase strings with hyphens
[ ] DECIMALs converted to floats with 2 decimal places
[ ] Timestamps in ISO 8601 format with milliseconds and Z
[ ] Booleans as true/false (not 1/0)
[ ] Optional fields included with null (not omitted)
[ ] Transaction amounts always positive
[ ] Transaction types mapped to credit/debit/exchange
[ ] Wallet array includes virtual currencies
[ ] Only GHS wallet has isPrimary: true
[ ] Flutter color codes in "0xFFRRGGBB" format
[ ] fullName combined from first + last
[ ] isVerified combines email_verified + kyc_status
[ ] Status values match Flutter expectations

═══════════════════════════════════════════════════════════════
END OF MAPPING DOCUMENT
═══════════════════════════════════════════════════════════════

This document provides the complete mapping between database,
backend API, and Flutter models. Use it as the source of truth
for all data transformations.
