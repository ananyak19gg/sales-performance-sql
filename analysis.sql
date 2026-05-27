CREATE DATABASE superstore_db;
USE superstore_db;
SHOW TABLES;
SELECT * FROM superstore LIMIT 1;
SELECT COUNT(*) FROM superstore;
SHOW COLUMNS FROM superstore;

-- Which category generates the most revenue but has the weakest profit margin?
SELECT category, SUM(sales) as revenue, ROUND(SUM(profit)/(SUM(quantity*sales))*100, 2) as profit_margin -- taking sales represents rev already
FROM superstore
GROUP BY category
ORDER BY revenue DESC, profit_margin ASC; 
-- Furniture has low revenue, high margin. WHY?
	SELECT category, 
	AVG(discount) as avg_discount,
	SUM(profit) as total_profit
	FROM superstore
	GROUP BY category; -- 
/* INSIGHT: Furniture has the highest discount but generates the lowest total_profit, so indicating low profitable.
			Office supplies has slightly lower discount but produces high profit, so more efficient pricing. 
            Technology has the lowest discount and achieves highest profit.
            Overall excessive discounting appears to negatively impact profitability,
*/

-- Which region contributes most to revenue and is it also the most profitable?
SELECT region, SUM(sales) as revenue, SUM(profit) as region_profit, ROUND(SUM(profit)/SUM(sales)*100,2) as profit_margin
FROM superstore
GROUP BY region
ORDER BY revenue DESC;
-- Why is Central underperforming?
	SELECT category, 
	SUM(profit) as total_profit,
	AVG(discount) as avg_discount
	FROM superstore
	WHERE region = 'Central'
	GROUP BY category
	ORDER BY total_profit ASC;
/*
INSIGHT: While most regions have a stable relationship between revenue and profit, the central region is standing out because it has high revenue but low profit margin.
		 This underperformance by the central is driven by multiple loss making sub categories like furniture, appliances, binders which are heavily discounted.
		 Overall inconsistent and aggresive discounting is having an impact on central region profitability
*/

-- Is discounting hurting profit — does higher discount mean lower profit?
SELECT sub_category, AVG(discount) as avg_discount, SUM(profit) as total_profit, SUM(sales) as total_sales
FROM superstore
GROUP BY sub_category
ORDER BY avg_discount DESC;
-- Why is Binders profitable despite high discount?
	SELECT region, SUM(profit), AVG(discount) 
	FROM superstore WHERE sub_category = 'Binders' GROUP BY region;
/*
INSIGHT: The impact of discounting on profitability varies significantly across sub-categories and regions
		  meaning that a uniform pricing strategy is ineffective.
          Sub-categories such as Tables and Bookcases produces heavy losses at relatively high discount levels
          Binders sustain high discount while generating overall profit, A deeper regional analysis reveals that this profitability is unevenly distributed. While regions
		  like West and East remain profitable under moderate discounting, the Central region incurs losses
		  due to extremely high discounts.
          Overall, discounting alone does not determine profitability; its impact depends on sub-category
		  characteristics and regional execution.
*/

 -- Which products are selling well but still losing money?
SELECT product_id, SUM(sales) as product_sales, SUM(profit) as product_profit
FROM superstore
GROUP BY product_id
HAVING product_profit < 0 AND product_sales > 1000 -- we could also take a threshold value for sales 
ORDER BY product_sales DESC ;
/*SELECT category, COUNT(*) as loss_products, SUM(product_profit) as total_loss
FROM (
    SELECT product_id, category,
           SUM(profit) as product_profit,
           SUM(sales) as product_sales
    FROM superstore
    GROUP BY product_id, category
    HAVING SUM(profit) < 0 AND SUM(sales) > 1000
) t
GROUP BY category
ORDER BY total_loss ASC;
*/
/*
INSIGHT: significant number of high revenue products are operating at a loss, indicating systemic
		 pricing or cost inefficiencies.
		 Furniture is the primary concern, with the highest number of loss-making products and the
		 largest overall loss, suggesting widespread discounting or cost issues.
		 Technologyhas few products but contributes disproportionately high losses,
		 Overall, both the volume (Furniture) and severity (Technology) of loss-making products
		 highlight critical areas where pricing and cost strategies must be optimized to improve profitability.
*/

-- Who is the top performing product within each category?
SELECT product_id, category, total_profit
FROM (SELECT product_id, category, total_profit, RANK() OVER (PARTITION BY category ORDER BY total_profit DESC) as rnk
    FROM (SELECT product_id, category, SUM(profit) as total_profit
          FROM superstore
          GROUP BY product_id, category
         ) t1
      ) t2
WHERE rnk = 1
ORDER BY total_profit DESC;
/*
INSIGHT: Top-performing products vary significantly across categories, with Technology
		 outperforming others by a large margin.
		 In contrast, even the best-performing product in Furniture yields relatively low
		 profit, reinforcing the category’s overall weak profitability.
         This highlights a structural imbalance where Technology drives high-value gains,
         while Furniture remains a low-margin category, even at its peak performance.
*/

-- How has monthly revenue trended over the years — are we growing?
SELECT YEAR(order_date) as yr, MONTH(order_date) as mon, SUM(sales) as revenue
FROM superstore
GROUP BY yr, mon
ORDER BY yr, mon;
/*
INSIGHT: Revenue shows strong growth from 2011 to 2013, with slight stabilization in 2014.
		 A clear seasonal pattern exists, with peaks in September–December (especially November)
         and lows in January–February, indicating year-end demand and monthly volatility.
*/

 -- Which month showed the highest growth and which crashed?
SELECT *, ROUND((rev - prev_rev)/prev_rev * 100, 2) as growth_percent
FROM (
    SELECT mon, yr, rev, LAG(rev) OVER(ORDER BY yr, mon) as prev_rev
    FROM (
        SELECT MONTH(order_date) as mon, YEAR(order_date) as yr, SUM(sales) as rev
        FROM superstore
        GROUP BY yr, mon
    ) t
) t2
WHERE prev_rev IS NOT NULL
ORDER BY growth_percent ASC;
/*
INSIGHT: Monthly growth is highly volatile, driven more by seasonality and low base effects than steady expansion.
		 Revenue declines sharply in January–February, followed by recovery in March, while peak growth
         occurs during September–November, aligning with high-demand periods.
		 Overall, growth patterns are inconsistent month-to-month and heavily influenced by seasonal trends.
*/

 -- What does cumulative revenue look like — when did we cross major milestones?
 SELECT monthly_rev, SUM(monthly_rev) OVER (ORDER BY yr, mon) as cummulative_revenue
 FROM 
	(SELECT YEAR(order_date) as yr, MONTH(order_date) as mon, SUM(sales) as monthly_rev
	FROM superstore
	GROUP BY YEAR(order_date), MONTH(order_date) ) as monthly_total;
	/*	 SELECT *,
		CASE 
			WHEN cumulative_revenue >= 1000000 THEN '1M reached'
			WHEN cumulative_revenue >= 2000000 THEN '2M reached'
		END as milestone
		FROM (
			SELECT yr, mon, 
				   SUM(monthly_rev) OVER (ORDER BY yr, mon) as cumulative_revenue
			FROM (
				SELECT YEAR(order_date) as yr, MONTH(order_date) as mon, SUM(sales) as monthly_rev
				FROM superstore
				GROUP BY yr, mon
			) t
		) t2;   
	*/
 /*
INSIGHT: Cumulative revenue keeps increasing over time, which shows that the business is growing overall.
		 However, this steady increase is normal and does not show the ups and downs happening each month.
         To better understand growth, we should check how long it takes to reach milestones
         (like 1 million, 2 million, etc.) to see if the business is growing faster or slowing down.
*/   
 -- Which customer segment drives the most profit and are we over-discounting them?
SELECT segment, SUM(profit) as total_profit, AVG(discount) as avg_discount, SUM(sales) as revenue, ROUND(SUM(profit)/SUM(sales)*100,2) as margin
FROM superstore
GROUP BY segment;
 /*
INSIGHT: The Consumer segment generates the highest profit and revenue, making it the most important segment.
		 However, it has the lowest profit margin compared to Corporate and Home Office
         even though discount levels are similar across all segments.
         This suggests that the Consumer segment may not be as efficient
         and there is room to improve profitability without increasing discounts.
*/
 -- Who are our highest value customers and which tier do they fall in?
SELECT customer_id, customer_name , total_spent, 
CASE
	WHEN customer_bucket = 4 THEN 'Platinum VIP'
        WHEN customer_bucket = 3 THEN 'Gold'
        WHEN customer_bucket = 2 THEN 'Silver'
        ELSE 'Bronze'
    END as customer_tier
FROM
    (SELECT customer_id, total_spent, customer_name, NTILE(4) OVER (ORDER BY total_spent DESC) as customer_bucket
	FROM 
		(SELECT customer_id,customer_name, SUM(sales) as total_spent
		FROM superstore
		GROUP BY customer_id) as customer_value
	) as bucketed_customer
    ORDER BY total_spent DESC;
    /*
INSIGHT: Customer spending is highly uneven, with a small group of top customers contributing a large portion of total sales.
		 For example, the highest-value customer spends significantly more than the minimum threshold required to be in the top tier,
         while many customers in the lower tier contribute very small amounts.
         This shows that a small group of high-value customers is extremely important for the business.
         Instead of treating all customers the same, the company should focus on retaining these top customers
         through loyalty programs, personalized offers, or special attention, as losing them would have a major impact on revenue.
*/
