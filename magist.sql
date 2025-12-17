use magist;

-- 1. How many orders are there in the dataset? -- 99441 orders
SELECT COUNT(*) num_orders
FROM orders;

-- 2. Are orders actually delivered? -- 97% of orders are delivered
SELECT
	order_status, 
    COUNT(*) num_orders,
    COUNT(*)*100/(SELECT COUNT(*) FROM orders) percentage
FROM orders
GROUP BY order_status;

-- 3. Is Magist having user growth? -- yes

SELECT 
	YEAR(order_purchase_timestamp) year, 
    MONTH(order_purchase_timestamp) month, 
    COUNT(*) num_users
FROM orders
GROUP BY year, month
ORDER BY year, month;

-- 4. How many products are there on the products table? -- 32951 products
SELECT COUNT(DISTINCT product_id) product_id
FROM products; 

-- 5. Which are the categories with the most products? -- bed_bath_table, sports_leisure, furniture_decor
SELECT 
	p.product_category_name brazilian,
	t.product_category_name_english english, 
    COUNT(*) count
    -- COUNT(*)*100/(SELECT COUNT(*) FROM products) percentage 5% computers accessories, 
FROM products p
JOIN product_category_name_translation t
ON p.product_category_name=t.product_category_name
GROUP BY brazilian,english
ORDER BY count DESC
;

-- 6. How many of those products were present in actual transactions? -- 32951 (29.3%)
SELECT COUNT(*)
FROM products
WHERE product_id IN (SELECT DISTINCT product_id FROM order_items); 

SELECT
    COUNT(DISTINCT oi.product_id) AS products_in_transactions,
    COUNT(*) AS total_products,
    COUNT(DISTINCT oi.product_id) * 100.0 / COUNT(*) AS percentage_used
FROM products p
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id;


-- 7. What’s the price for the most expensive and most cheapest products?
SELECT MIN(price) min, MAX(price) max
FROM order_items
;

-- 8. What are the highest and lowest payment values? 
SELECT MIN(payment_value) min, MAX(payment_value) max
FROM order_payments
;


-- --------------------------------------BUSINESS-QUESTIONS------------------------------------------------------
-- 9/1 What categories of tech products does Magist have?

SELECT DISTINCT
    t.product_category_name_english eng
FROM products p
JOIN product_category_name_translation t
ON p.product_category_name=t.product_category_name
WHERE t.product_category_name_english IN (
'electronics', 'computers'
'computers_accessories',
'telephony',
'consoles_games',
'audio',
'tablets_printing_image',
'cine_photo',
'books_technical',
'pc_gamer'
);

-- 10/2. How many products of these tech categories have been sold (within the time window of the database snapshot)? 
-- What percentage does that represent from the overall number of products sold?

SELECT
    t.product_category_name_english AS category,
    COUNT(oi.product_id) AS sold_in_category,

    COUNT(oi.product_id) * 100.0
    / (
        SELECT COUNT(*)
        FROM order_items
    ) AS percentage

FROM product_category_name_translation t
JOIN products p
    ON t.product_category_name = p.product_category_name
JOIN order_items oi
    ON p.product_id = oi.product_id

WHERE t.product_category_name_english IN (
    'computers'
    'electronics',
    'computers_accessories',
    'telephony',
    'consoles_games',
    'audio',
    'tablets_printing_image',
    'cine_photo',
    'books_technical',
    'pc_gamer'
)
GROUP BY t.product_category_name_english
ORDER BY sold_in_category DESC;

-- 11/3 What’s the average price of the tech products being sold? --78.7K

SELECT ROUND(AVG(price),3)
FROM order_items oi
JOIN products p
ON p.product_id = oi.product_id
JOIN product_category_name_translation t
ON p.product_category_name = t.product_category_name
WHERE t.product_category_name_english IN (
    'electronics',
    'computers'
    'computers_accessories',
    'telephony',
    'consoles_games',
    'audio',
    'tablets_printing_image',
    'cine_photo',
    'books_technical',
    'pc_gamer'
);

-- 13/5 How many months of data are included in the magist database?

SELECT 
    COUNT(DISTINCT DATE_FORMAT(order_purchase_timestamp, '%Y-%m')) num_month
FROM orders;

-- 14/6 How many sellers are there? How many Tech sellers are there? What percentage of overall sellers are Tech sellers? -- 16.4% tech sellers, 83.6% other sellers

SELECT 
	tech.tech_sellers tech_sellers,
    tot.tot_sellers total_sellers,
    tech.tech_sellers*100/tot.tot_sellers pct_tech_sellers

FROM
(SELECT COUNT(*) tot_sellers FROM sellers) tot,
(SELECT COUNT(DISTINCT
	oi.seller_id) tech_sellers
    -- t.product_category_name_english
FROM 
	products p
JOIN 
	product_category_name_translation t
ON 
	p.product_category_name=t.product_category_name
JOIN 
	order_items oi
ON 
	p.product_id=oi.product_id
WHERE t.product_category_name_english IN(
		 'electronics',
		 'computers',
         'computers_accessories',
         'telephony',
         'consoles_games',
         'audio',
         'tablets_printing_image',
         'cine_photo',
         'books_technical',
         'pc_gamer'
)
) tech;

-- 15/7 What is the total amount earned by all sellers? 13591643.7
-- What is the total amount earned by all Tech sellers? 1862089.3
SELECT 
    ROUND(SUM(price), 2) AS total_revenue_all_sellers
FROM order_items;


SELECT ROUND(SUM(price),3) tot_revenue_tech_sellers
FROM order_items oi
JOIN products p
ON oi.product_id=p.product_id
JOIN product_category_name_translation t
ON t.product_category_name=p.product_category_name
WHERE t.product_category_name_english IN(
		 'electronics',
		 'computers',
         'computers_accessories',
         'telephony',
         'consoles_games',
         'audio',
         'tablets_printing_image',
         'cine_photo',
         'books_technical',
         'pc_gamer'
)
;

-- 16/8 Can you work out the average monthly income of all sellers? Can you work out the average monthly income of Tech sellers? 938.33, 866.49

SELECT AVG(monthly_r.revenue) monthly_income
FROM
(SELECT
	seller_id s, 
    SUM(price) revenue,
    MONTH(order_purchase_timestamp) m
FROM order_items oi
JOIN orders o
ON o.order_id=oi.order_id
JOIN products p
ON oi.product_id=p.product_id
JOIN product_category_name_translation t
ON t.product_category_name=p.product_category_name
WHERE t.product_category_name_english IN (

		 'electronics',
		 'computers',
         'computers_accessories',
         'telephony',
         'consoles_games',
         'audio',
         'tablets_printing_image',
         'cine_photo',
         'books_technical',
         'pc_gamer')

GROUP BY m,s

) monthly_r;

-- 17/9 What’s the average time between the order being placed and the product being delivered? 12.5 days

SELECT
	ROUND(AVG(DATEDIFF(order_delivered_customer_date,order_purchase_timestamp)),1) avg_diff_days
FROM 
	orders;
    
-- 18/10 How many orders are delivered on time vs orders delivered with a delay? on time 88649, delay 7827

SELECT
	COUNT(*) num_orders,
    -- DATEDIFF(order_estimated_delivery_date,order_delivered_customer_date) timediff,
	CASE
		WHEN order_estimated_delivery_date > order_delivered_customer_date THEN 'on time'
        WHEN order_estimated_delivery_date < order_delivered_customer_date THEN 'delayed'
        ELSE 'no data'
	END AS status
FROM 
	orders
GROUP BY status
ORDER BY num_orders DESC
;



