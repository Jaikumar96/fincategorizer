# FinCategorizer API Documentation

## Base URLs

- **Development**: `http://localhost:8080`
- **Production**: `https://api.fincategorizer.com`

All endpoints (except `/auth/**`) require JWT authentication via the `Authorization: Bearer <token>` header.

---

## Authentication

### POST /auth/register
Register a new user with email/password.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "fullName": "John Doe"
}
```

**Response (201):**
```json
{
  "userId": 123,
  "email": "user@example.com",
  "fullName": "John Doe",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4...",
  "expiresIn": 3600
}
```

### POST /auth/login
Login with email/password.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Response (200):**
```json
{
  "userId": 123,
  "email": "user@example.com",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4...",
  "expiresIn": 3600
}
```

### POST /auth/google
OAuth 2.0 login with Google.

**Request:**
```json
{
  "code": "4/0AX4XfWh..." // Authorization code from Google
}
```

**Response (200):**
```json
{
  "userId": 124,
  "email": "user@gmail.com",
  "fullName": "Jane Doe",
  "profilePictureUrl": "https://lh3.googleusercontent.com/...",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4...",
  "expiresIn": 3600
}
```

### POST /auth/refresh
Refresh access token using refresh token.

**Request:**
```json
{
  "refreshToken": "dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4..."
}
```

**Response (200):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": 3600
}
```

---

## Transactions

### POST /api/transactions
Create a single transaction.

**Request:**
```json
{
  "merchantName": "Swiggy Order #123456",
  "amount": 450.50,
  "currency": "INR",
  "transactionDate": "2025-11-17T12:30:00Z"
}
```

**Response (201):**
```json
{
  "transactionId": 12345,
  "userId": 123,
  "merchantName": "Swiggy Order #123456",
  "merchantNormalized": "swiggy order",
  "amount": 450.50,
  "currency": "INR",
  "transactionDate": "2025-11-17T12:30:00Z",
  "category": {
    "categoryId": 1,
    "categoryName": "Food & Dining",
    "icon": "🍔",
    "color": "#FF6B6B"
  },
  "confidenceScore": 0.920,
  "isUserCorrected": false,
  "alternatives": [
    {
      "categoryId": 2,
      "categoryName": "Groceries",
      "score": 0.045
    },
    {
      "categoryId": 15,
      "categoryName": "Others",
      "score": 0.025
    }
  ],
  "createdAt": "2025-11-17T12:30:05Z"
}
```

### POST /api/transactions/batch
Upload multiple transactions via CSV file.

**Request:** (multipart/form-data)
```
file: transactions.csv
```

**CSV Format:**
```csv
date,merchant,amount,currency
2025-11-17,Swiggy Order,450.50,INR
2025-11-16,Uber Trip,180.00,INR
2025-11-15,Amazon.in,1299.00,INR
```

**Response (202):**
```json
{
  "jobId": "batch_abc123",
  "status": "processing",
  "totalRows": 250,
  "validRows": 248,
  "invalidRows": 2,
  "errors": [
    {
      "row": 15,
      "field": "date",
      "error": "Invalid date format. Expected YYYY-MM-DD"
    },
    {
      "row": 87,
      "field": "amount",
      "error": "Amount must be a positive number"
    }
  ],
  "estimatedCompletionTime": "2025-11-17T12:35:00Z"
}
```

### GET /api/transactions/batch/{jobId}
Check batch upload status.

**Response (200):**
```json
{
  "jobId": "batch_abc123",
  "status": "completed",
  "totalRows": 250,
  "processed": 250,
  "successful": 248,
  "failed": 2,
  "startedAt": "2025-11-17T12:30:00Z",
  "completedAt": "2025-11-17T12:34:15Z",
  "results": {
    "avgConfidence": 0.897,
    "categoryDistribution": {
      "Food & Dining": 45,
      "Transportation": 30,
      "Shopping": 28,
      "Groceries": 25
    }
  }
}
```

### GET /api/transactions
List transactions with filtering and pagination.

**Query Parameters:**
- `page` (int, default: 0)
- `size` (int, default: 20, max: 100)
- `sort` (string, default: "transactionDate,desc")
- `startDate` (ISO date, optional)
- `endDate` (ISO date, optional)
- `categoryId` (int, optional)
- `minConfidence` (float, optional)
- `maxConfidence` (float, optional)
- `isUserCorrected` (boolean, optional)
- `search` (string, optional) - Search in merchant name

**Example:**
```
GET /api/transactions?page=0&size=20&categoryId=1&minConfidence=0.80&sort=transactionDate,desc
```

**Response (200):**
```json
{
  "content": [
    {
      "transactionId": 12345,
      "merchantName": "Swiggy Order #123456",
      "merchantNormalized": "swiggy order",
      "amount": 450.50,
      "currency": "INR",
      "transactionDate": "2025-11-17T12:30:00Z",
      "category": {
        "categoryId": 1,
        "categoryName": "Food & Dining",
        "icon": "🍔",
        "color": "#FF6B6B"
      },
      "confidenceScore": 0.920,
      "isUserCorrected": false
    }
  ],
  "pageable": {
    "pageNumber": 0,
    "pageSize": 20,
    "sort": {
      "sorted": true,
      "unsorted": false,
      "empty": false
    }
  },
  "totalElements": 150,
  "totalPages": 8,
  "last": false,
  "first": true,
  "numberOfElements": 20
}
```

### GET /api/transactions/{id}
Get single transaction by ID.

**Response (200):**
```json
{
  "transactionId": 12345,
  "userId": 123,
  "merchantName": "Swiggy Order #123456",
  "merchantNormalized": "swiggy order",
  "amount": 450.50,
  "currency": "INR",
  "transactionDate": "2025-11-17T12:30:00Z",
  "category": {
    "categoryId": 1,
    "categoryName": "Food & Dining",
    "icon": "🍔",
    "color": "#FF6B6B"
  },
  "confidenceScore": 0.920,
  "isUserCorrected": false,
  "metadata": {
    "location": "Bangalore, India",
    "notes": "Dinner order"
  },
  "createdAt": "2025-11-17T12:30:05Z",
  "updatedAt": "2025-11-17T12:30:05Z"
}
```

### PUT /api/transactions/{id}/category
Update transaction category (user correction).

**Request:**
```json
{
  "categoryId": 2,
  "notes": "This was groceries, not food delivery"
}
```

**Response (200):**
```json
{
  "transactionId": 12345,
  "category": {
    "categoryId": 2,
    "categoryName": "Groceries"
  },
  "isUserCorrected": true,
  "previousCategory": {
    "categoryId": 1,
    "categoryName": "Food & Dining"
  },
  "updatedAt": "2025-11-17T13:45:00Z",
  "message": "Category updated successfully. This correction will improve future predictions."
}
```

### DELETE /api/transactions/{id}
Delete a transaction.

**Response (204):** No content

---

## Categories

### GET /api/categories
Get all categories (default + user's custom categories).

**Response (200):**
```json
{
  "categories": [
    {
      "categoryId": 1,
      "categoryName": "Food & Dining",
      "categoryType": "default",
      "icon": "🍔",
      "color": "#FF6B6B",
      "description": "Restaurants, food delivery, dining out",
      "transactionCount": 45,
      "totalSpent": 12500.50
    },
    {
      "categoryId": 16,
      "categoryName": "Pet Care",
      "categoryType": "custom",
      "icon": "🐕",
      "color": "#95E1D3",
      "parentCategoryId": 15,
      "transactionCount": 8,
      "totalSpent": 3200.00
    }
  ]
}
```

### POST /api/categories
Create a custom category.

**Request:**
```json
{
  "categoryName": "Pet Care",
  "icon": "🐕",
  "color": "#95E1D3",
  "parentCategoryId": 15,
  "description": "Pet food, veterinary, grooming"
}
```

**Response (201):**
```json
{
  "categoryId": 16,
  "userId": 123,
  "categoryName": "Pet Care",
  "categoryType": "custom",
  "icon": "🐕",
  "color": "#95E1D3",
  "parentCategoryId": 15,
  "createdAt": "2025-11-17T14:00:00Z"
}
```

### PUT /api/categories/{id}
Update a custom category (cannot update default categories).

**Request:**
```json
{
  "categoryName": "Pet Expenses",
  "icon": "🐾",
  "color": "#A8E6CF"
}
```

**Response (200):**
```json
{
  "categoryId": 16,
  "categoryName": "Pet Expenses",
  "icon": "🐾",
  "color": "#A8E6CF",
  "updatedAt": "2025-11-17T14:30:00Z"
}
```

### DELETE /api/categories/{id}
Soft delete a custom category.

**Response (204):** No content

### GET /api/categories/merchants/{merchantName}
Get category suggestion for a merchant.

**Example:**
```
GET /api/categories/merchants/Swiggy
```

**Response (200):**
```json
{
  "merchantName": "Swiggy",
  "suggestions": [
    {
      "categoryId": 1,
      "categoryName": "Food & Dining",
      "confidence": 0.980,
      "source": "pattern_match",
      "usageCount": 150
    },
    {
      "categoryId": 2,
      "categoryName": "Groceries",
      "confidence": 0.750,
      "source": "ml_prediction",
      "usageCount": 20
    }
  ]
}
```

---

## Analytics

### GET /api/analytics/accuracy
Get model accuracy metrics.

**Query Parameters:**
- `days` (int, default: 30) - Number of days to analyze

**Example:**
```
GET /api/analytics/accuracy?days=30
```

**Response (200):**
```json
{
  "period": {
    "startDate": "2025-10-18",
    "endDate": "2025-11-17",
    "days": 30
  },
  "overallAccuracy": 0.947,
  "totalTransactions": 1250,
  "correctPredictions": 1184,
  "userCorrections": 66,
  "avgConfidenceScore": 0.873,
  "accuracyByCategory": {
    "Food & Dining": 0.965,
    "Transportation": 0.982,
    "Shopping": 0.890,
    "Groceries": 0.970
  },
  "accuracyTrend": [
    {"date": "2025-10-18", "accuracy": 0.91, "transactions": 42},
    {"date": "2025-10-25", "accuracy": 0.93, "transactions": 38},
    {"date": "2025-11-01", "accuracy": 0.95, "transactions": 45},
    {"date": "2025-11-08", "accuracy": 0.96, "transactions": 50},
    {"date": "2025-11-15", "accuracy": 0.95, "transactions": 41}
  ]
}
```

### GET /api/analytics/category-distribution
Get spending distribution by category.

**Query Parameters:**
- `startDate` (ISO date, optional)
- `endDate` (ISO date, optional)

**Response (200):**
```json
{
  "period": {
    "startDate": "2025-10-18",
    "endDate": "2025-11-17"
  },
  "totalSpent": 45230.50,
  "distribution": [
    {
      "categoryId": 1,
      "categoryName": "Food & Dining",
      "icon": "🍔",
      "color": "#FF6B6B",
      "amount": 12500.50,
      "percentage": 27.6,
      "transactionCount": 45
    },
    {
      "categoryId": 3,
      "categoryName": "Transportation",
      "amount": 8200.00,
      "percentage": 18.1,
      "transactionCount": 60
    },
    {
      "categoryId": 4,
      "categoryName": "Shopping",
      "amount": 9850.00,
      "percentage": 21.8,
      "transactionCount": 28
    }
  ]
}
```

### GET /api/analytics/trends
Get spending trends over time.

**Query Parameters:**
- `groupBy` (string: "day", "week", "month") - Default: "week"
- `startDate` (ISO date, optional)
- `endDate` (ISO date, optional)

**Response (200):**
```json
{
  "groupBy": "week",
  "trends": [
    {
      "period": "2025-W42",
      "startDate": "2025-10-14",
      "endDate": "2025-10-20",
      "totalSpent": 8450.00,
      "transactionCount": 42,
      "avgTransactionAmount": 201.19,
      "byCategory": {
        "Food & Dining": 2100.00,
        "Transportation": 1500.00,
        "Shopping": 2850.00
      }
    },
    {
      "period": "2025-W43",
      "startDate": "2025-10-21",
      "endDate": "2025-10-27",
      "totalSpent": 9230.50,
      "transactionCount": 38,
      "avgTransactionAmount": 242.91
    }
  ]
}
```

### GET /api/analytics/confidence-scores
Get confidence score distribution.

**Response (200):**
```json
{
  "histogram": [
    {
      "range": "0.00-0.20",
      "count": 5,
      "percentage": 0.4
    },
    {
      "range": "0.20-0.40",
      "count": 8,
      "percentage": 0.6
    },
    {
      "range": "0.40-0.60",
      "count": 15,
      "percentage": 1.2
    },
    {
      "range": "0.60-0.80",
      "count": 85,
      "percentage": 6.8
    },
    {
      "range": "0.80-0.90",
      "count": 220,
      "percentage": 17.6
    },
    {
      "range": "0.90-1.00",
      "count": 917,
      "percentage": 73.4
    }
  ],
  "avgConfidence": 0.897,
  "medianConfidence": 0.920,
  "lowConfidenceCount": 28,
  "lowConfidenceThreshold": 0.85
}
```

### GET /api/analytics/top-merchants
Get top merchants by spending.

**Query Parameters:**
- `limit` (int, default: 10, max: 50)
- `startDate` (ISO date, optional)
- `endDate` (ISO date, optional)

**Response (200):**
```json
{
  "topMerchants": [
    {
      "merchantName": "Amazon.in",
      "merchantNormalized": "amazon in",
      "transactionCount": 28,
      "totalSpent": 15650.00,
      "avgAmount": 559.00,
      "category": {
        "categoryId": 4,
        "categoryName": "Shopping"
      }
    },
    {
      "merchantName": "Swiggy",
      "transactionCount": 42,
      "totalSpent": 12300.50,
      "avgAmount": 292.87,
      "category": {
        "categoryId": 1,
        "categoryName": "Food & Dining"
      }
    }
  ]
}
```

---

## ML Inference (Internal API)

### POST /ml/categorize
Categorize a single transaction.

**Request:**
```json
{
  "merchantNormalized": "swiggy order",
  "amount": 450.50,
  "currency": "INR",
  "userId": 123,
  "lastTransactions": [
    {"categoryId": 1, "categoryName": "Food & Dining"},
    {"categoryId": 3, "categoryName": "Transportation"},
    {"categoryId": 1, "categoryName": "Food & Dining"}
  ]
}
```

**Response (200):**
```json
{
  "categoryId": 1,
  "categoryName": "Food & Dining",
  "confidenceScore": 0.920,
  "alternatives": [
    {
      "categoryId": 2,
      "categoryName": "Groceries",
      "score": 0.045
    },
    {
      "categoryId": 15,
      "categoryName": "Others",
      "score": 0.025
    }
  ],
  "inferenceTime": 142,
  "model": "distilbert-financial-v1",
  "sources": {
    "fingpt": 0.85,
    "pattern": 0.95
  }
}
```

### POST /ml/categorize/batch
Categorize multiple transactions.

**Request:**
```json
{
  "transactions": [
    {
      "merchantNormalized": "swiggy order",
      "amount": 450.50,
      "currency": "INR"
    },
    {
      "merchantNormalized": "uber trip",
      "amount": 180.00,
      "currency": "INR"
    }
  ]
}
```

**Response (200):**
```json
{
  "results": [
    {
      "index": 0,
      "categoryId": 1,
      "categoryName": "Food & Dining",
      "confidenceScore": 0.920
    },
    {
      "index": 1,
      "categoryId": 3,
      "categoryName": "Transportation",
      "confidenceScore": 0.970
    }
  ],
  "totalInferenceTime": 285,
  "avgInferenceTime": 142.5
}
```

---

## Error Responses

### 400 Bad Request
```json
{
  "error": "Bad Request",
  "message": "Invalid request parameters",
  "details": [
    {
      "field": "amount",
      "message": "Amount must be greater than 0"
    }
  ],
  "timestamp": "2025-11-17T12:30:00Z",
  "path": "/api/transactions"
}
```

### 401 Unauthorized
```json
{
  "error": "Unauthorized",
  "message": "Invalid or expired JWT token",
  "timestamp": "2025-11-17T12:30:00Z"
}
```

### 403 Forbidden
```json
{
  "error": "Forbidden",
  "message": "You don't have permission to access this resource",
  "timestamp": "2025-11-17T12:30:00Z"
}
```

### 404 Not Found
```json
{
  "error": "Not Found",
  "message": "Transaction not found",
  "timestamp": "2025-11-17T12:30:00Z"
}
```

### 429 Too Many Requests
```json
{
  "error": "Rate Limit Exceeded",
  "message": "You have exceeded the rate limit of 1000 requests per minute",
  "retryAfter": 45,
  "timestamp": "2025-11-17T12:30:00Z"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal Server Error",
  "message": "An unexpected error occurred",
  "requestId": "abc123-def456",
  "timestamp": "2025-11-17T12:30:00Z"
}
```

---

## Rate Limiting

- **Limit**: 1000 requests per minute per user
- **Headers**:
  - `X-RateLimit-Limit`: 1000
  - `X-RateLimit-Remaining`: 850
  - `X-RateLimit-Reset`: 1700234400 (Unix timestamp)

---

## Webhooks (Optional Feature)

### POST /api/webhooks
Register a webhook endpoint.

**Request:**
```json
{
  "url": "https://your-app.com/webhooks/fincategorizer",
  "events": ["transaction.created", "transaction.updated", "batch.completed"],
  "secret": "your_webhook_secret"
}
```

**Response (201):**
```json
{
  "webhookId": "wh_abc123",
  "url": "https://your-app.com/webhooks/fincategorizer",
  "events": ["transaction.created", "transaction.updated", "batch.completed"],
  "isActive": true,
  "createdAt": "2025-11-17T14:00:00Z"
}
```

**Webhook Payload Example:**
```json
{
  "event": "transaction.created",
  "timestamp": "2025-11-17T12:30:05Z",
  "data": {
    "transactionId": 12345,
    "merchantName": "Swiggy Order",
    "amount": 450.50,
    "category": {
      "categoryId": 1,
      "categoryName": "Food & Dining"
    },
    "confidenceScore": 0.920
  },
  "signature": "sha256=..."
}
```

---

**End of API Documentation**
