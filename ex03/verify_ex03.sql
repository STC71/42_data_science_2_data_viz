-- EX03 Highest Building – comprobaciones 100%
-- Uso:
--   docker exec -i postgres_piscineds psql -U "$USER" -d piscineds -f verify_ex03.sql
--   o:  psql -U ... -d piscineds -f verify_ex03.sql

\echo '========== 1) TOTAL compradores (user_id distintos con purchase) =========='
SELECT COUNT(DISTINCT user_id) AS total_buyers
FROM customers
WHERE event_type = 'purchase';

\echo '========== 2) FREQUENCY – mismos bins que Building.py =========='
WITH per_user AS (
    SELECT user_id, COUNT(*)::int AS freq
    FROM customers
    WHERE event_type = 'purchase'
    GROUP BY user_id
),
binned AS (
    SELECT
        CASE
            WHEN freq < 10 THEN '0-10'
            WHEN freq < 20 THEN '10-20'
            WHEN freq < 30 THEN '20-30'
            ELSE '30+'
        END AS bin_label,
        CASE
            WHEN freq < 10 THEN 0
            WHEN freq < 20 THEN 1
            WHEN freq < 30 THEN 2
            ELSE 3
        END AS bin_id
    FROM per_user
)
SELECT bin_label, COUNT(*) AS n_customers
FROM binned
GROUP BY bin_label, bin_id
ORDER BY bin_id;

\echo '========== 3) Suma frequency = total_buyers? =========='
WITH per_user AS (
    SELECT user_id, COUNT(*)::int AS freq
    FROM customers
    WHERE event_type = 'purchase'
    GROUP BY user_id
),
binned AS (
    SELECT CASE
        WHEN freq < 10 THEN 0 WHEN freq < 20 THEN 1
        WHEN freq < 30 THEN 2 ELSE 3 END AS bin_id
    FROM per_user
)
SELECT
    (SELECT COUNT(*) FROM binned) AS sum_freq_bins,
    (SELECT COUNT(DISTINCT user_id) FROM customers WHERE event_type = 'purchase') AS total_buyers,
    (SELECT COUNT(*) FROM binned) =
    (SELECT COUNT(DISTINCT user_id) FROM customers WHERE event_type = 'purchase') AS match_ok;

\echo '========== 4) Solo columna 30+ (freq >= 30) =========='
SELECT COUNT(*) AS customers_30plus
FROM (
    SELECT user_id
    FROM customers
    WHERE event_type = 'purchase'
    GROUP BY user_id
    HAVING COUNT(*) >= 30
) t;

\echo '========== 5) Fronteras frequency (cuántos en 9, 10, 29, 30) =========='
WITH per_user AS (
    SELECT user_id, COUNT(*)::int AS freq
    FROM customers
    WHERE event_type = 'purchase'
    GROUP BY user_id
)
SELECT freq, COUNT(*) AS n_users
FROM per_user
WHERE freq IN (9, 10, 29, 30, 31)
GROUP BY freq
ORDER BY freq;

\echo '========== 6) MONETARY – mismos bins que Building.py =========='
WITH per_user AS (
    SELECT user_id, SUM(price) AS total_spent
    FROM customers
    WHERE event_type = 'purchase' AND price IS NOT NULL
    GROUP BY user_id
),
binned AS (
    SELECT
        CASE
            WHEN total_spent < 50  THEN '0-50'
            WHEN total_spent < 100 THEN '50-100'
            WHEN total_spent < 150 THEN '100-150'
            WHEN total_spent < 200 THEN '150-200'
            ELSE '200+'
        END AS bin_label,
        CASE
            WHEN total_spent < 50  THEN 0
            WHEN total_spent < 100 THEN 1
            WHEN total_spent < 150 THEN 2
            WHEN total_spent < 200 THEN 3
            ELSE 4
        END AS bin_id
    FROM per_user
)
SELECT bin_label, COUNT(*) AS n_customers
FROM binned
GROUP BY bin_label, bin_id
ORDER BY bin_id;

\echo '========== 7) Suma monetary = usuarios con purchase y price NOT NULL =========='
SELECT
    (SELECT COUNT(DISTINCT user_id)
     FROM customers
     WHERE event_type = 'purchase' AND price IS NOT NULL) AS users_with_price;

\echo '========== 8) 200+ (total_spent >= 200) =========='
SELECT COUNT(*) AS customers_200plus
FROM (
    SELECT user_id
    FROM customers
    WHERE event_type = 'purchase' AND price IS NOT NULL
    GROUP BY user_id
    HAVING SUM(price) >= 200
) t;

\echo '========== FIN =========='
