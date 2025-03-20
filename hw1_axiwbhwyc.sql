--Задача 1. Средняя стоимость заказа по категориям товаров--
select name as category_name, AVG(summ) as avg_order_amount
from 
(select categories.name as name, SUM(products.price*order_items.quantity) as summ
from order_items 
join orders on order_items.order_id=orders.id 
join products on order_items.product_id =products.id
join categories on categories.id=products.category_id
where orders.created_at>='2023-03-01' and orders.created_at<'2023-04-01'
group by categories.name, order_items.order_id)
group by name;

--Задача 2. Рейтинг пользователей по сумме оплаченных заказов--
WITH user_spending AS (
    SELECT 
        u.id AS user_id,
        u.name AS user_name,
        SUM(p.amount) AS total_spent
    FROM 
        users u
    JOIN 
        orders o ON u.id = o.user_id
    JOIN 
        payments p ON o.id = p.order_id
    WHERE 
        o.status = 'Оплачен'
    GROUP BY 
        u.id, u.name
),
ranked_users AS (
    SELECT 
        user_id,
        user_name,
        total_spent,
        RANK() OVER (ORDER BY total_spent DESC) AS user_rank
    FROM 
        user_spending
)
SELECT 
    user_name,
    total_spent,
    user_rank
FROM 
    ranked_users
WHERE 
    user_rank <= 3;

--Задача 3. Количество заказов и сумма платежей по месяцам--
SELECT 
    TO_CHAR(o.created_at, 'YYYY-MM') AS month,
    COUNT(DISTINCT o.id) AS total_orders,
    COALESCE(SUM(p.amount), 0) AS total_payments
FROM 
    orders o
LEFT JOIN 
    payments p ON o.id = p.order_id
WHERE 
    o.created_at >= '2023-01-01' AND o.created_at < '2024-01-01'
GROUP BY 
    TO_CHAR(o.created_at, 'YYYY-MM')
ORDER BY 
    month;


--Задача 4. Рейтинг товаров по количеству продаж--
WITH product_sales AS (
    SELECT 
        p.id AS product_id,
        p.name AS product_name,
        SUM(oi.quantity) AS total_sold
    FROM 
        order_items oi
    JOIN 
        products p ON oi.product_id = p.id
    GROUP BY 
        p.id, p.name
),
total_sales AS (
    SELECT 
        SUM(total_sold) AS total_quantity
    FROM 
        product_sales
)
SELECT 
    ps.product_name,
    ps.total_sold,
    ROUND((ps.total_sold * 1.0 / ts.total_quantity) * 100, 2) AS sales_percentage
FROM 
    product_sales ps,
    total_sales ts
ORDER BY 
    ps.total_sold DESC
LIMIT 5;

--Задача 5. Пользователи, которые сделали заказы на сумму выше среднего--
WITH user_payments AS (
    SELECT 
        u.id AS user_id,
        u.name AS user_name,
        SUM(p.amount) AS total_paid
    FROM 
        users u
    JOIN 
        orders o ON u.id = o.user_id
    JOIN 
        payments p ON o.id = p.order_id
    WHERE 
        o.status = 'Оплачен'
    GROUP BY 
        u.id, u.name
),
avg_payment AS (
    SELECT 
        AVG(total_paid) AS avg_total_paid
    FROM 
        user_payments
)
SELECT 
    up.user_name,
    up.total_paid
FROM 
    user_payments up,
    avg_payment ap
WHERE 
    up.total_paid > ap.avg_total_paid
ORDER BY 
    up.total_paid DESC;

--Задача 6. Рейтинг товаров по количеству продаж в каждой категории--
WITH product_sales AS (
    SELECT 
        c.name AS category_name,
        p.name AS product_name,
        SUM(oi.quantity) AS total_sold,
        ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY SUM(oi.quantity) DESC) AS rank
    FROM 
        order_items oi
    JOIN 
        products p ON oi.product_id = p.id
    JOIN 
        categories c ON p.category_id = c.id
    GROUP BY 
        c.id, c.name, p.id, p.name
)
SELECT 
    category_name,
    product_name,
    total_sold
FROM 
    product_sales
WHERE 
    rank <= 3
ORDER BY 
    category_name, rank;

--Задача 7. Категории товаров с максимальной выручкой в каждом месяце--
WITH monthly_revenue AS (
    SELECT 
        TO_CHAR(o.created_at, 'YYYY-MM') AS month,
        c.name AS category_name,
        SUM(oi.quantity * p.price) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY TO_CHAR(o.created_at, 'YYYY-MM') ORDER BY SUM(oi.quantity * p.price) DESC) AS rank
    FROM 
        orders o
    JOIN 
        order_items oi ON o.id = oi.order_id
    JOIN 
        products p ON oi.product_id = p.id
    JOIN 
        categories c ON p.category_id = c.id
    WHERE 
        o.created_at >= '2023-01-01' AND o.created_at < '2023-07-01'
    GROUP BY 
        TO_CHAR(o.created_at, 'YYYY-MM'), c.name
)
SELECT 
    month,
    category_name,
    total_revenue
FROM 
    monthly_revenue
WHERE 
    rank = 1
ORDER BY 
    month;

--Задача 8. Накопительная сумма платежей по месяцам--
SELECT 
    TO_CHAR(p.payment_date, 'YYYY-MM') AS month,
    SUM(p.amount) AS monthly_payments,
    SUM(SUM(p.amount)) OVER (ORDER BY TO_CHAR(p.payment_date, 'YYYY-MM') ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_payments
FROM 
    payments p
WHERE 
    p.payment_date >= '2023-01-01' AND p.payment_date < '2024-01-01'
GROUP BY 
    TO_CHAR(p.payment_date, 'YYYY-MM')
ORDER BY 
    month;