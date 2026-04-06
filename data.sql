CREATE DATABASE ecommerce;
USE ecommerce;

CREATE TABLE ecommerce_data (
event_time VARCHAR(50),
event_type VARCHAR(20),
product_id BIGINT,
category_id BIGINT,
category_code VARCHAR(100),
brand VARCHAR(100),
price FLOAT,
user_id BIGINT,
user_session VARCHAR(100)
);

select *
from ecommerce_data;

-- check brand why missing data
SELECT *
FROM ecommerce_data
WHERE brand IS NULL;

SELECT brand, LENGTH(brand)
FROM ecommerce_data
WHERE TRIM(brand) = '';

-- missing data
UPDATE ecommerce_data
SET brand = 'Unknown'
WHERE brand = '';

-- check cate-code why missing data
SELECT *
FROM ecommerce_data
WHERE category_code IS NULL;

SELECT category_code, LENGTH(category_code)
FROM ecommerce_data
WHERE TRIM(category_code) = '';

-- missing data
UPDATE ecommerce_data
SET category_code = 'Unknown'
WHERE category_code = '';

-- replace date
UPDATE ecommerce_data
SET event_time = REPLACE(event_time,' UTC','');

-- Convert event_time -> DATETIME
ALTER TABLE ecommerce_data
ADD event_time_clean DATETIME;

UPDATE ecommerce_data
SET event_time_clean = STR_TO_DATE(event_time, '%Y-%m-%d %H:%i:%s');

-- data duplicate
SELECT 
    user_id,
    product_id,
    event_time,
    event_type,
    COUNT(*) as cnt
FROM ecommerce_data
GROUP BY user_id, product_id, event_time, event_type
HAVING COUNT(*) > 1;

-- cate 
SELECT 
    SUBSTRING_INDEX(category_code, '.', 1) AS main_category,
    SUBSTRING_INDEX(category_code, '.', -1) AS sub_category
FROM ecommerce_data;

-- delete data duplicate
ALTER TABLE ecommerce_data
ADD id INT AUTO_INCREMENT PRIMARY KEY;

DELETE FROM ecommerce_data
WHERE id NOT IN (
    SELECT id FROM (
        SELECT 
            id,
            ROW_NUMBER() OVER (
                PARTITION BY user_id, product_id, event_time, event_type
                ORDER BY id
            ) as rn
        FROM ecommerce_data
    ) t
    WHERE rn = 1
);

-- phân tích phần chính
-- total user
SELECT COUNT(DISTINCT user_id) AS total_users
FROM ecommerce_data;

-- total session
SELECT COUNT(DISTINCT user_session) AS total_sessions
FROM ecommerce_data;

-- event type
SELECT event_type, COUNT(*) total
FROM ecommerce_data
GROUP BY event_type;

-- Conversion Rate
SELECT 
    SUM(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS views,
    SUM(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS carts,
    SUM(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchases
FROM ecommerce_data;

-- User có view
SELECT COUNT(DISTINCT user_id)
FROM ecommerce_data
WHERE event_type = 'view';

-- User có cart
SELECT COUNT(DISTINCT user_id)
FROM ecommerce_data
WHERE event_type = 'cart';

-- User có purchase
SELECT COUNT(DISTINCT user_id)
FROM ecommerce_data
WHERE event_type = 'purchase';

-- total user cho từng hành vi
WITH user_funnel AS (
    SELECT 
        user_id,
        MAX(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS carted,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased
    FROM ecommerce_data
    GROUP BY user_id
)

SELECT 
    COUNT(*) AS total_users,
    SUM(viewed) AS users_view,
    SUM(carted) AS users_cart,
    SUM(purchased) AS users_purchase
FROM user_funnel;

-- Doanh thu
SELECT SUM(price) AS total_revenue
FROM ecommerce_data
WHERE event_type = 'purchase';

-- top cate
SELECT 
    SUBSTRING_INDEX(category_code, '.', 1) AS main_category,
    COUNT(*) AS purchases
FROM ecommerce_data
WHERE event_type = 'purchase'
GROUP BY main_category
ORDER BY purchases DESC
LIMIT 10;

-- top brand
SELECT brand, COUNT(*) AS purchases
FROM ecommerce_data
WHERE event_type = 'purchase'
GROUP BY brand
ORDER BY purchases DESC
LIMIT 10;

-- user view only
SELECT COUNT(DISTINCT user_id)
FROM ecommerce_data
WHERE user_id NOT IN (
    SELECT DISTINCT user_id
    FROM ecommerce_data
    WHERE event_type = 'purchase'
);

-- user thêm hàng
SELECT COUNT(DISTINCT user_id)
FROM ecommerce_data
WHERE user_id IN (
    SELECT user_id FROM ecommerce_data WHERE event_type = 'cart'
)
AND user_id NOT IN (
    SELECT user_id FROM ecommerce_data WHERE event_type = 'purchase'
);