# code for dense rank 
with cte1 as (SELECT 
p.division,
p.product,
sum(sold_quantity) as total_quantity
FROM gdb0041.fact_sales_monthly s
join dim_product p 
on p.product_code = s.product_code
where fiscal_year = 2021
group by p.product,p.division),
cte2 as (
	select *,
	dense_rank() over(partition by division order by total_quantity desc) as drnk
	from cte1)
select *from cte2 where drnk <=3

#code for pre and post invoice discount 
select *,
(1-pre_invoice_discount_pct)*total_gross_price as net_invoice_sale,
(po.discounts_pct+other_deductions_pct) as post_invoice_discount_pct
from sales_preinv_discount s
join fact_post_invoice_deductions po
on s.customer_code = po.customer_code and 
s.product_code = po.product_code and 
s.date = po.date


WITH cte1 as (
select 
s.date, s.product_code, s.customer_code, p.product,  p.variant, c.market,
 s.sold_quantity,g.gross_price, pre.pre_invoice_discount_pct,
round(g.gross_price*s.sold_quantity) as Total_gross_price
from fact_sales_monthly s
join dim_customer c
on s.customer_code = c.customer_code
join dim_product p
on p.product_code = s.product_code
JOIN fact_gross_price g 
on g. product_code = s.product_code and g.fiscal_year= s.fiscal_year
join fact_pre_invoice_deductions pre
on pre.customer_code = s.customer_code and pre.fiscal_year = s.fiscal_year
)
select *,
(Total_gross_price - Total_gross_price*pre_invoice_discount_pct) as net_invoice_sale
from cte1

# code for top 2 rank region gross total in million 

with cte1 as(
SELECT 
s.market, c.region,
round(sum(net_sales)/1000000,2) as total_net_sales_MLN
FROM gdb0041.net_sales s
join dim_customer c
on c.market = s.market
where fiscal_year= 2021
group by s.market, c.region
order by total_net_sales_MLN desc ),
 cte2 as (
select *,
dense_rank() over (partition by region order by total_net_sales_MLN desc) as rnk 
from cte1)

select* from cte2 where rnk<=2


#forecast accuracy code #2021 

create temporary table forecast_accuracy_2021
with forecast_accuracy_err AS (
    SELECT 
        a.customer_code AS customer_code,
        a.fiscal_year as fiscal_year,
        c.market AS market,
        sum(sold_quantity) as total_sold_quantity,
        SUM((forecast_quantity - sold_quantity)) AS net_error,
        SUM((forecast_quantity - sold_quantity)) * 100 / SUM(forecast_quantity) AS net_error_pct,
        SUM(ABS((forecast_quantity - sold_quantity))) AS abs_net_error,
        SUM(ABS((forecast_quantity - sold_quantity))) * 100 / SUM(forecast_quantity) AS abs_net_error_pct
    FROM 
        gdb0041.fact_act_est a
        JOIN dim_customer c ON a.customer_code = c.customer_code
    WHERE 
        a.fiscal_year = 2021
    GROUP BY 
        a.customer_code, c.customer, c.market,a.fiscal_year
)
SELECT e.*,
c.customer,
if( abs_net_error_pct>100,0 ,(100-abs_net_error_pct)) as forecast_accuracy
 FROM forecast_accuracy_err e
 join dim_customer c
 using (customer_code)
 order by forecast_accuracy desc
 
 # code for joining 
