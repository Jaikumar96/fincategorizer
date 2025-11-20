# FinCategorizer - System Architecture

## Table of Contents
1. [System Overview](#system-overview)
2. [Microservices Architecture](#microservices-architecture)
3. [Data Flow](#data-flow)
4. [Database Design](#database-design)
5. [ML Pipeline](#ml-pipeline)
6. [Security Architecture](#security-architecture)
7. [Scalability & Performance](#scalability--performance)
8. [Deployment Architecture](#deployment-architecture)

## System Overview

FinCategorizer is built as a **microservices architecture** with the following design principles:

- **Separation of Concerns**: Each service handles a specific domain
- **Loose Coupling**: Services communicate via REST APIs
- **Fault Tolerance**: Circuit breakers and fallback mechanisms
- **Horizontal Scalability**: Stateless services for easy scaling
- **Data Consistency**: ACID transactions within services, eventual consistency across services

### Technology Choices Rationale

| Technology | Choice | Rationale |
|------------|--------|-----------|
| **Gateway** | Spring Cloud Gateway | Industry-standard, built-in filters, WebFlux support |
| **Backend** | Spring Boot | Robust ecosystem, production-ready, excellent tooling |
| **ML Service** | FastAPI | Async support, fast inference, Python ML ecosystem |
| **Database** | MySQL | ACID compliance, complex queries, mature tooling |
| **Cache** | Redis | In-memory performance, pub/sub, TTL support |
| **Frontend** | React + TypeScript | Component reusability, type safety, large community |

## Microservices Architecture

### Service Inventory

```
┌─────────────────────────────────────────────────────────────────┐
│                    CLIENT (Browser/Mobile)                       │
└───────────────────────────┬─────────────────────────────────────┘
                            │ HTTPS
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      NGINX Reverse Proxy                         │
│  - TLS Termination                                               │
│  - Static File Serving (React build)                             │
│  - Request Routing                                               │
└───────────────────────────┬─────────────────────────────────────┘
                            │ HTTP
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                   API GATEWAY SERVICE (8080)                     │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ Spring Cloud Gateway                                     │    │
│  │ ┌─────────────┐ ┌──────────────┐ ┌─────────────────┐   │    │
│  │ │ JWT Filter  │ │ Rate Limiter │ │ CORS Handler    │   │    │
│  │ └─────────────┘ └──────────────┘ └─────────────────┘   │    │
│  │ ┌─────────────────────────────────────────────────────┐ │    │
│  │ │            Route Predicates                         │ │    │
│  │ │ /api/transactions/* → transaction-service:8081     │ │    │
│  │ │ /api/ml/*           → ml-inference-service:8000    │ │    │
│  │ │ /api/categories/*   → category-service:8082        │ │    │
│  │ │ /api/analytics/*    → analytics-service:8083       │ │    │
│  │ └─────────────────────────────────────────────────────┘ │    │
│  └─────────────────────────────────────────────────────────┘    │
└───────────────────────────┬─────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ Transaction  │    │  Category    │    │  Analytics   │
│   Service    │◄──►│   Service    │◄──►│   Service    │
│   (8081)     │    │   (8082)     │    │   (8083)     │
└──────┬───────┘    └──────┬───────┘    └──────┬───────┘
       │                   │                   │
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │ ML Inference    │
                  │   Service       │
                  │   (8000)        │
                  └─────────┬───────┘
                            │
        ┌───────────────────┴───────────────────┐
        ▼                                       ▼
┌────────────────┐                      ┌────────────────┐
│ MySQL Database │                      │ Redis Cache    │
│  - Users       │                      │ - JWT Tokens   │
│  - Transactions│                      │ - Merchant Map │
│  - Categories  │                      │ - Session Data │
│  - Analytics   │                      │                │
└────────────────┘                      └────────────────┘
```

### Service Responsibilities

#### 1. Gateway Service (Port 8080)
**Responsibilities**:
- Authentication & Authorization (JWT validation)
- Request routing to backend services
- Rate limiting (1000 req/min per user)
- CORS handling
- Request/response logging

**Key Components**:
```java
@Configuration
public class GatewayConfig {
    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
            .route("transactions", r -> r.path("/api/transactions/**")
                .filters(f -> f.filter(jwtAuthFilter).requestRateLimiter())
                .uri("http://transaction-service:8081"))
            // ... other routes
            .build();
    }
}
```

**Dependencies**: None (entry point)

---

#### 2. Transaction Service (Port 8081)
**Responsibilities**:
- Transaction CRUD operations
- CSV batch upload processing
- Transaction pre-processing (normalization)
- Orchestrate ML categorization
- User correction handling
- Recurring transaction detection

**Key Components**:
- `TransactionController`: REST endpoints
- `TransactionService`: Business logic
- `TransactionRepository`: JPA data access
- `CsvParser`: CSV file parsing
- `MLClient`: HTTP client for ML service
- `RedisCache`: Merchant→Category caching

**Database Tables**:
- `transactions`
- `model_training_data` (for corrections)

**External Dependencies**:
- ML Inference Service (HTTP)
- Category Service (HTTP)
- MySQL (JDBC)
- Redis (Jedis/Lettuce)

**Data Flow Example** (Single Transaction):
```
1. POST /api/transactions
2. Validate input (amount, date, merchant)
3. Normalize merchant name (lowercase, trim)
4. Check Redis cache for merchant→category mapping
5. If cache miss:
   a. Call ML service: POST /ml/categorize
   b. ML service returns {category_id, confidence}
   c. Store in Redis (TTL: 7 days)
6. Save transaction to MySQL
7. Return response to client
```

---

#### 3. ML Inference Service (Port 8000)
**Responsibilities**:
- Single & batch transaction categorization
- DistilBERT inference (placeholder for FinGPT)
- Pattern-based classification
- Weighted ensemble prediction
- Context-aware predictions (last 5 transactions)

**Key Components**:
- `main.py`: FastAPI app
- `categorizer.py`: ML model wrapper
- `patterns.py`: Regex & heuristic rules
- `ensemble.py`: Weighted voting logic

**ML Pipeline**:
```python
# Hybrid Classification
def categorize(transaction):
    # 1. DistilBERT (70% weight)
    fingpt_input = f"{merchant_normalized} {amount} {context}"
    fingpt_probs = model.predict(fingpt_input)  # Shape: [15]
    
    # 2. Pattern-based (30% weight)
    pattern_probs = pattern_matcher.match(merchant_normalized, amount)
    
    # 3. Ensemble
    final_probs = 0.7 * fingpt_probs + 0.3 * pattern_probs
    category_id = argmax(final_probs)
    confidence = final_probs[category_id]
    
    return {
        "category_id": category_id,
        "confidence": confidence,
        "alternatives": top_3_alternatives(final_probs)
    }
```

**Performance Optimizations**:
- Model loaded once at startup (singleton)
- Batch inference with asyncio parallelization
- TensorFlow Lite for faster inference (optional)
- Caching of pattern matching results

---

#### 4. Category Service (Port 8082)
**Responsibilities**:
- Manage default & custom categories
- Merchant pattern CRUD
- Merchant→Category suggestion
- Self-learning cron job (update patterns from corrections)

**Key Components**:
- `CategoryController`: REST endpoints
- `CategoryService`: Business logic
- `MerchantPatternService`: Pattern matching & learning
- `SelfLearningScheduler`: Nightly cron (3 AM)

**Self-Learning Pipeline**:
```java
@Scheduled(cron = "0 0 3 * * ?")  // 3 AM daily
public void updateMerchantPatterns() {
    // 1. Fetch unprocessed corrections
    List<Correction> corrections = trainingDataRepo
        .findByIsProcessedFalse();
    
    // 2. Aggregate by merchant pattern
    Map<String, CategoryStats> stats = corrections.stream()
        .collect(groupingBy(c -> c.getMerchantNormalized(), 
                            collectingStats()));
    
    // 3. Update confidence scores
    for (Entry<String, CategoryStats> entry : stats.entrySet()) {
        String merchant = entry.getKey();
        CategoryStats stat = entry.getValue();
        
        if (stat.correctionRate > 0.7) {  // 70% agreement
            MerchantPattern pattern = patternRepo
                .findByMerchantPattern(merchant);
            pattern.setCategoryId(stat.dominantCategory);
            pattern.setConfidence(stat.correctionRate);
            patternRepo.save(pattern);
        }
    }
    
    // 4. Mark as processed
    corrections.forEach(c -> c.setIsProcessed(true));
    trainingDataRepo.saveAll(corrections);
}
```

---

#### 5. Analytics Service (Port 8083)
**Responsibilities**:
- Calculate model accuracy metrics
- Generate category distribution reports
- Spending trend analysis
- Confidence score histograms
- Daily aggregation job

**Key Components**:
- `AnalyticsController`: REST endpoints
- `AnalyticsService`: Aggregation logic
- `MetricsScheduler`: Daily job (2 AM)

**Aggregation Query Example**:
```sql
-- Daily accuracy calculation
INSERT INTO analytics_metrics 
    (user_id, date, total_transactions, correct_predictions, accuracy_rate)
SELECT 
    user_id,
    CURDATE() AS date,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN is_user_corrected = 0 THEN 1 ELSE 0 END) AS correct,
    SUM(CASE WHEN is_user_corrected = 0 THEN 1 ELSE 0 END) / COUNT(*) AS accuracy
FROM transactions
WHERE transaction_date >= DATE_SUB(CURDATE(), INTERVAL 1 DAY)
GROUP BY user_id;
```

---

## Data Flow

### User Transaction Upload Flow

```
┌─────────┐
│ Client  │
│ (React) │
└────┬────┘
     │ 1. POST /api/transactions/batch (CSV file)
     │    Authorization: Bearer JWT_TOKEN
     ▼
┌────────────┐
│  Gateway   │
│            │ 2. Validate JWT → Extract user_id
│            │ 3. Check rate limit (1000/min)
│            │ 4. Route to transaction-service
└─────┬──────┘
      │
      ▼
┌─────────────────┐
│ Transaction     │
│   Service       │
│                 │ 5. Parse CSV (Apache Commons CSV)
│                 │ 6. Validate each row (date, amount, merchant)
│                 │ 7. Normalize merchant names
│                 │    - Lowercase
│                 │    - Remove special chars
│                 │    - Trim whitespace
│                 │ 8. Batch insert into temp table
└─────┬───────────┘
      │
      │ 9. For each transaction (async):
      ▼
┌──────────────┐        ┌────────────┐
│ Redis Cache  │◄──────►│ ML Service │
│              │        │            │
│ Check cache: │        │ 10. Predict│
│ merchant →   │  Miss  │     category│
│   category   ├───────►│            │
│              │◄───────┤ Return:    │
│ Store result │  Hit   │ {category, │
│ (TTL: 7d)    │        │  confidence}│
└──────────────┘        └────────────┘
      │
      │ 11. Update transaction with category_id, confidence
      ▼
┌──────────────┐
│ MySQL        │
│              │ 12. Bulk insert transactions
│ transactions │     (batch size: 1000)
│    table     │ 13. Update analytics_metrics
└──────────────┘
      │
      │ 14. Return job status
      ▼
┌─────────────┐
│   Client    │ 15. Display results
│ (Dashboard) │     - Success count
│             │     - Failed rows with errors
└─────────────┘
```

### ML Categorization Flow (Detailed)

```
┌────────────────────────────────────────────────────────────────┐
│              ML Inference Service (FastAPI)                     │
├────────────────────────────────────────────────────────────────┤
│  POST /categorize                                               │
│  Input: {                                                       │
│    merchant_normalized: "swiggy",                               │
│    amount: 450.50,                                              │
│    currency: "INR",                                             │
│    user_id: "user_123",                                         │
│    last_transactions: [...]  // Last 5 for context              │
│  }                                                              │
└───┬────────────────────────────────────────────────────────────┘
    │
    ├─► 1. FinGPT Classifier (70% weight)
    │   ┌──────────────────────────────────────────────────────┐
    │   │ a. Tokenization:                                     │
    │   │    input_text = f"{merchant} spent {amount} "        │
    │   │                 f"recent: {last_categories}"         │
    │   │    tokens = tokenizer.encode(input_text)             │
    │   │                                                       │
    │   │ b. Model Inference:                                  │
    │   │    logits = model(tokens)  # Shape: [1, 15]          │
    │   │    fingpt_probs = softmax(logits)                    │
    │   │                                                       │
    │   │ c. Output:                                           │
    │   │    [0.85, 0.05, 0.02, ...]  # 15 categories          │
    │   └──────────────────────────────────────────────────────┘
    │
    └─► 2. Pattern-Based Classifier (30% weight)
        ┌──────────────────────────────────────────────────────┐
        │ a. Regex Matching:                                   │
        │    SELECT category_id, confidence                    │
        │    FROM merchant_patterns                            │
        │    WHERE 'swiggy' REGEXP merchant_pattern            │
        │      AND region = 'IN'                               │
        │    Result: {category_id: 1 (Food), conf: 0.95}       │
        │                                                       │
        │ b. Amount Heuristics:                                │
        │    IF amount < 50 AND merchant LIKE '%BMTC%':        │
        │       boost Transportation category                  │
        │                                                       │
        │ c. Output (one-hot encoded):                         │
        │    [0.95, 0.03, 0.02, ...]  # 15 categories          │
        └──────────────────────────────────────────────────────┘
    
    ┌──────────────────────────────────────────────────────────┐
    │ 3. Ensemble Weighted Voting                              │
    │    final_probs = 0.7 * fingpt_probs + 0.3 * pattern_probs│
    │                                                           │
    │    For "swiggy" example:                                 │
    │    final_probs[0] = 0.7*0.85 + 0.3*0.95 = 0.595 + 0.285  │
    │                   = 0.880 (Food & Dining)                │
    │                                                           │
    │    category_id = argmax(final_probs) = 1                 │
    │    confidence = 0.880                                    │
    └──────────────────────────────────────────────────────────┘
    
    ┌──────────────────────────────────────────────────────────┐
    │ 4. Return Response                                       │
    │    {                                                     │
    │      "category_id": 1,                                   │
    │      "category_name": "Food & Dining",                   │
    │      "confidence_score": 0.880,                          │
    │      "alternatives": [                                   │
    │        {id: 2, name: "Groceries", score: 0.05},          │
    │        {id: 15, name: "Others", score: 0.03}             │
    │      ]                                                   │
    │    }                                                     │
    └──────────────────────────────────────────────────────────┘
```

---

## Database Design

### Entity-Relationship Diagram

```
┌──────────────────────────┐
│        users             │
├──────────────────────────┤
│ user_id (PK)             │
│ email (UNIQUE)           │
│ password_hash            │
│ oauth_provider           │
│ created_at               │
│ updated_at               │
└────────┬─────────────────┘
         │ 1
         │
         │ N
         ▼
┌──────────────────────────┐       ┌──────────────────────────┐
│    transactions          │   N   │      categories          │
├──────────────────────────┤──────►├──────────────────────────┤
│ transaction_id (PK)      │   1   │ category_id (PK)         │
│ user_id (FK)             │       │ user_id (FK, NULLABLE)   │
│ merchant_name            │       │ category_name            │
│ merchant_normalized      │       │ category_type (ENUM)     │
│ amount                   │       │ parent_category_id (FK)  │
│ currency                 │       │ icon                     │
│ transaction_date         │       │ color                    │
│ category_id (FK)         │       │ created_at               │
│ confidence_score         │       └──────────┬───────────────┘
│ is_user_corrected        │                  │ 1
│ metadata_json (JSON)     │                  │
│ created_at               │                  │ N
└────────┬─────────────────┘                  ▼
         │ 1                        ┌──────────────────────────┐
         │                          │   merchant_patterns      │
         │ N                        ├──────────────────────────┤
         ▼                          │ pattern_id (PK)          │
┌──────────────────────────┐       │ merchant_pattern         │
│  model_training_data     │       │ category_id (FK)         │
├──────────────────────────┤       │ region                   │
│ training_id (PK)         │       │ confidence               │
│ transaction_id (FK)      │       │ usage_count              │
│ original_category_id (FK)│       │ last_used                │
│ corrected_category_id(FK)│       └──────────────────────────┘
│ user_id (FK)             │
│ correction_date          │       ┌──────────────────────────┐
│ is_processed             │       │   analytics_metrics      │
└──────────────────────────┘       ├──────────────────────────┤
                                   │ metric_id (PK)           │
                                   │ user_id (FK)             │
                                   │ date (DATE)              │
                                   │ total_transactions       │
                                   │ correct_predictions      │
                                   │ accuracy_rate            │
                                   │ avg_confidence           │
                                   │ category_distribution    │
                                   │   (JSON)                 │
                                   └──────────────────────────┘
```

### Table Schemas

#### transactions
```sql
CREATE TABLE transactions (
    transaction_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    merchant_name VARCHAR(255) NOT NULL,
    merchant_normalized VARCHAR(255) NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'INR',
    transaction_date DATETIME NOT NULL,
    category_id INT NOT NULL,
    confidence_score DECIMAL(4, 3) NOT NULL,  -- 0.000 to 1.000
    is_user_corrected BOOLEAN DEFAULT FALSE,
    metadata_json JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (category_id) REFERENCES categories(category_id),
    
    INDEX idx_user_date (user_id, transaction_date),
    INDEX idx_merchant_norm (merchant_normalized),
    INDEX idx_category (category_id),
    INDEX idx_confidence (confidence_score)
);
```

**Indexing Strategy**:
- `idx_user_date`: Fast filtering by user + date range queries
- `idx_merchant_norm`: Quick lookup for merchant pattern matching
- `idx_category`: Aggregations by category
- `idx_confidence`: Filter by confidence thresholds (e.g., <0.85 for verification)

---

## ML Pipeline

### Model Architecture (DistilBERT Placeholder)

```
Input Transaction:
{merchant: "Swiggy Order", amount: 450.50, last_5_categories: [1,1,5,2,1]}

                    ┌─────────────────────────────────┐
                    │     Feature Engineering         │
                    ├─────────────────────────────────┤
                    │ 1. Text: "swiggy order 450.50   │
                    │    recent: food food shopping   │
                    │    groceries food"              │
                    │ 2. Tokenization (BERT WordPiece)│
                    │    [101, 2015, 1045, ...]       │
                    │ 3. Padding to max_len=128       │
                    └─────────────┬───────────────────┘
                                  │
                                  ▼
                    ┌─────────────────────────────────┐
                    │  DistilBERT Encoder (6 layers)  │
                    ├─────────────────────────────────┤
                    │ - Multi-head Self-Attention     │
                    │ - Layer Normalization           │
                    │ - Feed-Forward Network          │
                    │ Output: [CLS] embedding (768-d) │
                    └─────────────┬───────────────────┘
                                  │
                                  ▼
                    ┌─────────────────────────────────┐
                    │   Classification Head           │
                    ├─────────────────────────────────┤
                    │ Linear(768 → 256) + ReLU        │
                    │ Dropout(0.1)                    │
                    │ Linear(256 → 15) [categories]   │
                    │ Softmax                         │
                    └─────────────┬───────────────────┘
                                  │
                                  ▼
                        [0.85, 0.05, 0.02, ...]
                        15-class probability distribution
```

### Training Pipeline (Future FinGPT Fine-tuning)

```python
# 1. Data Collection
- Collect 500K+ labeled transactions from users
- Include user corrections (model_training_data table)
- Balance classes (oversample rare categories)

# 2. Data Preprocessing
def preprocess(transaction):
    text = f"{merchant_normalized} {amount} {currency}"
    context = " ".join(last_5_category_names)
    return f"{text} context: {context}"

# 3. Fine-Tuning with LoRA (Low-Rank Adaptation)
from peft import LoraConfig, get_peft_model

lora_config = LoraConfig(
    r=16,  # Low-rank dimension
    lora_alpha=32,
    target_modules=["q_proj", "v_proj"],
    lora_dropout=0.1,
    task_type="SEQ_CLS"
)

model = AutoModelForSequenceClassification.from_pretrained(
    "FinGPT/fingpt-forecaster_dow30_llama2-7b_lora",
    num_labels=15
)
model = get_peft_model(model, lora_config)

# 4. Training
trainer = Trainer(
    model=model,
    train_dataset=train_ds,
    eval_dataset=val_ds,
    compute_metrics=compute_accuracy
)
trainer.train()

# 5. Export to TensorFlow Lite (for faster inference)
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()
```

---

## Security Architecture

### Authentication Flow (OAuth 2.0 + JWT)

```
┌────────┐                                          ┌─────────────┐
│ Client │                                          │   Google    │
│(React) │                                          │OAuth Server │
└───┬────┘                                          └──────┬──────┘
    │                                                      │
    │ 1. Click "Sign in with Google"                      │
    ├─────────────────────────────────────────────────────►│
    │                                                      │
    │ 2. Redirect to Google consent screen                │
    │◄─────────────────────────────────────────────────────┤
    │                                                      │
    │ 3. User grants permission                            │
    ├─────────────────────────────────────────────────────►│
    │                                                      │
    │ 4. Authorization code                                │
    │◄─────────────────────────────────────────────────────┤
    │                                                      │
    ▼                                                      │
┌──────────────┐                                          │
│   Gateway    │                                          │
│   Service    │                                          │
└───┬──────────┘                                          │
    │ 5. POST /oauth/token?code=AUTH_CODE                 │
    ├─────────────────────────────────────────────────────►│
    │                                                      │
    │ 6. Access Token                                      │
    │◄─────────────────────────────────────────────────────┤
    │                                                      │
    │ 7. GET /userinfo (with access token)                │
    ├─────────────────────────────────────────────────────►│
    │                                                      │
    │ 8. User profile {email, name, picture}               │
    │◄─────────────────────────────────────────────────────┤
    │                                                      │
    ▼                                                      │
┌──────────────┐                                          │
│    MySQL     │                                          │
│ users table  │                                          │
└───┬──────────┘                                          │
    │ 9. INSERT/UPDATE user                               │
    │    (email, oauth_provider='google')                 │
    │                                                      │
    │ 10. Generate JWT                                     │
    │     Payload: {user_id, email, exp}                  │
    │     Secret: env.JWT_SECRET                          │
    │     Expires: 1 hour                                 │
    │                                                      │
    ▼                                                      │
┌────────┐                                                │
│ Client │                                                │
└────────┘                                                │
    │ 11. Store JWT in localStorage                       │
    │     Store refresh_token (7 days)                    │
    │                                                      │
    │ 12. All API calls:                                  │
    │     Authorization: Bearer JWT_TOKEN                 │
```

### JWT Structure

```json
{
  "header": {
    "alg": "HS256",
    "typ": "JWT"
  },
  "payload": {
    "user_id": 123,
    "email": "user@example.com",
    "roles": ["USER"],
    "iat": 1700000000,
    "exp": 1700003600
  },
  "signature": "HMACSHA256(base64UrlEncode(header) + '.' + base64UrlEncode(payload), SECRET_KEY)"
}
```

### Rate Limiting (Bucket4j)

```java
@Configuration
public class RateLimitConfig {
    @Bean
    public Bucket createBucket() {
        Bandwidth limit = Bandwidth.classic(
            1000,  // 1000 requests
            Refill.greedy(1000, Duration.ofMinutes(1))
        );
        return Bucket4j.builder()
            .addLimit(limit)
            .build();
    }
}

// In Gateway filter
if (!bucket.tryConsume(1)) {
    throw new RateLimitException("Rate limit exceeded");
}
```

---

## Scalability & Performance

### Horizontal Scaling Strategy

```
┌────────────────────────────────────────────────────────────┐
│                     Load Balancer (Nginx)                   │
└──────┬───────────────┬───────────────┬─────────────────────┘
       │               │               │
       ▼               ▼               ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│  Gateway 1  │ │  Gateway 2  │ │  Gateway 3  │
│  (Stateless)│ │  (Stateless)│ │  (Stateless)│
└─────────────┘ └─────────────┘ └─────────────┘
       │               │               │
       └───────────────┴───────────────┘
                       │
       ┌───────────────┼───────────────┐
       ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│Transaction 1 │ │Transaction 2 │ │Transaction 3 │
│  (Stateless) │ │  (Stateless) │ │  (Stateless) │
└──────────────┘ └──────────────┘ └──────────────┘
       │               │               │
       └───────────────┴───────────────┘
                       │
       ┌───────────────┼───────────────┐
       ▼               ▼               ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  ML Svc 1    │ │  ML Svc 2    │ │  ML Svc 3    │
│ (GPU worker) │ │ (GPU worker) │ │ (GPU worker) │
└──────────────┘ └──────────────┘ └──────────────┘
       │               │               │
       └───────────────┴───────────────┘
                       │
       ┌───────────────┴───────────────┐
       ▼                               ▼
┌──────────────┐              ┌──────────────┐
│ MySQL Cluster│              │ Redis Cluster│
│ - Master (W) │              │ - Master     │
│ - Replica(R) │              │ - Replica    │
└──────────────┘              └──────────────┘
```

### Caching Strategy (Multi-Layer)

```
┌─────────────────────────────────────────────────────────────┐
│                     Application Layer                        │
├─────────────────────────────────────────────────────────────┤
│ L1 Cache: In-Memory (Caffeine)                              │
│ - Category metadata (15 default categories)                 │
│ - User profile (active users)                               │
│ - TTL: 10 minutes                                            │
│ - Max size: 10,000 entries                                  │
└────────────────────────┬────────────────────────────────────┘
                         │ Miss
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                     Redis Layer (L2)                         │
├─────────────────────────────────────────────────────────────┤
│ merchant_normalized → category_id mapping                   │
│ - Key: "merchant:{merchant_normalized}"                     │
│ - Value: {category_id, confidence}                          │
│ - TTL: 7 days                                                │
│ - Eviction: LRU                                              │
│                                                              │
│ JWT blacklist (for logout)                                  │
│ - Key: "jwt:blacklist:{token_hash}"                         │
│ - TTL: Match JWT expiry                                     │
└────────────────────────┬────────────────────────────────────┘
                         │ Miss
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                     MySQL Database                           │
├─────────────────────────────────────────────────────────────┤
│ - InnoDB buffer pool (8GB)                                   │
│ - Query cache disabled (deprecated in MySQL 8.0)            │
│ - Persistent storage                                         │
└─────────────────────────────────────────────────────────────┘
```

### Database Optimization

**Connection Pooling (HikariCP)**:
```yaml
spring:
  datasource:
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000
```

**Read-Write Splitting**:
```java
@Configuration
public class DataSourceConfig {
    @Bean
    @Primary
    public DataSource masterDataSource() {
        // Write operations
        return DataSourceBuilder.create()
            .url("jdbc:mysql://mysql-master:3306/fincategorizer")
            .build();
    }
    
    @Bean
    public DataSource replicaDataSource() {
        // Read-only operations (analytics)
        return DataSourceBuilder.create()
            .url("jdbc:mysql://mysql-replica:3306/fincategorizer")
            .build();
    }
}
```

---

## Deployment Architecture

### Docker Compose (Development)

```yaml
version: '3.8'
networks:
  fincategorizer-net:
    driver: bridge

services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root123
      MYSQL_DATABASE: fincategorizer
    volumes:
      - ./database/schema.sql:/docker-entrypoint-initdb.d/schema.sql
      - mysql-data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5
  
  redis:
    image: redis:7.2-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis-data:/data
  
  gateway-service:
    build: ./backend/gateway-service
    ports:
      - "8080:8080"
    depends_on:
      - mysql
      - redis
    environment:
      SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/fincategorizer
      SPRING_REDIS_HOST: redis
      JWT_SECRET: ${JWT_SECRET:-change-me-in-production}
  
  # ... other services
```

### Kubernetes (Production)

```yaml
# gateway-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gateway-service
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
        image: fincategorizer/gateway:latest
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_DATASOURCE_URL
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: url
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
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: gateway-hpa
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
```

---

## Monitoring & Observability

### Metrics Collection (Prometheus)

```java
@RestController
public class TransactionController {
    private final Counter transactionCounter = Counter.builder("transactions_created")
        .description("Total transactions created")
        .tag("service", "transaction-service")
        .register(Metrics.globalRegistry);
    
    private final Timer categorizationTimer = Timer.builder("categorization_duration")
        .description("Time to categorize transaction")
        .register(Metrics.globalRegistry);
    
    @PostMapping("/transactions")
    public ResponseEntity<Transaction> createTransaction(@RequestBody TransactionRequest req) {
        return categorizationTimer.record(() -> {
            Transaction txn = service.categorize(req);
            transactionCounter.increment();
            return ResponseEntity.ok(txn);
        });
    }
}
```

### Logging Strategy

```java
@Slf4j
public class TransactionService {
    public Transaction categorize(TransactionRequest req) {
        MDC.put("userId", req.getUserId());
        MDC.put("transactionId", UUID.randomUUID().toString());
        
        log.info("Categorizing transaction: merchant={}, amount={}", 
                 req.getMerchant(), req.getAmount());
        
        try {
            Category cat = mlClient.categorize(req);
            log.info("Categorized successfully: category={}, confidence={}", 
                     cat.getName(), cat.getConfidence());
            return save(req, cat);
        } catch (Exception e) {
            log.error("Categorization failed", e);
            throw new CategorizationException("Failed to categorize", e);
        } finally {
            MDC.clear();
        }
    }
}
```

---

**End of Architecture Document**
