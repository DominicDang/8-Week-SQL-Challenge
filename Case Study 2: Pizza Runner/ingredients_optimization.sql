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

-- C. Ingredient Optimisation
-- 1. What are the standard ingredients for each pizza?
-- 2. What was the most commonly added extra?
-- 3. What was the most common exclusion?
-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
