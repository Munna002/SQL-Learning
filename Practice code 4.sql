CREATE DEFINER=`root`@`localhost` PROCEDURE `get_forecast_accuracy`(
	in_fiscal_year int

)
BEGIN
WITH forecast_accuracy_err AS (
    SELECT 
        a.customer_code AS customer_code,
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
        a.fiscal_year = in_fiscal_year
    GROUP BY 
        a.customer_code, c.customer, c.market
)
SELECT e.*,
c.customer,
c.market,
if( abs_net_error_pct>100,0 ,(100-abs_net_error_pct)) as forecast_accuracy
 FROM forecast_accuracy_err e
 join dim_customer c
 using (customer_code)
 order by forecast_accuracy desc;
END