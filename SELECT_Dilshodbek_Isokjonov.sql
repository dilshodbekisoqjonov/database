-- Which staff members made the highest revenue for each store and deserve a bonus for the year 2017?

-- Solution 1: Using CTE (Common Table Expressions) and JOINs
WITH payment_year_2017 AS (
    SELECT s.staff_id, s.store_id, SUM(p.amount) AS revenue
    FROM payment p
    JOIN staff s ON p.staff_id = s.staff_id
    WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
    GROUP BY s.staff_id, s.store_id
),
max_revenue_per_store AS (
    SELECT store_id, MAX(revenue) AS max_revenue
    FROM payment_year_2017
    GROUP BY store_id
)
SELECT s.staff_id, s.first_name, s.last_name, s.store_id, p.revenue
FROM payment_year_2017 p
JOIN max_revenue_per_store m ON p.store_id = m.store_id AND p.revenue = m.max_revenue
JOIN staff s ON p.staff_id = s.staff_id
ORDER BY s.store_id;

-- Solution 2: Using subqueries and JOINs
SELECT s.staff_id, s.first_name, s.last_name, s.store_id, p.revenue
FROM (
    SELECT s.staff_id, s.store_id, SUM(p.amount) AS revenue
    FROM payment p
    JOIN staff s ON p.staff_id = s.staff_id
    WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
    GROUP BY s.staff_id, s.store_id
) p
JOIN staff s USING (staff_id)
WHERE (p.store_id, p.revenue) IN (
    SELECT store_id, MAX(revenue) AS max_revenue
    FROM (
        SELECT s.staff_id, s.store_id, SUM(p.amount) AS revenue
        FROM payment p
        JOIN staff s ON p.staff_id = s.staff_id
        WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
        GROUP BY s.staff_id, s.store_id
    ) sub
    GROUP BY store_id
)
ORDER BY s.store_id;

-- Solution 3: Using DISTINCT ON and window functions
SELECT DISTINCT ON (s.store_id) s.staff_id, s.first_name, s.last_name, s.store_id, SUM(p.amount) OVER (PARTITION BY s.staff_id) AS revenue
FROM payment p
JOIN staff s ON p.staff_id = s.staff_id
WHERE EXTRACT(YEAR FROM p.payment_date) = 2017
ORDER BY s.store_id, revenue DESC;

-- Which five movies were rented more than the others, and what is the expected age of the audience for these movies?

-- Solution 1: Using CTE (Common Table Expressions) and JOINs
WITH rentals_by_film AS (
    SELECT f.film_id, f.title, f.rating, COUNT(r.rental_id) AS rental_count
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    GROUP BY f.film_id, f.title, f.rating
)
SELECT rb.film_id, rb.title,
    CASE rb.rating
        WHEN 'G' THEN 'All ages'
        WHEN 'PG' THEN '7+'
        WHEN 'PG-13' THEN '13+'
        WHEN 'R' THEN '17+'
        WHEN 'NC-17' THEN '18+'
        ELSE 'Unknown'
    END AS expected_age_of_audience,
    rb.rental_count
FROM rentals_by_film rb
ORDER BY rb.rental_count DESC
LIMIT 5;

-- Solution 2: Using subqueries and JOINs
SELECT rb.film_id, rb.title, rb.rating, rb.rental_count
FROM (
    SELECT f.film_id, f.title, f.rating, COUNT(r.rental_id) AS rental_count
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    GROUP BY f.film_id, f.title, f.rating
) AS rb
ORDER BY rb.rental_count DESC
LIMIT 5;

SELECT rb.film_id, rb.title,
    CASE rb.rating
        WHEN 'G' THEN 'All ages'
        WHEN 'PG' THEN '7+'
        WHEN 'PG-13' THEN '13+'
        WHEN 'R' THEN '17+'
        WHEN 'NC-17' THEN '18+'
        ELSE 'Unknown'
    END AS expected_age_of_audience,
    rb.rental_count
FROM (
    SELECT f.film_id, f.title, f.rating, COUNT(r.rental_id) AS rental_count
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    GROUP BY f.film_id, f.title, f.rating
) AS rb
ORDER BY rb.rental_count DESC
LIMIT 5;

-- Solution 3: Using window functions and JOINs
WITH rentals_by_film AS (
    SELECT f.film_id, f.title, f.rating,
           COUNT(r.rental_id) AS rental_count,
           RANK() OVER (ORDER BY COUNT(r.rental_id) DESC) AS rental_rank
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    GROUP BY f.film_id, f.title, f.rating
)
SELECT film_id, title, rating,
    CASE rating
        WHEN 'G' THEN 'All ages'
        WHEN 'PG' THEN '7+'
        WHEN 'PG-13' THEN '13+'
        WHEN 'R' THEN '17+'
        WHEN 'NC-17' THEN '18+'
        ELSE 'Unknown'
    END AS expected_age_of_audience,
    rental_count
FROM rentals_by_film
WHERE rental_rank <= 5
ORDER BY rental_count DESC LIMIT 5;

-- Which actors/actresses didn't act for a longer period of time than the others?

--Solution 1: Using CTE (Common Table Expressions) and JOINs
WITH actor_last_film_date AS (
    SELECT a.actor_id, a.first_name, a.last_name, MAX(f.release_year) AS last_film_year
    FROM actor a
    JOIN film_actor fa ON a.actor_id = fa.actor_id
    JOIN film f ON fa.film_id = f.film_id
    GROUP BY a.actor_id, a.first_name, a.last_name
)
SELECT actor_id, first_name, last_name, last_film_year
FROM actor_last_film_date
WHERE last_film_year <= (SELECT min(last_film_year) FROM actor_last_film_date);

-- Solution 2: Using subqueries and JOINs
SELECT a.actor_id, a.first_name, a.last_name, MAX(f.release_year) AS last_film_year
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN film f ON fa.film_id = f.film_id
GROUP BY a.actor_id, a.first_name, a.last_name
HAVING MAX(f.release_year) <= (
    SELECT MIN(subquery.last_film_year)
    FROM (
        SELECT a2.actor_id, MAX(f2.release_year) AS last_film_year
        FROM actor a2
        JOIN film_actor fa2 ON a2.actor_id = fa2.actor_id
        JOIN film f2 ON fa2.film_id = f2.film_id
        GROUP BY a2.actor_id
    ) subquery
);

-- Solution 3: Using window functions and JOINs
WITH actor_last_film_date AS (
    SELECT a.actor_id, a.first_name, a.last_name,
           MAX(f.release_year) AS last_film_year,
           MIN(MAX(f.release_year)) OVER () AS min_last_film_year
    FROM actor a
    JOIN film_actor fa ON a.actor_id = fa.actor_id
    JOIN film f ON fa.film_id = f.film_id
    GROUP BY a.actor_id, a.first_name, a.last_name
)
SELECT actor_id, first_name, last_name, last_film_year
FROM actor_last_film_date
WHERE last_film_year = min_last_film_year;
