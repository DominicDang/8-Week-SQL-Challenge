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

SELECT *
FROM pizza_runner.pizza_toppings;

-- 2. What was the most commonly added extra?

WITH toppings AS (SELECT pizza_id, 
	   REGEXP_SPLIT_TO_TABLE(toppings, '[,\s]+')::INTEGER AS topping_id
FROM pizza_runner.pizza_recipes)

SELECT topping_id, pt.topping_name, COUNT(*) AS total_frequency
FROM toppings t
INNER JOIN pizza_toppings pt
USING (topping_id)
GROUP BY t.topping_id, pt.topping_name
ORDER BY total_frequency DESC;

-- 3. What was the most common exclusion?

WITH toppings_excluded AS (SELECT pizza_id,
	   REGEXP_SPLIT_TO_TABLE(exclusions, '[,\s]+'):: INTEGER AS topping_id
FROM customer_orders_temp)

SELECT topping_id, COUNT(*) AS frequency
FROM toppings_excluded
GROUP BY topping_id;

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following: Meat Lovers Meat Lovers - Exclude Beef Meat Lovers - Extra Bacon Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

WITH toppings_data AS 
	(SELECT order_id, 
			REGEXP_SPLIT_TO_TABLE(exclusions, '[,\s]+'):: INTEGER AS exclusions,
			REGEXP_SPLIT_TO_TABLE(extras, '[,\s]+'):: INTEGER AS extras
FROM customer_orders_temp)

SELECT order_id, 
	   CASE WHEN exclusions = 3 THEN 'Meat Lovers - Exclude Beef'
       		WHEN extras = 1 THEN 'Meat Lovers - Extra Bacon'
            WHEN exclusions = 4 THEN 'Meat Lovers - Exclude Cheese'
            WHEN extras = 6 AND extras = 9 THEN 'Bacon - Extra Mushrooms, Peppers'
       ELSE 'Meat Lovers' END AS order_type
FROM toppings_data
GROUP BY order_id, exclusions, extras

-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients For example: "Meat Lovers: 2xBacon, Beef, ... , Salami" 

SELECT 
    pizza_type, 
    GROUP_CONCAT(
        CASE 
            WHEN quantity = 2 THEN CONCAT('2x', ingredient)
            ELSE ingredient
        END
        ORDER BY ingredient ASC
        SEPARATOR ', '
    ) AS ingredients_list
FROM customer_orders_temp
GROUP BY pizza_type;
