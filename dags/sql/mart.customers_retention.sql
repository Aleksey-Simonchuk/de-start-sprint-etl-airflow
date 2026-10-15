insert into mart.customer_retention (
	new_customers_count,
	returning_customers_count,
	refunded_customer_count,
	period_id, item_id,
	new_customers_revenue,
	returning_customers_revenue,
	customers_refunded
)
with pre_mart_cte as (
	select
		mfs.customer_id,
		mfs.payment_amount,
		count(mfs.customer_id) over (partition by mfs.customer_id, mdc.week_of_year) as cnt_customer_id,
		sum(mfs.payment_amount) over (partition by mfs.item_id, mdc.week_of_year),
		mdc.week_of_year::varchar || 'th week of ' || mdc.year_actual::varchar as period_name,
		mdc.year_actual * 100 + mdc.week_of_year as period_id, -- в родительских таблицах нет такого, придумал свой так, чтобы сортировка работала корректно  
		mfs.item_id as item_id,
		mfs.status
	from mart.f_sales mfs left join mart.d_calendar mdc using(date_id)
),
new_customers_cte as (
select
	distinct(item_id) as item_id,
	period_id,
	count(customer_id) as new_customers_count,
	sum(payment_amount) as new_customers_revenue
from pre_mart_cte
where cnt_customer_id = 1
group by item_id, period_id
),
returning_customers_cte as (
select
	distinct(item_id) as item_id,
	period_id,
	count(customer_id) as returning_customers_count,
	sum(payment_amount)as returning_customers_revenue
from pre_mart_cte
where cnt_customer_id > 1
group by item_id, period_id
),
refunded_customers_cte as (
select
	distinct(item_id) as item_id,
	period_id,
	count(distinct(customer_id)) as refunding_customers_count,
	count(customer_id) as customers_refunded
from pre_mart_cte
where status = 'refunded'
group by item_id, period_id
),
lets_insert_except_1_col_cte as (
select
	distinct pmc.item_id as service_col,
	new_cus.new_customers_count,
	ret_cus.returning_customers_count,
	ref_cus.refunding_customers_count,
	pmc.period_name,
	pmc.period_id,
	pmc.item_id,
	new_cus.new_customers_revenue,
	ret_cus.returning_customers_revenue,
	ref_cus.customers_refunded
from pre_mart_cte as pmc
	left join new_customers_cte as new_cus on(pmc.item_id=new_cus.item_id and pmc.period_id=new_cus.period_id)
	left join returning_customers_cte as ret_cus on(pmc.item_id=ret_cus.item_id and pmc.period_id=ret_cus.period_id)
	left join refunded_customers_cte as ref_cus on(pmc.item_id=ref_cus.item_id and pmc.period_id=ref_cus.period_id)
order by item_id, period_id
)
select
	new_customers_count,
	returning_customers_count,
	refunding_customers_count,
	period_id,
	item_id,
	new_customers_revenue,
	returning_customers_revenue,
	customers_refunded
from lets_insert_except_1_col_cte;