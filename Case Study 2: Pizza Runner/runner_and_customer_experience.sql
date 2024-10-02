CREATE TEMP TABLE customer_orders_temp AS
(SELECT order_id, customer_id, pizza_id,
	    CASE WHEN exclusions IS NULL or exclusions LIKE 'null' OR exclusions LIKE '' THEN NULL
       		 ELSE exclusions
             END AS exclusions,
        CASE WHEN extras IS NULL or extras LIKE 'null' OR extras LIKE '' THEN NULL
       		 ELSE extras
             END AS extras,
 		order_time
FROM pizza_runner.customer_orders); 

CREATE TEMP TABLE runner_orders_temp AS
(
    SELECT 
        order_id, 
        runner_id, 
        CASE 
            WHEN pickup_time IS NULL OR pickup_time = 'null' THEN NULL
            ELSE pickup_time
        END AS pickup_time, 
        CASE 
            WHEN distance IS NULL OR distance = 'null' THEN NULL
            WHEN distance LIKE '%km' THEN TRIM('km' FROM distance)::FLOAT
            ELSE distance::FLOAT
        END AS distance, 
        CASE 
            WHEN duration IS NULL OR duration = 'null' THEN NULL
            WHEN duration LIKE '%minutes' THEN TRIM(' minutes' FROM duration)::INTEGER
            WHEN duration LIKE '%mins' THEN TRIM(' mins' FROM duration)::INTEGER
  			WHEN duration LIKE '%minute' THEN TRIM (' minute' FROM duration)::INTEGER
            ELSE duration::INTEGER
        END AS duration, 
        CASE 
            WHEN cancellation IS NULL OR cancellation = 'null' OR cancellation = '' THEN NULL
            ELSE cancellation
        END AS cancellation
    FROM 
        pizza_runner.runner_orders
);

ALTER TABLE runner_orders_temp
ALTER COLUMN pickup_time TYPE timestamp with time zone USING pickup_time::timestamp with time zone;

-- B. Runner and Customer Experience
--1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT EXTRACT ('week' FROM registration_date) AS registration_week,
	   COUNT(runner_id) AS runner_signup
FROM pizza_runner.runners
GROUP BY registration_week;

--2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

WITH mins_diff AS (
			SELECT r.runner_id, c.order_id, r.pickup_time, c.order_time,
	   		 		EXTRACT(EPOCH FROM (r.pickup_time - c.order_time)) / 60 AS minutes_diff
  			FROM customer_orders_temp c
  			INNER JOIN runner_orders_temp r
  			USING (order_id))
            
SELECT runner_id, AVG(minutes_diff) AS avg_min_diff
FROM mins_diff
GROUP BY runner_id
ORDER BY runner_id;

--3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

WITH prep_time_cte 
	AS (
  		SELECT 
    		c.order_id, 
    		COUNT(c.order_id) AS pizza_order, 
    		c.order_time, 
    		r.pickup_time, 
    		EXTRACT(EPOCH FROM (pickup_time - order_time)) / 60 AS minutes_diff
  		FROM customer_orders_temp c
  		JOIN runner_orders_temp r
    	ON c.order_id = r.order_id
  		WHERE r.distance != 0
  		GROUP BY c.order_id, c.order_time, r.pickup_time
)

SELECT order_id, minutes_diff, pizza_order
FROM prep_time_cte
ORDER BY order_id;

--4. What was the average distance travelled for each customer?

SELECT customer_id , AVG(distance) AS avg_distance
FROM runner_orders_temp r, customer_orders_temp c
WHERE r.order_id = c.order_id
GROUP BY customer_id
ORDER BY customer_id;

--5. What was the difference between the longest and shortest delivery times for all orders?

WITH prep_time_cte 
	AS (
  		SELECT 
    		c.order_id, 
    		COUNT(c.order_id) AS pizza_order, 
    		c.order_time, 
    		r.pickup_time, 
    		EXTRACT(EPOCH FROM (pickup_time - order_time)) / 60 AS minutes_diff
  		FROM customer_orders_temp c
  		JOIN runner_orders_temp r
    	ON c.order_id = r.order_id
  		WHERE r.distance != 0
  		GROUP BY c.order_id, c.order_time, r.pickup_time
)

SELECT MAX(minutes_diff)- MIN (minutes_diff) AS max_delivered_time
FROM prep_time_cte;

--6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT order_id, runner_id, distance,
	   duration/60 AS duration_hour,
       AVG(distance/duration*60) AS avg_speed
FROM runner_orders_temp 
WHERE distance IS NOT NULL
GROUP BY order_id, runner_id, distance, duration
ORDER BY order_id;

--7. What is the successful delivery percentage for each runner?

SELECT 
  runner_id, 
  ROUND(100 * SUM(
    CASE WHEN distance IS NULL THEN 0
    ELSE 1 END) / COUNT(*), 0) AS success_perc
FROM runner_orders_temp
GROUP BY runner_id
ORDER BY runner_id;

