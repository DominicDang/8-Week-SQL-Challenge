/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

WITH total_amount AS (SELECT s.customer_id, COUNT(product_id) AS total_amount
					  FROM dannys_diner.sales s
					  GROUP BY customer_id
					  ORDER BY customer_id ASC),

-- 2. How many days has each customer visited the restaurant?

visited_days AS (SELECT customer_id, COUNT(DISTINCT order_date) AS num_days
				 FROM dannys_diner.sales 
				 GROUP BY customer_id),

-- 3. What was the first item from the menu purchased by each customer?

first_item AS (SELECT s.customer_id, s.order_date, m.product_name
			   FROM dannys_diner.sales s
			   INNER JOIN dannys_diner.menu m 
			   USING (product_id)
			   ORDER BY customer_id ASC, order_date ASC),

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

num_purchased_items AS (SELECT product_id, COUNT(*) AS num_purchases
FROM dannys_diner.sales
GROUP BY product_id)

SELECT * 
FROM num_purchased_items
WHERE num_purchases >= (SELECT MAX(num_purchases) 
FROM num_purchased_items)

ranked_selection 
		AS (SELECT product_id, total_items, 
	   			   ROW_NUMBER() OVER(ORDER BY total_items DESC) AS rank
			FROM (SELECT product_id, COUNT(*) AS total_items
	  			  FROM dannys_diner.sales
	  		GROUP BY product_id) num_purchases),
      
SELECT product_id, total_items
FROM ranked_selection
WHERE rank = 1

-- 5. Which item was the most popular for each customer?

product_amount 
		AS (SELECT customer_id, product_id, COUNT(product_id) AS total_amount
			FROM dannys_diner.sales
			GROUP BY customer_id, product_id	
			ORDER BY customer_id ASC),

ranked_products 
		AS (SELECT customer_id, product_id, total_amount,
				   ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY total_amount DESC) AS rank
			FROM product_amount
			GROUP BY customer_id, product_id, total_amount),

SELECT customer_id, product_id, total_amount
FROM ranked_products
WHERE rank = 1

-- 6. Which item was purchased first by the customer after they became a member?

member_transactions 
		AS (SELECT *
            FROM dannys_diner.sales s
            INNER JOIN dannys_diner.members m
            USING (customer_id)
            WHERE order_date >= join_date),

ranked_data 
		AS (SELECT customer_id, product_id, order_date,
            	   ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date ASC) AS rank
            FROM member_transactions
            GROUP BY customer_id, product_id, order_date
            ORDER BY customer_id),
            
SELECT customer_id, product_id, order_date
FROM ranked_data
WHERE rank = 1

-- 7. Which item was purchased just before the customer became a member?

purchases_before 
		AS (SELECT *
            FROM dannys_diner.sales s
            INNER JOIN dannys_diner.members m 
            USING (customer_id)
            WHERE order_date < join_date),

ranked_before
		AS (SELECT customer_id, product_id, order_date,
            	   ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date DESC) AS rank
            FROM purchases_before),

SELECT customer_id, product_id, order_date
FROM ranked_before 
WHERE rank = 1
            
-- 8. What is the total items and amount spent for each member before they became a member?

-- Total items before they become a member
SELECT customer_id, COUNT(product_id) AS total_items
FROM purchases_before
GROUP BY customer_id

-- Amount spent before they become a member
SELECT customer_id, SUM(price) AS amount_spend
FROM purchases_before b
INNER JOIN dannys_diner.menu
USING (product_id)
GROUP BY customer_id


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

points_table 
		AS (SELECT customer_id, product_name, 
	   			   (CASE WHEN product_name = 'sushi' THEN price * 10 * 2
                    	 ELSE price * 10
                    END) AS points
			FROM dannys_diner.sales s
			INNER JOIN dannys_diner.menu m
			USING (product_id))

SELECT customer_id, SUM(points) AS total_points
FROM points_table
GROUP BY customer_id
ORDER BY customer_id ASC

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT customer_id, SUM(price*2*10) AS total_points
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu m1
USING (product_id)
INNER JOIN dannys_diner.members m2
USING (customer_id)
WHERE order_date >= join_date AND order_date BETWEEN join_date AND join_date + 7
GROUP BY customer_id
ORDER BY customer_id 
