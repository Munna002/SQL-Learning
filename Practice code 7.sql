CREATE DEFINER=`root`@`localhost` PROCEDURE `get_n_top_products`(
	in_fiscal_year year,
    in_top_n int
)
BEGIN
	SELECT 
product,
round(sum(net_sales)/1000000,2) as total_net_sales_MLN
FROM gdb0041.net_sales
where fiscal_year =in_fiscal_year
group by product
order by total_net_sales_MLN desc
limit in_top_n;
END