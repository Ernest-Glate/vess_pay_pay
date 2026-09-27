VESSPay Backend API Specification (Screen-Mapped)
TypeScript (NestJS) + Python (FastAPI)
Version 2.0 - Aligned with 20 Flutter Screens

═══════════════════════════════════════════════════════════════
SCREEN-TO-API MAPPING
═══════════════════════════════════════════════════════════════

This specification defines EXACT API endpoints required by each of the 20
Flutter screens currently implemented in the mobile app.

ARCHITECTURE:
- TypeScript (NestJS): Money operations, wallet, payments, transactions
- Python (FastAPI): Authentication, KYC, user management, security

═══════════════════════════════════════════════════════════════
AUTHENTICATION SCREENS (5 screens)
═══════════════════════════════════════════════════════════════

───────────────────────────────────────────────────────────────
1. SPLASH_SCREEN.DART
───────────────────────────────────────────────────────────────
Service: Python (FastAPI)
Purpose: Initial app load, token validation, user session check

Required Endpoints:

GET /api/v1/auth/session/validate
Headers:
  Authorization: Bearer {access_token}
Response 200:
  {
    "valid": true,
    "user_id": "uuid",
    "kyc_status": "approved",
    "kyc_tier": 1,
    "requires_mfa": false,
    "session_expires_at": "2025-02-06T10:00:00Z"
  }
Response 401:
  {
    "valid": false,
    "error": "Token expired or invalid"
  }

GET /api/v1/config/app
Response 200:
  {
    "min_app_version": "1.0.0",
    "force_update": false,
    "maintenance_mode": false,
    "supported_countries": ["GH"],
    "supported_currencies": ["GHS", "USD", "EUR", "GBP"],
    "features": {
      "momo_enabled": true,
      "card_funding_enabled": true,
      "p2p_enabled": true
    }
  }

───────────────────────────────────────────────────────────────
2. LANDING_SCREEN.DART
───────────────────────────────────────────────────────────────
Service: Python (FastAPI)
Purpose: Marketing content, public information

Required Endpoints:

GET /api/v1/public/features
Response 200:
  {
    "features": [
      {
        "title": "Send Money to Any MoMo",
        "description": "Pay any Ghana mobile money number instantly",
        "icon": "send_money"
      },
      {
        "title": "No SIM Card Required",
        "description": "Perfect for tourists and diaspora",
        "icon": "no_sim"
      }
    ],
    "supported_networks": ["MTN", "Vodafone", "AirtelTigo"],
    "exchange_rates": {
      "USD_GHS": 12.50,
      "EUR_GHS": 13.80,
      "GBP_GHS": 15.90
    }
  }

GET /api/v1/public/faq
Response 200:
  {
    "faqs": [
      {
        "question": "How do I fund my wallet?",
        "answer": "You can fund via international card or at partner kiosks"
      }
    ]
  }

───────────────────────────────────────────────────────────────
3. LOGIN_SCREEN.DART
───────────────────────────────────────────────────────────────
Service: Python (FastAPI)
Purpose: User authentication, session creation

Required Endpoints:

POST /api/v1/auth/login
Request:
  {
    "email": "user@example.com",
    "password": "SecurePassword123!",
    "device_id": "device-uuid-here",
    "device_name": "iPhone 13 Pro",
    "device_type": "ios"
  }
Response 200 (No MFA):
  {
    "access_token": "jwt-token",
    "refresh_token": "refresh-token",
    "token_type": "Bearer",
    "expires_in": 900,
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "kyc_status": "approved",
      "kyc_tier": 1,
      "phone": "+233241234567"
    },
    "requires_mfa": false
  }
Response 200 (MFA Required):
  {
    "requires_mfa": true,
    "mfa_token": "temporary-token",
    "mfa_methods": ["totp", "sms"],
    "user_id": "uuid"
  }
Response 401:
  {
    "error": "INVALID_CREDENTIALS",
    "message": "Email or password is incorrect",
    "attempts_remaining": 3
  }
Response 423:
  {
    "error": "ACCOUNT_LOCKED",
    "message": "Account locked due to multiple failed attempts",
    "locked_until": "2025-02-05T11:00:00Z"
  }

POST /api/v1/auth/biometric/login
Request:
  {
    "user_id": "uuid",
    "biometric_token": "encrypted-biometric-token",
    "device_id": "device-uuid-here"
  }
Response 200:
  {
    "access_token": "jwt-token",
    "refresh_token": "refresh-token",
    "token_type": "Bearer",
    "expires_in": 900
  }

POST /api/v1/auth/refresh
Request:
  {
    "refresh_token": "refresh-token-here"
  }
Response 200:
  {
    "access_token": "new-jwt-token",
    "refresh_token": "new-refresh-token",
    "expires_in": 900
  }

POST /api/v1/auth/forgot-password
Request:
  {
    "email": "user@example.com"
  }
Response 200:
  {
    "message": "Password reset email sent",
    "reset_token_expires_at": "2025-02-05T12:00:00Z"
  }

───────────────────────────────────────────────────────────────
4. MFA_SCREEN.DART
───────────────────────────────────────────────────────────────
Service: Python (FastAPI)
Purpose: Multi-factor authentication verification

Required Endpoints:

POST /api/v1/auth/mfa/verify
Request:
  {
    "mfa_token": "temporary-token-from-login",
    "code": "123456",
    "method": "totp"
  }
Response 200:
  {
    "access_token": "jwt-token",
    "refresh_token": "refresh-token",
    "token_type": "Bearer",
    "expires_in": 900,
    "user": { /* user object */ }
  }
Response 401:
  {
    "error": "INVALID_CODE",
    "message": "Invalid or expired verification code",
    "attempts_remaining": 2
  }

POST /api/v1/auth/mfa/resend
Request:
  {
    "mfa_token": "temporary-token",
    "method": "sms"
  }
Response 200:
  {
    "message": "Verification code sent",
    "expires_at": "2025-02-05T10:10:00Z"
  }

───────────────────────────────────────────────────────────────
5. ONBOARDING_SCREEN.DART
───────────────────────────────────────────────────────────────
Service: Python (FastAPI)
Purpose: User registration and KYC submission

Required Endpoints:

POST /api/v1/auth/register
Request:
  {
    "email": "newuser@example.com",
    "password": "SecurePassword123!",
    "first_name": "John",
    "last_name": "Doe",
    "phone": "+233241234567",
    "date_of_birth": "1990-01-01",
    "nationality": "USA",
    "terms_accepted": true,
    "device_id": "device-uuid"
  }
Response 201:
  {
    "user_id": "uuid",
    "email": "newuser@example.com",
    "kyc_status": "pending",
    "message": "Registration successful. Please complete KYC.",
    "verification_email_sent": true
  }
Response 400:
  {
    "error": "EMAIL_EXISTS",
    "message": "An account with this email already exists"
  }

POST /api/v1/auth/verify-email
Request:
  {
    "email": "newuser@example.com",
    "code": "123456"
  }
Response 200:
  {
    "verified": true,
    "message": "Email verified successfully"
  }

POST /api/v1/kyc/submit
Headers:
  Authorization: Bearer {access_token}
  Content-Type: multipart/form-data
Request:
  {
    "passport_number": "N12345678",
    "passport_expiry": "2030-12-31",
    "passport_image": <file>,
    "selfie_image": <file>,
    "proof_of_address": <file> (optional for tier 1)
  }
Response 200:
  {
    "kyc_id": "uuid",
    "status": "under_review",
    "estimated_review_time": "2-24 hours",
    "message": "KYC documents submitted successfully"
  }

GET /api/v1/kyc/status
Headers:
  Authorization: Bearer {access_token}
Response 200:
  {
    "kyc_status": "approved",
    "kyc_tier": 1,
    "approved_at": "2025-02-05T09:00:00Z",
    "limits": {
      "max_transaction": 500.00,
      "daily_limit": 2000.00,
      "monthly_limit": 10000.00
    },
    "next_tier_requirements": [
      "Proof of address document required for Tier 2"
    ]
  }

═══════════════════════════════════════════════════════════════
DASHBOARD SCREEN (1 screen)
═══════════════════════════════════════════════════════════════

───────────────────────────────────────────────────────────────
6. DASHBOARD_SCREEN.DART
───────────────────────────────────────────────────────────────
Services: TypeScript (wallet data) + Python (user data)

Required Endpoints:

GET /api/v1/wallet/balance
Headers:
  Authorization: Bearer {access_token}
Service: TypeScript (NestJS)
Response 200:
  {
    "balance": 1250.50,
    "currency": "GHS",
    "pending_amount": 50.00,
    "available_balance": 1200.50,
    "last_updated": "2025-02-05T10:00:00Z"
  }

GET /api/v1/transactions/recent
Headers:
  Authorization: Bearer {access_token}
Service: TypeScript (NestJS)
Query Params:
  limit=5
Response 200:
  {
    "transactions": [
      {
        "id": "txn-uuid-1",
        "type": "payment",
        "amount": -50.00,
        "currency": "GHS",
        "recipient_phone": "+233241234567",
        "recipient_name": "Kwame Mensah",
        "status": "completed",
        "created_at": "2025-02-05T09:30:00Z",
        "description": "MoMo payment"
      },
      {
        "id": "txn-uuid-2",
        "type": "deposit",
        "amount": 200.00,
        "currency": "GHS",
        "payment_method": "card",
        "card_last4": "4242",
        "status": "completed",
        "created_at": "2025-02-04T15:20:00Z",
        "description": "Card deposit"
      }
    ],
    "total_count": 25
  }

GET /api/v1/user/profile
Headers:
  Authorization: Bearer {access_token}
Service: Python (FastAPI)
Response 200:
  {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "phone": "+233241234567",
      "kyc_status": "approved",
      "kyc_tier": 1,
      "profile_picture_url": "https://cdn.vesspay.com/profile/uuid.jpg"
    }
  }

GET /api/v1/wallet/statistics
Headers:
  Authorization: Bearer {access_token}
Service: TypeScript (NestJS)
Query Params:
  period=30d
Response 200:
  {
    "period": "30d",
    "total_deposits": 1500.00,
    "total_payments": 750.00,
    "total_fees": 15.00,
    "transaction_count": 12,
    "top_recipients": [
      {
        "phone": "+233241234567",
        "name": "Kwame Mensah",
        "amount": 250.00,
        "count": 3
      }
    ],
    "daily_spending": [
      {
        "date": "2025-02-05",
        "amount": 150.00
      }
    ]
  }

GET /api/v1/notifications/unread
Headers:
  Authorization: Bearer {access_token}
Service: Python (FastAPI)
Response 200:
  {
    "unread_count": 3,
    "notifications": [
      {
        "id": "notif-uuid-1",
        "type": "payment_success",
        "title": "Payment Successful",
        "message": "GHS 50 sent to +233241234567",
        "created_at": "2025-02-05T09:30:00Z",
        "read": false
      }
    ]
  }

═══════════════════════════════════════════════════════════════
PAYMENTS SCREENS (7 screens)
═══════════════════════════════════════════════════════════════

───────────────────────────────────────────────────────────────
7. ADD_MONEY_SCREEN.DART
───────────────────────────────────────────────────────────────
Service: TypeScript (NestJS)
Purpose: Fund wallet via card or other methods

Required Endpoints:

GET /api/v1/funding/methods
Headers:
  Authorization: Bearer {access_token}
Response 200:
  {
    "methods": [
      {
        "id": "card",
        "name": "Credit/Debit Card",
        "enabled": true,
        "providers": ["stripe", "flutterwave"],
        "min_amount": 10.00,
        "max_amount": 10000.00,
        "currencies": ["USD", "EUR", "GBP"],
        "fee_percentage": 3.4,
        "fee_fixed": 0.30
      },
      {
        "id": "bank_transfer",
        "name": "Bank Transfer",
        "enabled": true,
        "min_amount": 50.00,
        "max_amount": 50000.00,
        "currencies": ["USD", "GHS"],
        "fee_percentage": 0,
        "fee_fixed": 0
      }
    ]
  }

POST /api/v1/funding/initiate
Headers:
  Authorization: Bearer {access_token}
Request:
  {
    "amount": 100.00,
    "currency": "USD",
    "method": "card",
    "provider": "stripe"
  }
Response 200:
  {
    "funding_id": "fund-uuid",
    "amount": 100.00,
    "currency": "USD",
    "amount_ghs": 1250.00,
    "fx_rate": 12.50,
    "fx_spread_percentage": 2.5,
    "effective_rate": 12.19,
    "fees": {
      "provider_fee": 3.70,
      "total_charge": 103.70
    },
    "client_secret": "stripe-payment-intent-secret",
    "expires_at": "2025-02-05T10:15:00Z"
  }

POST /api/v1/funding/confirm
Headers:
  Authorization: Bearer {access_token}
Request:
  {
    "funding_id": "fund-uuid",
    "payment_method_id": "pm_xxxxx",
    "provider_transaction_id": "pi_xxxxx"
  }
Response 200:
  {
    "funding_id": "fund-uuid",
    "status": "completed",
    "amount_credited": 1250.00,
    "currency": "GHS",
    "new_balance": 2450.50,
    "completed_at": "2025-02-05T10:05:00Z"
  }

GET /api/v1/funding/history
Headers:
  Authorization: Bearer {access_token}
Query Params:
  page=1&limit=20
Response 200:
  {
    "fundings": [
      {
        "id": "fund-uuid",
        "amount": 100.00,
        "currency": "USD",
        "amount_ghs": 1250.00,
        "method": "card",
        "card_last4": "4242",
        "card_brand": "visa",
        "status": "completed",
        "created_at": "2025-02-05T10:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 5,
      "has_more": false
    }
  }

───────────────────────────────────────────────────────────────
8. CURRENCY_EXCHANGE_SCREEN.DART
───────────────────────────────────────────────────────────────
Service: TypeScript (NestJS)
Purpose: View and calculate FX conversions

Required Endpoints:

GET /api/v1/fx/rates
Query Params:
  from=USD&to=GHS
Response 200:
  {
    "from_currency": "USD",
    "to_currency": "GHS",
    "base_rate": 12.50,
    "spread_percentage": 2.5,
    "effective_rate": 12.19,
    "rate_updated_at": "2025-02-05T10:00:00Z",
    "valid_until": "2025-02-05T10:05:00Z"
  }

POST /api/v1/fx/calculate
Request:
  {
    "amount": 100.00,
    "from_currency": "USD",
    "to_currency": "GHS"
  }
Response 200:
  {
    "amount_from": 100.00,
    "currency_from": "USD",
    "amount_to": 1219.00,
    "currency_to": "GHS",
    "fx_rate": 12.50,
    "effective_rate": 12.19,
    "spread_percentage": 2.5,
    "spread_amount": 31.00
  }

GET /api/v1/fx/supported-currencies
Response 200:
  {
    "currencies": [
      {
        "code": "USD",
        "name": "US Dollar",
        "symbol": "$",
        "flag": "🇺🇸"
      },
      {
        "code": "EUR",
        "name": "Euro",
        "symbol": "€",
        "flag": "🇪🇺"
      },
      {
        "code": "GBP",
        "name": "British Pound",
        "symbol": "£",
        "flag": "🇬🇧"
      },
      {
        "code": "GHS",
        "name": "Ghana Cedi",
        "symbol": "GH₵",
        "flag": "🇬🇭"
      }
    ]
  }

───────────────────────────────────────────────────────────────
9. EXCHANGE_SUCCESS_SCREEN.DART
───────────────────────────────────────────────────────────────
Service: TypeScript (NestJS)
Purpose: Show exchange transaction details

Required Endpoints:

GET /api/v1/funding/{funding_id}
Headers:
  Authorization: Bearer {access_token}
Path Params:
  funding_id: uuid
Response 200:
  {
    "id": "fund-uuid",
    "amount": 100.00,
    "currency": "USD",
    "amount_ghs": 1219.00,
    "fx_rate": 12.50,
    "effective_rate": 12.19,
    "spread_percentage": 2.5,
    "method": "card",
    "card_last4": "4242",
    "status": "completed",
    "receipt": {
      "receipt_id": "REC-20250205-001",
      "receipt_url": "https://cdn.vesspay.com/receipts/fund-uuid.pdf"
    },
    "created_at": "2025-02-05T10:00:00Z",
    "completed_at": "2025-02-05T10:02:00Z"
  }

POST /api/v1/funding/{funding_id}/receipt/email
Headers:
  Authorization: Bearer {access_token}
Request:
  {
    "email": "user@example.com"
  }
Response 200:
  {
    "message": "Receipt sent to user@example.com"
  }

───────────────────────────────────────────────────────────────
10. PAY_MOMO_SCREEN.DART
───────────────────────────────────────────────────────────────
Service: TypeScript (NestJS)
Purpose: Send money to MoMo number

Required Endpoints:

POST /api/v1/payment/validate-recipient
Headers:
  Authorization: Bearer {access_token}
Request:
  {
    "phone": "+233241234567"
  }
Response 200:
  {
    "valid": true,
    "phone": "+233241234567",
    "network": "MTN",
    "name": "Kwame Mensah" (optional, if name lookup available)
  }
Response 400:
  {
    "valid": false,
    "error": "Invalid Ghana mobile number"
  }

POST /api/v1/payment/initiate
Headers:
  Authorization: Bearer {access_token}
Request:
  {
    "idempotency_key": "client-generated-uuid",
    "recipient_phone": "+233241234567",
    "amount": 50.00,
    "currency": "GHS",
    "note": "Payment for lunch",
    "recipient_name": "Kwame Mensah" (optional)
  }
Response 200:
  {
    "payment_id": "pay-uuid",
    "idempotency_key": "client-generated-uuid",
    "recipient_phone": "+233241234567",
    "recipient_network": "MTN",
    "amount": 50.00,
    "currency": "GHS",
    "status": "pending",
    "wallet_balance_before": 1250.50,
    "wallet_balance_after": 1200.50,
    "created_at": "2025-02-05T10:10:00Z",
    "expires_at": "2025-02-06T10:10:00Z"
  }
Response 400:
  {
    "error": "INSUFFICIENT_BALANCE",
    "message": "Wallet balance insufficient",
    "required": 50.00,
    "available": 30.00
  }
Response 409:
  {
    "error": "DUPLICATE_PAYMENT",
    "message": "Payment with this idempotency key already exists",
    "existing_payment_id": "pay-uuid-existing"
  }

GET /api/v1/payment/{payment_id}/status
Headers:
  Authorization: Bearer {access_token}
Path Params:
  payment_id: uuid
Response 200:
  {
    "payment_id": "pay-uuid",
    "status": "completed",
    "amount": 50.00,
    "recipient_phone": "+233241234567",
    "external_transaction_id": "momo-txn-12345",
    "completed_at": "2025-02-05T10:12:00Z"
  }

GET /api/v1/payment/limits
Headers:
  Authorization: Bearer {access_token}
Response 200:
  {
    "kyc_tier": 1,
    "limits": {
      "max_transaction": 500.00,
      "daily_limit": 2000.00,
      "monthly_limit": 10000.00,
      "daily_used": 150.00,
      "monthly_used": 1200.00,
      "daily_remaining": 1850.00,
      "monthly_remaining": 8800.00
    }
  }

───────────────────────────────────────────────────────────────
11. PAYMENT_SUCCESS_SCREEN.DART
───────────────────────────────────────────────────────────────
Service: TypeScript (NestJS)
Purpose: Show payment confirmation and details

Required Endpoints:

GET /api/v1/payment/{payment_id}
Headers:
  Authorization: Bearer {access_token}
Response 200:
  {
    "id": "pay-uuid",
    "type": "payment",
    "amount": 50.00,
    "currency": "GHS",
    "recipient_phone": "+233241234567",
    "recipient_name": "Kwame Mensah",
    "recipient_network": "MTN",
    "status": "completed",
    "note": "Payment for lunch",
    "external_transaction_id": "momo-txn-12345",
    "receipt": {
      "receipt_id": "REC-20250205-002",
      "receipt_url": "https://cdn.vesspay.com/receipts/pay-uuid.pdf"
    },
    "created_at": "2025-02-05T10:10:00Z",
    "completed_at": "2025-02-05T10:12:00Z"
  }

POST /api/v1/payment/{payment_id}/receipt/share
Headers:
  Authorization: Bearer {access_token}
Request:
  {
    "method": "email",
    "destination": "user@example.com"
  }
Response 200:
  {
    "message": "Receipt sent successfully"
  }

POST /api/v1/payment/{payment_id}/save-recipient
Headers:
  Authorization: Bearer {access_token}
Request:
  {
    "name": "Kwame Mensah",
    "nickname": "Kwame"
  }
Response 200:
  {
    "recipient_id": "rec-uuid",
    "message": "Recipient saved successfully"
  }

───────────────────────────────────────────────────────────────
12. REQUEST_MONEY_SCREEN.DART
───────────────────────────────────────────────────────────────
Service: TypeScript (NestJS)
Purpose: Generate payment request QR or link

Required Endpoints:

POST /api/v1/payment/request/create
Headers:
  Authorization: Bearer {access_token}
Request:
  {
    "amount": 100.00,
    "currency": "GHS",
    "note": "Payment for services",
    "expires_in_minutes": 60
  }
Response 200:
  {
    "request_id": "req-uuid",
    "qr_code_data": "vesspay://pay?r=req-uuid",
    "qr_code_image": "data:image/png;base64,iVBORw0KGgo...",
    "payment_link": "https://pay.vesspay.com/r/req-uuid",
    "amount": 100.00,
    "currency": "GHS",
    "status": "pending",
    "created_at": "2025-02-05T10:15:00Z",
    "expires_at": "2025-02-05T11:15:00Z"
  }

GET /api/v1/payment/request/{request_id}/status
Headers:
  Authorization: Bearer {access_token}
Response 200:
  {
    "request_id": "req-uuid",
    "status": "paid",
    "amount": 100.00,
    "paid_by": "user-uuid",
    "paid_at": "2025-02-05T10:30:00Z",
    "payment_id": "pay-uuid"
  }

GET /api/v1/payment/requests
Headers:
  Authorization: Bearer {access_token}
Query Params:
  status=pending&page=1&limit=20
Response 200:
  {
    "requests": [
      {
        "request_id": "req-uuid",
        "amount": 100.00,
        "currency": "GHS",
        "status": "pending",
        "created_at": "2025-02-05T10:15:00Z",
        "expires_at": "2025-02-05T11:15:00Z"
      }
    ],
    "pagination": { /* ... */ }
  }

───────────────────────────────────────────────────────────────
13. SEND_MONEY_SCREEN.DART
───────────────────────────────────────────────────────────────
Service: TypeScript (NestJS)
Purpose: Quick send to saved recipients

Required Endpoints:

GET /api/v1/recipients
Headers:
  Authorization: Bearer {access_token}
Query Params:
  search=Kwame (optional)
Response 200:
  {
    "recipients": [
      {
        "id": "rec-uuid-1",
        "name": "Kwame Mensah",
        "nickname": "Kwame",
        "phone": "+233241234567",
        "network": "MTN",
        "last_payment_amount": 50.00,
        "last_payment_date": "2025-02-05T09:30:00Z",
        "total_payments": 5,
        "total_amount": 250.00
      }
    ]
  }

POST /api/v1/recipients
Headers:
  Authorization: Bearer {access_token}
Request:
  {
    "name": "Kwame Mensah",
    "nickname": "Kwame",
    "phone": "+233241234567"
  }
Response 201:
  {
    "recipient_id": "rec-uuid",
    "message": "Recipient added successfully"
  }

DELETE /api/v1/recipients/{recipient_id}
Headers:
  Authorization: Bearer {access_token}
Response 200:
  {
    "message": "Recipient deleted successfully"
  }

POST /api/v1/payment/quick-send
Headers:
  Authorization: Bearer {access_token}
Request:
  {
    "recipient_id": "rec-uuid",
    "amount": 50.00,
    "idempotency_key": "client-uuid"
  }
Response 200:
  {
    "payment_id": "pay-uuid",
    "status": "pending"
  }

───────────────────────────────────────────────────────────────
14. TRANSACTION_DETAILS_SCREEN.DART
───────────────────────────────────────────────────────────────
Service: TypeScript (NestJS)
Purpose: View full transaction details

Required Endpoints:

GET /api/v1/transactions/{transaction_id}
Headers:
  Authorization: Bearer {access_token}
Path Params:
  transaction_id: uuid
Response 200:
  {
    "id": "txn-uuid",
    "type": "payment",
    "amount": 50.00,
    "currency": "GHS",
    "status": "completed",
    "recipient_phone": "+233241234567",
    "recipient_name": "Kwame Mensah",
    "recipient_network": "MTN",
    "note": "Payment for lunch",
    "external_transaction_id": "momo-txn-12345",
    "idempotency_key": "client-uuid",
    "wallet_balance_before": 1250.50,
    "wallet_balance_after": 1200.50,
    "fees": 0.00,
    "receipt": {
      "receipt_id": "REC-20250205-002",
      "receipt_url": "https://cdn.vesspay.com/receipts/txn-uuid.pdf"
    },
    "metadata": {
      "ip_address": "192.168.1.1",
      "device_type": "ios",
      "app_version": "1.0.0"
    },
    "created_at": "2025-02-05T10:10:00Z",
    "completed_at": "2025-02-05T10:12:00Z"
  }

POST /api/v1/transactions/{transaction_id}/dispute
Headers:
  Authorization: Bearer {access_token}
Request:
  {
    "reason": "Payment not received by recipient",
    "description": "I sent the payment but recipient says they didn't receive it",
    "evidence": ["attachment_url_1"]
  }
Response 200:
  {
    "dispute_id": "dis-uuid",
    "status": "pending_review",
    "created_at": "2025-02-05T10:20:00Z"
  }

POST /api/v1/transactions/{transaction_id}/receipt/download
Headers:
  Authorization: Bearer {access_token}
Response 200:
  {
    "receipt_url": "https://cdn.vesspay.com/receipts/txn-uuid.pdf",
    "expires_at": "2025-02-05T11:00:00Z"
  }

═══════════════════════════════════════════════════════════════
PROFILE SCREENS (4 screens)
═══════════════════════════════════════════════════════════════

───────────────────────────────────────────────────────────────
15. PROFILE_SCREEN.DART
───────────────────────────────────────────────────────────────
Service: Python (FastAPI)
Purpose: View and edit user profile

Required Endpoints:

GET /api/v1/user/profile
Headers:
  Authorization: Bearer {access_token}
Response 200:
  {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "phone": "+233241234567",
      "date_of_birth": "1990-01-01",
      "nationality": "USA",
      "passport_number": "N12345678",
      "profile_picture_url": "https://cdn.vesspay.com/profile/uuid.jpg",
      "kyc_status": "approved",
      "kyc_tier": 1,
      "email_verified": true,
      "phone_verified": true,
      "created_at": "2025-01-01T00:00:00Z"
    }
  }

PUT /api/v1/user/profile
Headers:
  Authorization: Bearer {access_token}
Request:
  {
    "first_name": "John",
    "last_name": "Doe Updated",
    "phone": "+233241234567"
  }
Response 200:
  {
    "message": "Profile updated successfully",
    "user": { /* updated user object */ }
  }

POST /api/v1/user/profile-picture
Headers:
  Authorization: Bearer {access_token}
  Content-Type: multipart/form-data
Request:
  {
    "image": <file>
  }
Response 200:
  {
    "profile_picture_url": "https://cdn.vesspay.com/profile/uuid.jpg",
    "message": "Profile picture updated"
  }

DELETE /api/v1/user/profile-picture
Headers:
  Authorization: Bearer {access_token}
Response 200:
  {
    "message": "Profile picture removed"
  }

───────────────────────────────────────────────────────────────
16. ACCOUNT_SETTINGS_SCREEN.DART
───────────────────────────────────────────────────────────────
Service: Python (FastAPI)
Purpose: Manage account preferences and settings

Required Endpoints:

GET /api/v1/user/settings
Headers:
  Authorization: Bearer {access_token}
Response 200:
  {
    "settings": {
      "language": "en",
      "currency_display": "GHS",
      "notifications": {
        "push_enabled": true,
        "email_enabled": true,
        "sms_enabled": false,
        "payment_alerts": true,
        "marketing_emails": false
      },
      "privacy": {
        "profile_visibility": "private",
        "transaction_history_visible": false
      },
      "security": {
        "mfa_enabled": true,
        "biometric_enabled": true,
        "trusted_devices_count": 2
      }
    }
  }

PUT /api/v1/user/settings
Headers:
  Authorization: Bearer {access_token}
Request:
  {
    "language": "en",
    "currency_display": "USD",
    "notifications": {
      "push_enabled": true,
      "email_enabled": false
    }
  }
Response 200:
  {
    "message": "Settings updated successfully"
  }

POST /api/v1/user/request-data-export
Headers:
  Authorization: Bearer {access_token}
Response 200:
  {
    "request_id": "export-uuid",
    "status": "processing",
    "estimated_completion": "2025-02-05T11:00:00Z",
    "message": "Data export request received. You'll receive an email when ready."
  }

POST /api/v1/user/delete-account
Headers:
  Authorization: Bearer {access_token}
Request:
  {
    "confirmation": "DELETE",
    "reason": "No longer need the service"
  }
Response 200:
  {
    "message": "Account deletion scheduled",
    "deletion_date": "2025-02-12T00:00:00Z",
    "cancellation_deadline": "2025-02-11T23:59:59Z"
  }

───────────────────────────────────────────────────────────────
17. CHANGE_PASSWORD_SCREEN.DART
───────────────────────────────────────────────────────────────
Service: Python (FastAPI)
Purpose: Change account password

Required Endpoints:

POST /api/v1/user/change-password
Headers:
  Authorization: Bearer {access_token}
Request:
  {
    "current_password": "OldPassword123!",
    "new_password": "NewSecurePassword456!",
    "confirm_password": "NewSecurePassword456!"
  }
Response 200:
  {
    "message": "Password changed successfully",
    "all_sessions_invalidated": true,
    "new_access_token": "jwt-token",
    "new_refresh_token": "refresh-token"
  }
Response 400:
  {
    "error": "INVALID_PASSWORD",
    "message": "Current password is incorrect"
  }
Response 422:
  {
    "error": "WEAK_PASSWORD",
    "message": "Password must be at least 8 characters with uppercase, lowercase, number, and special character"
  }

POST /api/v1/user/reset-password
Request:
  {
    "reset_token": "token-from-email",
    "new_password": "NewSecurePassword456!",
    "confirm_password": "NewSecurePassword456!"
  }
Response 200:
  {
    "message": "Password reset successful",
    "access_token": "jwt-token",
    "refresh_token": "refresh-token"
  }

───────────────────────────────────────────────────────────────
18. SECURITY_SCREEN.DART
───────────────────────────────────────────────────────────────
Service: Python (FastAPI)
Purpose: Manage security settings (MFA, biometrics, devices)

Required Endpoints:

GET /api/v1/user/security
Headers:
  Authorization: Bearer {access_token}
Response 200:
  {
    "mfa": {
      "enabled": true,
      "methods": ["totp", "sms"],
      "backup_codes_count": 8
    },
    "biometric": {
      "enabled": true,
      "registered_at": "2025-01-15T10:00:00Z"
    },
    "devices": [
      {
        "id": "device-uuid-1",
        "name": "iPhone 13 Pro",
        "type": "ios",
        "last_used": "2025-02-05T10:00:00Z",
        "ip_address": "192.168.1.1",
        "location": "Accra, Ghana",
        "current": true
      }
    ],
    "recent_activity": [
      {
        "action": "login",
        "timestamp": "2025-02-05T09:00:00Z",
        "ip_address": "192.168.1.1",
        "device": "iPhone 13 Pro",
        "location": "Accra, Ghana",
        "status": "success"
      }
    ]
  }

POST /api/v1/user/mfa/enable
Headers:
  Authorization: Bearer {access_token}
Request:
  {
    "method": "totp"
  }
Response 200:
  {
    "secret": "JBSWY3DPEHPK3PXP",
    "qr_code": "data:image/png;base64,iVBORw0KGgo...",
    "backup_codes": [
      "12345678",
      "23456789",
      "34567890"
    ]
  }

POST /api/v1/user/mfa/verify-enable
Headers:
  Authorization: Bearer {access_token}
Request:
  {
    "code": "123456"
  }
Response 200:
  {
    "message": "MFA enabled successfully",
    "mfa_enabled": true
  }

DELETE /api/v1/user/mfa/disable
Headers:
  Authorization: Bearer {access_token}
Request:
  {
    "password": "UserPassword123!",
    "code": "123456"
  }
Response 200:
  {
    "message": "MFA disabled successfully"
  }

POST /api/v1/user/biometric/enable
Headers:
  Authorization: Bearer {access_token}
Request:
  {
    "device_id": "device-uuid",
    "biometric_token": "encrypted-token"
  }
Response 200:
  {
    "message": "Biometric authentication enabled",
    "biometric_enabled": true
  }

DELETE /api/v1/user/biometric/disable
Headers:
  Authorization: Bearer {access_token}
Response 200:
  {
    "message": "Biometric authentication disabled"
  }

DELETE /api/v1/user/devices/{device_id}
Headers:
  Authorization: Bearer {access_token}
Response 200:
  {
    "message": "Device removed successfully"
  }

POST /api/v1/user/logout-all-devices
Headers:
  Authorization: Bearer {access_token}
Response 200:
  {
    "message": "Logged out from all devices",
    "devices_logged_out": 3
  }

═══════════════════════════════════════════════════════════════
WALLET SCREENS (3 screens)
═══════════════════════════════════════════════════════════════

───────────────────────────────────────────────────────────────
19. WALLET_SCREEN.DART
───────────────────────────────────────────────────────────────
Service: TypeScript (NestJS)
Purpose: Main wallet overview

Required Endpoints:

GET /api/v1/wallet
Headers:
  Authorization: Bearer {access_token}
Response 200:
  {
    "wallet": {
      "id": "wallet-uuid",
      "user_id": "user-uuid",
      "balance": 1250.50,
      "currency": "GHS",
      "pending_amount": 50.00,
      "available_balance": 1200.50,
      "status": "active",
      "created_at": "2025-01-01T00:00:00Z",
      "last_updated": "2025-02-05T10:00:00Z"
    },
    "limits": {
      "kyc_tier": 1,
      "max_transaction": 500.00,
      "daily_limit": 2000.00,
      "monthly_limit": 10000.00,
      "daily_used": 150.00,
      "monthly_used": 1200.00
    }
  }

GET /api/v1/wallet/summary
Headers:
  Authorization: Bearer {access_token}
Query Params:
  period=7d
Response 200:
  {
    "period": "7d",
    "opening_balance": 1000.00,
    "closing_balance": 1250.50,
    "total_deposits": 500.00,
    "total_payments": 250.00,
    "total_fees": 5.00,
    "net_change": 245.00,
    "transaction_count": 15
  }

POST /api/v1/wallet/freeze
Headers:
  Authorization: Bearer {access_token}
Request:
  {
    "reason": "Lost phone, securing account"
  }
Response 200:
  {
    "message": "Wallet frozen successfully",
    "status": "frozen",
    "unfrozen_at": null
  }

POST /api/v1/wallet/unfreeze
Headers:
  Authorization: Bearer {access_token}
Request:
  {
    "verification_code": "123456"
  }
Response 200:
  {
    "message": "Wallet unfrozen successfully",
    "status": "active"
  }

───────────────────────────────────────────────────────────────
20. TRANSACTIONS_SCREEN.DART
───────────────────────────────────────────────────────────────
Service: TypeScript (NestJS)
Purpose: List all wallet transactions

Required Endpoints:

GET /api/v1/transactions
Headers:
  Authorization: Bearer {access_token}
Query Params:
  page=1
  limit=20
  type=payment (optional: payment, deposit, refund, fee)
  status=completed (optional: pending, processing, completed, failed)
  start_date=2025-02-01 (optional)
  end_date=2025-02-05 (optional)
  sort=created_at (optional: created_at, amount)
  order=desc (optional: asc, desc)
Response 200:
  {
    "transactions": [
      {
        "id": "txn-uuid-1",
        "type": "payment",
        "amount": -50.00,
        "currency": "GHS",
        "status": "completed",
        "recipient_phone": "+233241234567",
        "recipient_name": "Kwame Mensah",
        "description": "MoMo payment",
        "created_at": "2025-02-05T09:30:00Z"
      },
      {
        "id": "txn-uuid-2",
        "type": "deposit",
        "amount": 200.00,
        "currency": "GHS",
        "status": "completed",
        "payment_method": "card",
        "card_last4": "4242",
        "description": "Card deposit",
        "created_at": "2025-02-04T15:20:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 125,
      "total_pages": 7,
      "has_more": true
    },
    "filters_applied": {
      "type": null,
      "status": null,
      "start_date": null,
      "end_date": null
    }
  }

GET /api/v1/transactions/statistics
Headers:
  Authorization: Bearer {access_token}
Query Params:
  period=30d
Response 200:
  {
    "period": "30d",
    "total_transactions": 50,
    "total_deposits": 1500.00,
    "total_payments": 750.00,
    "total_fees": 15.00,
    "average_transaction": 45.00,
    "largest_transaction": 500.00,
    "by_type": {
      "deposit": { "count": 10, "amount": 1500.00 },
      "payment": { "count": 38, "amount": 750.00 },
      "refund": { "count": 2, "amount": 100.00 }
    },
    "by_status": {
      "completed": { "count": 45, "amount": 2200.00 },
      "failed": { "count": 3, "amount": 150.00 },
      "pending": { "count": 2, "amount": 100.00 }
    }
  }

POST /api/v1/transactions/export
Headers:
  Authorization: Bearer {access_token}
Request:
  {
    "format": "pdf",
    "start_date": "2025-01-01",
    "end_date": "2025-02-05",
    "include_types": ["payment", "deposit"]
  }
Response 200:
  {
    "export_id": "export-uuid",
    "status": "processing",
    "estimated_completion": "2025-02-05T10:30:00Z"
  }

GET /api/v1/transactions/export/{export_id}
Headers:
  Authorization: Bearer {access_token}
Response 200:
  {
    "export_id": "export-uuid",
    "status": "completed",
    "download_url": "https://cdn.vesspay.com/exports/export-uuid.pdf",
    "expires_at": "2025-02-06T10:30:00Z"
  }

───────────────────────────────────────────────────────────────
21. TRANSACTION_HISTORY_SCREEN.DART
───────────────────────────────────────────────────────────────
Service: TypeScript (NestJS)
Purpose: Detailed transaction history with advanced filtering

Required Endpoints:

(Same as TRANSACTIONS_SCREEN.DART but with additional filters)

GET /api/v1/transactions/search
Headers:
  Authorization: Bearer {access_token}
Query Params:
  q=Kwame (search by recipient name or phone)
  min_amount=10.00
  max_amount=500.00
  page=1
  limit=20
Response 200:
  {
    "transactions": [ /* ... */ ],
    "search_query": "Kwame",
    "matches_found": 5
  }

GET /api/v1/transactions/categories
Headers:
  Authorization: Bearer {access_token}
Response 200:
  {
    "categories": [
      {
        "name": "Groceries",
        "transaction_count": 10,
        "total_amount": 250.00,
        "color": "#4CAF50"
      },
      {
        "name": "Transport",
        "transaction_count": 5,
        "total_amount": 100.00,
        "color": "#2196F3"
      }
    ]
  }

PUT /api/v1/transactions/{transaction_id}/category
Headers:
  Authorization: Bearer {access_token}
Request:
  {
    "category": "Groceries"
  }
Response 200:
  {
    "message": "Category updated successfully"
  }

═══════════════════════════════════════════════════════════════
WEBHOOK ENDPOINTS (Backend → Mobile Push)
═══════════════════════════════════════════════════════════════

These webhooks trigger push notifications to mobile app via FCM:

POST /webhooks/payment/status-update
Trigger: Payment status changes (pending → completed/failed)
Payload:
  {
    "event": "payment.status.updated",
    "payment_id": "pay-uuid",
    "user_id": "user-uuid",
    "status": "completed",
    "amount": 50.00,
    "recipient_phone": "+233241234567",
    "timestamp": "2025-02-05T10:12:00Z"
  }

POST /webhooks/funding/completed
Trigger: Wallet funded successfully
Payload:
  {
    "event": "funding.completed",
    "funding_id": "fund-uuid",
    "user_id": "user-uuid",
    "amount": 1250.00,
    "currency": "GHS",
    "new_balance": 2450.50,
    "timestamp": "2025-02-05T10:05:00Z"
  }

POST /webhooks/kyc/status-update
Trigger: KYC status changes
Payload:
  {
    "event": "kyc.status.updated",
    "user_id": "user-uuid",
    "kyc_status": "approved",
    "kyc_tier": 1,
    "timestamp": "2025-02-05T09:00:00Z"
  }

POST /webhooks/security/login-alert
Trigger: New device login
Payload:
  {
    "event": "security.login.new_device",
    "user_id": "user-uuid",
    "device_name": "MacBook Pro",
    "location": "Accra, Ghana",
    "ip_address": "192.168.1.1",
    "timestamp": "2025-02-05T10:00:00Z"
  }

═══════════════════════════════════════════════════════════════
RATE LIMITING SPECIFICATIONS
═══════════════════════════════════════════════════════════════

Per Endpoint Rate Limits:

PUBLIC ENDPOINTS:
- GET /api/v1/public/*: 1000 req/hour per IP
- GET /api/v1/config/*: 100 req/hour per IP

AUTHENTICATION:
- POST /api/v1/auth/login: 5 req/15min per IP
- POST /api/v1/auth/register: 3 req/hour per IP
- POST /api/v1/auth/refresh: 10 req/hour per user
- POST /api/v1/auth/forgot-password: 3 req/hour per email

PAYMENTS:
- POST /api/v1/payment/initiate: 10 req/hour per user
- POST /api/v1/payment/validate-recipient: 20 req/hour per user
- GET /api/v1/payment/*: 100 req/hour per user

WALLET:
- GET /api/v1/wallet/*: 100 req/hour per user
- POST /api/v1/funding/initiate: 5 req/hour per user

GENERAL:
- All other authenticated endpoints: 100 req/hour per user

Rate Limit Response (429):
{
  "error": "RATE_LIMIT_EXCEEDED",
  "message": "Too many requests. Please try again later.",
  "retry_after": 3600,
  "limit": 10,
  "remaining": 0,
  "reset_at": "2025-02-05T11:00:00Z"
}

═══════════════════════════════════════════════════════════════
ERROR CODES REFERENCE
═══════════════════════════════════════════════════════════════

Authentication & Authorization:
- VES-1001: Invalid credentials
- VES-1002: Account locked
- VES-1003: Email not verified
- VES-1004: Token expired
- VES-1005: Invalid MFA code
- VES-1006: Insufficient permissions

KYC & Compliance:
- VES-2001: KYC not approved
- VES-2002: KYC tier limit exceeded
- VES-2003: Sanctioned country
- VES-2004: Under 18 years old
- VES-2005: Document verification failed

Wallet & Payments:
- VES-3001: Insufficient balance
- VES-3002: Invalid recipient
- VES-3003: Duplicate transaction
- VES-3004: Payment amount exceeds limit
- VES-3005: Wallet frozen
- VES-3006: Payment expired

External Providers:
- VES-5001: MoMo provider error
- VES-5002: Card payment failed
- VES-5003: Provider timeout
- VES-5004: Invalid FX rate

System:
- VES-4001: Rate limit exceeded
- VES-6001: Invalid request format
- VES-6002: Internal server error
- VES-6003: Service unavailable

═══════════════════════════════════════════════════════════════
PERFORMANCE REQUIREMENTS
═══════════════════════════════════════════════════════════════

API Response Times (p95):
- GET /api/v1/wallet/balance: < 100ms
- POST /api/v1/payment/initiate: < 200ms
- POST /api/v1/auth/login: < 300ms
- POST /api/v1/kyc/submit: < 500ms
- GET /api/v1/transactions: < 150ms

Database Queries:
- All queries: < 50ms (p95)
- Ledger integrity check: < 100ms

Webhook Processing:
- Acknowledge: < 50ms
- Complete processing: < 5s (async)

═══════════════════════════════════════════════════════════════
IMPLEMENTATION CHECKLIST
═══════════════════════════════════════════════════════════════

TypeScript (NestJS) Backend:
[ ] All wallet endpoints implemented
[ ] All payment endpoints implemented
[ ] All transaction endpoints implemented
[ ] All funding endpoints implemented
[ ] Double-entry ledger working
[ ] Idempotency implemented
[ ] Rate limiting configured
[ ] Webhook handling secure
[ ] Unit tests >90% coverage
[ ] Integration tests passing
[ ] API documentation (Swagger)
[ ] Production-ready error handling

Python (FastAPI) Backend:
[ ] All auth endpoints implemented
[ ] All user endpoints implemented
[ ] All KYC endpoints implemented
[ ] All security endpoints implemented
[ ] JWT authentication working
[ ] MFA implementation complete
[ ] Risk scoring algorithm implemented
[ ] Rate limiting configured
[ ] Unit tests >85% coverage
[ ] Integration tests passing
[ ] API documentation (Swagger)
[ ] Production-ready error handling

Cross-Service:
[ ] Inter-service communication secure
[ ] Message queue operational
[ ] No shared database
[ ] Correlation IDs implemented
[ ] Distributed tracing setup
[ ] Monitoring dashboards configured
[ ] Alert rules defined
[ ] Load testing completed
[ ] Security audit passed

Mobile Integration:
[ ] All 20 screens have working endpoints
[ ] Push notifications configured
[ ] Offline queue sync working
[ ] Error handling graceful
[ ] Loading states implemented
[ ] Network detection working

═══════════════════════════════════════════════════════════════
END OF SPECIFICATION
═══════════════════════════════════════════════════════════════

This specification provides EXACT API contracts for all 20 Flutter screens.
Every endpoint must be implemented exactly as specified for seamless mobile integration.
