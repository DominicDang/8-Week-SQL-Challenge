CREATE TEMP TABLE customer_orders_temp AS
(SELECT order_id, customer_id, pizza_id,
	    CASE WHEN exclusions IS NULL or exclusions LIKE 'null' THEN ''
       		 ELSE exclusions
             END AS exclusions,
        CASE WHEN extras IS NULL or extras LIKE 'null' THEN ''
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
            WHEN cancellation IS NULL OR cancellation = 'null' THEN NULL
            ELSE cancellation
        END AS cancellation
    FROM 
        pizza_runner.runner_orders
);

-- A. Pizza Metrics
-- 1. How many pizzas were ordered?

SELECT COUNT(pizza_id) AS total_pizzas
FROM customer_orders_temp;

-- 2. How many unique customer orders were made?

SELECT COUNT(DISTINCT order_id) AS num_customers
FROM customer_orders_temp;

-- 3. How many successful orders were delivered by each runner?

SELECT runner_id, 
	      COUNT(order_id) AS num_succesful_orders
FROM runner_orders_temp
WHERE distance != 0 
GROUP BY runner_id;

-- 4. How many of each type of pizza was delivered?

SELECT c.pizza_id, COUNT(*) AS num_of_pizzas
FROM customer_orders_temp c
INNER JOIN runner_orders_temp r
USING (order_id)
WHERE r.duration != 0 
GROUP BY c.pizza_id

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
-- 6. What was the maximum number of pizzas delivered in a single order?
-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
-- 8. How many pizzas were delivered that had both exclusions and extras?
-- 9. What was the total volume of pizzas ordered for each hour of the day?
-- 10. What was the volume of orders for each day of the week?
