-- FinCategorizer Database Schema
-- MySQL 8.0+
-- Description: Complete database schema with tables, indexes, and seed data

-- ============================================================================
-- DROP EXISTING TABLES (for clean setup)
-- ============================================================================
DROP TABLE IF EXISTS analytics_metrics;
DROP TABLE IF EXISTS model_training_data;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS merchant_patterns;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS users;

-- ============================================================================
-- USERS TABLE
-- ============================================================================
CREATE TABLE users (
    user_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255),  -- NULL for OAuth users
    oauth_provider VARCHAR(50),  -- 'google', 'local', etc.
    full_name VARCHAR(255),
    profile_picture_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE,
    
    INDEX idx_email (email),
    INDEX idx_oauth (oauth_provider)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- CATEGORIES TABLE
-- ============================================================================
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NULL,  -- NULL for default categories, NOT NULL for custom
    category_name VARCHAR(100) NOT NULL,
    category_type ENUM('default', 'custom') NOT NULL DEFAULT 'custom',
    parent_category_id INT NULL,  -- For hierarchical categories
    icon VARCHAR(50),  -- Material-UI icon name or emoji
    color VARCHAR(7),  -- Hex color code #RRGGBB
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (parent_category_id) REFERENCES categories(category_id) ON DELETE SET NULL,
    
    INDEX idx_user_category (user_id, category_type),
    INDEX idx_type (category_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- TRANSACTIONS TABLE
-- ============================================================================
CREATE TABLE transactions (
    transaction_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    merchant_name VARCHAR(255) NOT NULL,
    merchant_normalized VARCHAR(255) NOT NULL,  -- Lowercase, no special chars
    amount DECIMAL(15, 2) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'INR',
    transaction_date DATETIME NOT NULL,
    category_id INT NOT NULL,
    confidence_score DECIMAL(4, 3) NOT NULL,  -- 0.000 to 1.000
    is_user_corrected BOOLEAN DEFAULT FALSE,
    metadata_json JSON,  -- Additional metadata: location, notes, tags, etc.
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(category_id),
    
    -- Performance indexes
    INDEX idx_user_date (user_id, transaction_date DESC),
    INDEX idx_merchant_norm (merchant_normalized),
    INDEX idx_category (category_id),
    INDEX idx_confidence (confidence_score),
    INDEX idx_user_corrected (user_id, is_user_corrected),
    INDEX idx_date_range (transaction_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- MERCHANT PATTERNS TABLE (for pattern-based classification)
-- ============================================================================
CREATE TABLE merchant_patterns (
    pattern_id INT AUTO_INCREMENT PRIMARY KEY,
    merchant_pattern VARCHAR(255) NOT NULL,  -- Regex or exact match
    category_id INT NOT NULL,
    region VARCHAR(10) NOT NULL DEFAULT 'IN',  -- 'IN', 'US', 'GLOBAL', etc.
    confidence DECIMAL(4, 3) NOT NULL DEFAULT 0.900,  -- Pattern confidence
    usage_count INT DEFAULT 0,  -- How many times this pattern was used
    last_used TIMESTAMP NULL,
    pattern_type ENUM('regex', 'exact', 'contains', 'starts_with', 'ends_with') DEFAULT 'contains',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE CASCADE,
    
    INDEX idx_pattern_region (merchant_pattern, region),
    INDEX idx_region_category (region, category_id),
    INDEX idx_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- MODEL TRAINING DATA TABLE (for self-learning)
-- ============================================================================
CREATE TABLE model_training_data (
    training_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    transaction_id BIGINT NOT NULL,
    original_category_id INT NOT NULL,  -- ML predicted category
    corrected_category_id INT NOT NULL,  -- User corrected category
    user_id BIGINT NOT NULL,
    correction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_processed BOOLEAN DEFAULT FALSE,  -- Processed by self-learning job
    feedback_notes TEXT,  -- Optional user feedback
    
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE CASCADE,
    FOREIGN KEY (original_category_id) REFERENCES categories(category_id),
    FOREIGN KEY (corrected_category_id) REFERENCES categories(category_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    
    INDEX idx_user_processed (user_id, is_processed),
    INDEX idx_processed_date (is_processed, correction_date),
    UNIQUE KEY unique_correction (transaction_id)  -- One correction per transaction
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- ANALYTICS METRICS TABLE (pre-computed aggregations)
-- ============================================================================
CREATE TABLE analytics_metrics (
    metric_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    date DATE NOT NULL,
    total_transactions INT NOT NULL DEFAULT 0,
    correct_predictions INT NOT NULL DEFAULT 0,
    accuracy_rate DECIMAL(5, 4),  -- 0.0000 to 1.0000
    avg_confidence DECIMAL(4, 3),
    category_distribution JSON,  -- {"1": 45, "2": 23, "3": 12, ...}
    top_merchants JSON,  -- [{"merchant": "Swiggy", "count": 15, "amount": 2500}, ...]
    spending_by_category JSON,  -- {"Food": 5000, "Transport": 1200, ...}
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    
    UNIQUE KEY unique_user_date (user_id, date),
    INDEX idx_date (date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- SEED DATA: DEFAULT CATEGORIES (15 categories)
-- ============================================================================
INSERT INTO categories (category_id, user_id, category_name, category_type, parent_category_id, icon, color, description) VALUES
(1, NULL, 'Food & Dining', 'default', NULL, '🍔', '#FF6B6B', 'Restaurants, food delivery, dining out'),
(2, NULL, 'Groceries', 'default', NULL, '🛒', '#4ECDC4', 'Supermarkets, grocery stores, fresh produce'),
(3, NULL, 'Transportation', 'default', NULL, '🚗', '#45B7D1', 'Uber, Ola, metro, bus, fuel'),
(4, NULL, 'Shopping', 'default', NULL, '🛍️', '#FFA07A', 'Clothing, electronics, online shopping'),
(5, NULL, 'Entertainment', 'default', NULL, '🎬', '#DDA15E', 'Movies, concerts, streaming subscriptions'),
(6, NULL, 'Healthcare', 'default', NULL, '🏥', '#BC6C25', 'Hospitals, medicines, doctor visits'),
(7, NULL, 'Bills & Utilities', 'default', NULL, '💡', '#606C38', 'Electricity, water, internet, phone bills'),
(8, NULL, 'Travel', 'default', NULL, '✈️', '#283618', 'Flights, hotels, vacation expenses'),
(9, NULL, 'Education', 'default', NULL, '📚', '#FEFAE0', 'Tuition, courses, books, school supplies'),
(10, NULL, 'Investments', 'default', NULL, '📈', '#DDA15E', 'Stocks, mutual funds, SIPs'),
(11, NULL, 'Insurance', 'default', NULL, '🛡️', '#BC6C25', 'Health, life, vehicle insurance'),
(12, NULL, 'Subscriptions', 'default', NULL, '📱', '#606C38', 'Netflix, Spotify, gym memberships'),
(13, NULL, 'Fuel', 'default', NULL, '⛽', '#283618', 'Petrol, diesel, CNG'),
(14, NULL, 'Gifts & Donations', 'default', NULL, '🎁', '#FEFAE0', 'Gifts, charity, donations'),
(15, NULL, 'Others', 'default', NULL, '📦', '#A8DADC', 'Miscellaneous transactions');

-- ============================================================================
-- SEED DATA: INDIAN MERCHANT PATTERNS (50+ patterns)
-- ============================================================================
INSERT INTO merchant_patterns (merchant_pattern, category_id, region, confidence, pattern_type, usage_count) VALUES
-- Food & Dining (Category 1)
('swiggy', 1, 'IN', 0.980, 'contains', 0),
('zomato', 1, 'IN', 0.980, 'contains', 0),
('dominos', 1, 'IN', 0.950, 'contains', 0),
('pizza hut', 1, 'IN', 0.950, 'contains', 0),
('mcdonalds', 1, 'IN', 0.950, 'contains', 0),
('kfc', 1, 'IN', 0.950, 'contains', 0),
('starbucks', 1, 'IN', 0.920, 'contains', 0),
('dunzo daily', 1, 'IN', 0.900, 'contains', 0),
('food panda', 1, 'IN', 0.950, 'contains', 0),

-- Groceries (Category 2)
('zepto', 2, 'IN', 0.980, 'contains', 0),
('blinkit', 2, 'IN', 0.980, 'contains', 0),
('grofers', 2, 'IN', 0.980, 'contains', 0),
('bigbasket', 2, 'IN', 0.980, 'contains', 0),
('dmart', 2, 'IN', 0.970, 'contains', 0),
('reliance fresh', 2, 'IN', 0.970, 'contains', 0),
('more supermarket', 2, 'IN', 0.960, 'contains', 0),
('spencers', 2, 'IN', 0.960, 'contains', 0),
('jiomart', 2, 'IN', 0.970, 'contains', 0),

-- Transportation (Category 3)
('uber', 3, 'IN', 0.980, 'contains', 0),
('ola', 3, 'IN', 0.980, 'contains', 0),
('rapido', 3, 'IN', 0.970, 'contains', 0),
('bmtc', 3, 'IN', 0.990, 'contains', 0),
('best bus', 3, 'IN', 0.990, 'contains', 0),
('delhi metro', 3, 'IN', 0.990, 'contains', 0),
('mumbai metro', 3, 'IN', 0.990, 'contains', 0),
('irctc', 3, 'IN', 0.980, 'contains', 0),
('redbus', 3, 'IN', 0.970, 'contains', 0),

-- Shopping (Category 4)
('amazon', 4, 'IN', 0.900, 'contains', 0),
('flipkart', 4, 'IN', 0.950, 'contains', 0),
('myntra', 4, 'IN', 0.980, 'contains', 0),
('ajio', 4, 'IN', 0.980, 'contains', 0),
('meesho', 4, 'IN', 0.970, 'contains', 0),
('nykaa', 4, 'IN', 0.980, 'contains', 0),
('shoppers stop', 4, 'IN', 0.970, 'contains', 0),
('lifestyle', 4, 'IN', 0.960, 'contains', 0),

-- Entertainment (Category 5)
('bookmyshow', 5, 'IN', 0.990, 'contains', 0),
('paytm movies', 5, 'IN', 0.980, 'contains', 0),
('pvr cinemas', 5, 'IN', 0.990, 'contains', 0),
('inox', 5, 'IN', 0.990, 'contains', 0),

-- Bills & Utilities (Category 7)
('cred', 7, 'IN', 0.900, 'contains', 0),
('paytm', 7, 'IN', 0.850, 'contains', 0),
('phonepe', 7, 'IN', 0.850, 'contains', 0),
('google pay', 7, 'IN', 0.850, 'contains', 0),
('bharatpe', 7, 'IN', 0.870, 'contains', 0),
('electricity bill', 7, 'IN', 0.990, 'contains', 0),
('water bill', 7, 'IN', 0.990, 'contains', 0),

-- Subscriptions (Category 12)
('netflix', 12, 'IN', 0.990, 'contains', 0),
('amazon prime', 12, 'IN', 0.980, 'contains', 0),
('disney hotstar', 12, 'IN', 0.990, 'contains', 0),
('spotify', 12, 'IN', 0.990, 'contains', 0),
('youtube premium', 12, 'IN', 0.990, 'contains', 0),
('cult fit', 12, 'IN', 0.980, 'contains', 0),

-- Fuel (Category 13)
('indian oil', 13, 'IN', 0.980, 'contains', 0),
('bharat petroleum', 13, 'IN', 0.980, 'contains', 0),
('hp petrol', 13, 'IN', 0.980, 'contains', 0),
('shell', 13, 'IN', 0.970, 'contains', 0);

-- ============================================================================
-- SEED DATA: DEMO USER
-- ============================================================================
INSERT INTO users (email, password_hash, oauth_provider, full_name, is_active) VALUES
('demo@fincategorizer.com', '$2a$12$LQzXvH6X3qP8dHVE6kF.3eYqZJt7h8xJvLPgC3sKqN8vY5zRtXxSK', 'local', 'Demo User', TRUE);
-- Password: Demo@123 (BCrypt hashed)

-- ============================================================================
-- SEED DATA: SAMPLE TRANSACTIONS (50 transactions for demo user)
-- ============================================================================
SET @demo_user_id = LAST_INSERT_ID();

INSERT INTO transactions (user_id, merchant_name, merchant_normalized, amount, currency, transaction_date, category_id, confidence_score, is_user_corrected) VALUES
-- November 2025
(@demo_user_id, 'Swiggy Order #123456', 'swiggy order', 450.00, 'INR', '2025-11-17 12:30:00', 1, 0.950, FALSE),
(@demo_user_id, 'Zepto - Groceries', 'zepto groceries', 850.50, 'INR', '2025-11-17 09:15:00', 2, 0.980, FALSE),
(@demo_user_id, 'Uber Trip', 'uber trip', 180.00, 'INR', '2025-11-16 18:45:00', 3, 0.970, FALSE),
(@demo_user_id, 'Amazon.in', 'amazon in', 1299.00, 'INR', '2025-11-16 14:20:00', 4, 0.850, FALSE),
(@demo_user_id, 'BookMyShow - Avengers', 'bookmyshow avengers', 500.00, 'INR', '2025-11-15 19:30:00', 5, 0.990, FALSE),
(@demo_user_id, 'Apollo Pharmacy', 'apollo pharmacy', 320.00, 'INR', '2025-11-15 11:00:00', 6, 0.920, FALSE),
(@demo_user_id, 'Electricity Bill - BESCOM', 'electricity bill bescom', 1850.00, 'INR', '2025-11-14 10:00:00', 7, 0.990, FALSE),
(@demo_user_id, 'MakeMyTrip - Hotel Booking', 'makemytrip hotel booking', 4500.00, 'INR', '2025-11-13 22:15:00', 8, 0.960, FALSE),
(@demo_user_id, 'Coursera Subscription', 'coursera subscription', 3999.00, 'INR', '2025-11-12 08:30:00', 9, 0.950, FALSE),
(@demo_user_id, 'Zerodha - SIP', 'zerodha sip', 5000.00, 'INR', '2025-11-11 09:00:00', 10, 0.940, FALSE),
(@demo_user_id, 'HDFC Life Insurance', 'hdfc life insurance', 15000.00, 'INR', '2025-11-10 15:30:00', 11, 0.980, FALSE),
(@demo_user_id, 'Netflix Subscription', 'netflix subscription', 649.00, 'INR', '2025-11-09 00:05:00', 12, 0.990, FALSE),
(@demo_user_id, 'Indian Oil Petrol', 'indian oil petrol', 2000.00, 'INR', '2025-11-08 17:45:00', 13, 0.980, FALSE),
(@demo_user_id, 'Gift Card - Amazon', 'gift card amazon', 1000.00, 'INR', '2025-11-07 12:00:00', 14, 0.900, FALSE),
(@demo_user_id, 'Misc Payment', 'misc payment', 250.00, 'INR', '2025-11-06 14:30:00', 15, 0.600, FALSE),

-- October 2025
(@demo_user_id, 'Zomato Order', 'zomato order', 380.00, 'INR', '2025-10-30 20:15:00', 1, 0.960, FALSE),
(@demo_user_id, 'BigBasket', 'bigbasket', 1200.00, 'INR', '2025-10-29 10:30:00', 2, 0.970, FALSE),
(@demo_user_id, 'Ola Cab', 'ola cab', 220.00, 'INR', '2025-10-28 18:00:00', 3, 0.980, FALSE),
(@demo_user_id, 'Flipkart', 'flipkart', 2499.00, 'INR', '2025-10-27 16:45:00', 4, 0.930, FALSE),
(@demo_user_id, 'PVR Cinemas', 'pvr cinemas', 600.00, 'INR', '2025-10-26 21:00:00', 5, 0.990, FALSE),
(@demo_user_id, 'Doctor Consultation', 'doctor consultation', 800.00, 'INR', '2025-10-25 11:30:00', 6, 0.880, FALSE),
(@demo_user_id, 'Jio Fiber Bill', 'jio fiber bill', 999.00, 'INR', '2025-10-24 09:00:00', 7, 0.970, FALSE),
(@demo_user_id, 'Dominos Pizza', 'dominos pizza', 599.00, 'INR', '2025-10-23 19:30:00', 1, 0.950, FALSE),
(@demo_user_id, 'DMart', 'dmart', 1850.00, 'INR', '2025-10-22 17:00:00', 2, 0.960, FALSE),
(@demo_user_id, 'Uber Eats', 'uber eats', 420.00, 'INR', '2025-10-21 13:15:00', 1, 0.940, FALSE),
(@demo_user_id, 'Myntra Shopping', 'myntra shopping', 1899.00, 'INR', '2025-10-20 15:30:00', 4, 0.970, FALSE),
(@demo_user_id, 'Spotify Premium', 'spotify premium', 119.00, 'INR', '2025-10-19 00:10:00', 12, 0.990, FALSE),
(@demo_user_id, 'Shell Petrol Pump', 'shell petrol pump', 1800.00, 'INR', '2025-10-18 16:30:00', 13, 0.970, FALSE),
(@demo_user_id, 'Starbucks Coffee', 'starbucks coffee', 450.00, 'INR', '2025-10-17 10:00:00', 1, 0.920, FALSE),
(@demo_user_id, 'Book Purchase - Amazon', 'book purchase amazon', 699.00, 'INR', '2025-10-16 14:45:00', 9, 0.900, FALSE),
(@demo_user_id, 'Cult.fit Membership', 'cult fit membership', 2499.00, 'INR', '2025-10-15 08:00:00', 12, 0.980, FALSE),
(@demo_user_id, 'KFC Order', 'kfc order', 550.00, 'INR', '2025-10-14 20:30:00', 1, 0.950, FALSE),
(@demo_user_id, 'Rapido Bike', 'rapido bike', 45.00, 'INR', '2025-10-13 09:15:00', 3, 0.960, FALSE),
(@demo_user_id, 'Nykaa Beauty', 'nykaa beauty', 1250.00, 'INR', '2025-10-12 18:30:00', 4, 0.970, FALSE),
(@demo_user_id, 'Water Bill', 'water bill', 450.00, 'INR', '2025-10-11 10:30:00', 7, 0.990, FALSE),
(@demo_user_id, 'RedBus Ticket', 'redbus ticket', 850.00, 'INR', '2025-10-10 22:00:00', 3, 0.970, FALSE),
(@demo_user_id, 'Amazon Prime Video', 'amazon prime video', 299.00, 'INR', '2025-10-09 00:15:00', 12, 0.980, FALSE),
(@demo_user_id, 'Pharmacy - MedPlus', 'pharmacy medplus', 380.00, 'INR', '2025-10-08 12:30:00', 6, 0.910, FALSE),
(@demo_user_id, 'Blinkit Groceries', 'blinkit groceries', 650.00, 'INR', '2025-10-07 19:15:00', 2, 0.980, FALSE),
(@demo_user_id, 'IRCTC Train Ticket', 'irctc train ticket', 1200.00, 'INR', '2025-10-06 07:30:00', 3, 0.980, FALSE),
(@demo_user_id, 'Donation - NGO', 'donation ngo', 500.00, 'INR', '2025-10-05 16:00:00', 14, 0.870, FALSE),
(@demo_user_id, 'Swiggy Instamart', 'swiggy instamart', 450.00, 'INR', '2025-10-04 21:00:00', 2, 0.950, FALSE),
(@demo_user_id, 'Google One Storage', 'google one storage', 130.00, 'INR', '2025-10-03 00:20:00', 12, 0.960, FALSE),
(@demo_user_id, 'Reliance Fresh', 'reliance fresh', 980.00, 'INR', '2025-10-02 11:45:00', 2, 0.960, FALSE),
(@demo_user_id, 'PayTM Recharge', 'paytm recharge', 399.00, 'INR', '2025-10-01 09:30:00', 7, 0.850, FALSE),

-- September 2025
(@demo_user_id, 'Pizza Hut', 'pizza hut', 799.00, 'INR', '2025-09-28 19:45:00', 1, 0.950, FALSE),
(@demo_user_id, 'Uber Auto', 'uber auto', 90.00, 'INR', '2025-09-25 08:15:00', 3, 0.970, FALSE),
(@demo_user_id, 'Ajio Fashion', 'ajio fashion', 1599.00, 'INR', '2025-09-22 15:00:00', 4, 0.970, FALSE),
(@demo_user_id, 'Hotstar Subscription', 'hotstar subscription', 1499.00, 'INR', '2025-09-20 00:30:00', 12, 0.990, FALSE),
(@demo_user_id, 'BMTC Bus Pass', 'bmtc bus pass', 1000.00, 'INR', '2025-09-15 10:00:00', 3, 0.990, FALSE);

-- ============================================================================
-- INITIAL ANALYTICS METRICS (for demo)
-- ============================================================================
INSERT INTO analytics_metrics (user_id, date, total_transactions, correct_predictions, accuracy_rate, avg_confidence, category_distribution) VALUES
(@demo_user_id, '2025-11-17', 50, 48, 0.9600, 0.940, '{"1":12,"2":10,"3":8,"4":6,"5":2,"6":2,"7":4,"8":1,"9":1,"10":1,"11":1,"12":6,"13":3,"14":2,"15":1}');

-- ============================================================================
-- PERFORMANCE OPTIMIZATION: ANALYZE TABLES
-- ============================================================================
ANALYZE TABLE users;
ANALYZE TABLE categories;
ANALYZE TABLE transactions;
ANALYZE TABLE merchant_patterns;
ANALYZE TABLE model_training_data;
ANALYZE TABLE analytics_metrics;

-- ============================================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================================

-- View: User transaction summary
CREATE VIEW v_user_transaction_summary AS
SELECT 
    u.user_id,
    u.email,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(t.amount) AS total_spent,
    AVG(t.confidence_score) AS avg_confidence,
    SUM(CASE WHEN t.is_user_corrected = TRUE THEN 1 ELSE 0 END) AS corrections,
    MAX(t.transaction_date) AS last_transaction_date
FROM users u
LEFT JOIN transactions t ON u.user_id = t.user_id
GROUP BY u.user_id, u.email;

-- View: Category spending by user
CREATE VIEW v_category_spending AS
SELECT 
    t.user_id,
    c.category_name,
    COUNT(t.transaction_id) AS transaction_count,
    SUM(t.amount) AS total_amount,
    AVG(t.confidence_score) AS avg_confidence
FROM transactions t
JOIN categories c ON t.category_id = c.category_id
GROUP BY t.user_id, c.category_name;

-- ============================================================================
-- STORED PROCEDURES
-- ============================================================================

DELIMITER $$

-- Procedure: Calculate daily accuracy for a user
CREATE PROCEDURE sp_calculate_daily_accuracy(IN p_user_id BIGINT, IN p_date DATE)
BEGIN
    DECLARE v_total INT;
    DECLARE v_correct INT;
    DECLARE v_accuracy DECIMAL(5,4);
    DECLARE v_avg_conf DECIMAL(4,3);
    
    -- Count total and correct predictions
    SELECT 
        COUNT(*) INTO v_total
    FROM transactions
    WHERE user_id = p_user_id 
      AND DATE(transaction_date) = p_date;
    
    SELECT 
        SUM(CASE WHEN is_user_corrected = FALSE THEN 1 ELSE 0 END) INTO v_correct
    FROM transactions
    WHERE user_id = p_user_id 
      AND DATE(transaction_date) = p_date;
    
    SELECT 
        AVG(confidence_score) INTO v_avg_conf
    FROM transactions
    WHERE user_id = p_user_id 
      AND DATE(transaction_date) = p_date;
    
    SET v_accuracy = IFNULL(v_correct / v_total, 0);
    
    -- Insert or update analytics metrics
    INSERT INTO analytics_metrics (user_id, date, total_transactions, correct_predictions, accuracy_rate, avg_confidence)
    VALUES (p_user_id, p_date, v_total, v_correct, v_accuracy, v_avg_conf)
    ON DUPLICATE KEY UPDATE
        total_transactions = v_total,
        correct_predictions = v_correct,
        accuracy_rate = v_accuracy,
        avg_confidence = v_avg_conf;
END$$

DELIMITER ;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

DELIMITER $$

-- Trigger: Update merchant pattern usage count
CREATE TRIGGER trg_update_pattern_usage
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    UPDATE merchant_patterns
    SET usage_count = usage_count + 1,
        last_used = NOW()
    WHERE LOWER(NEW.merchant_normalized) LIKE CONCAT('%', merchant_pattern, '%')
      AND region = 'IN'
    LIMIT 1;
END$$

DELIMITER ;

-- ============================================================================
-- INDEXES FOR FULL-TEXT SEARCH (optional, for advanced search)
-- ============================================================================
-- ALTER TABLE transactions ADD FULLTEXT INDEX ft_merchant (merchant_name, merchant_normalized);

-- ============================================================================
-- GRANT PERMISSIONS (for application user)
-- ============================================================================
-- CREATE USER 'fincategorizer_app'@'%' IDENTIFIED BY 'SecurePassword123!';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON fincategorizer.* TO 'fincategorizer_app'@'%';
-- FLUSH PRIVILEGES;

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
SELECT 'Database schema initialized successfully!' AS status;
