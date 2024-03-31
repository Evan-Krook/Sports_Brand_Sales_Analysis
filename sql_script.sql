########Seeing if there is any null values in the data tables########
#####################################################################
select count(*) from online_sports_rev.traffic;
select 
	count(*) as total_rows,
	SUM(CASE WHEN info.description IS NOT NULL THEN 1 ELSE 0 END) AS count_description,
	SUM(CASE WHEN finance.listing_price IS NOT NULL THEN 1 ELSE 0 END) AS count_listing_price,
	SUM(CASE WHEN traffic.last_visited IS NOT NULL THEN 1 ELSE 0 END) AS count_last_visited
from 
	online_sports_rev.info as info
inner join 
	online_sports_rev.traffic as traffic
on 
	traffic.product_id = info.product_id
inner join 
	online_sports_rev.finance as finance
on 
	finance.product_id = info.product_id;
    
########Pricing Differences Between Nike and Addidas########
############################################################
SELECT 
    brand.brand, 
    CAST(finance.listing_price AS UNSIGNED) AS listing_price, 
    COUNT(finance.product_id) AS product_count
FROM 
    online_sports_rev.brands AS brand
INNER JOIN 
    online_sports_rev.finance AS finance ON finance.product_id = brand.product_id
WHERE 
    brand.brand IN ('Nike', 'Adidas') 
    AND finance.listing_price > 0 
GROUP BY 
    1, 2
ORDER BY 
    listing_price DESC;

########Creating Labels for Poducts Grouped by Price Range and Brand########
############################################################################
select
	brand.brand, count(*), round(sum(finance.revenue),0) as total_revenue,
	case 
		when finance.listing_price < 42 then 'Budget'
        when finance.listing_price >= 42 and finance.listing_price < 74 then 'Average'
        when finance.listing_price >= 74 and finance.listing_price < 129 then 'Expensive'
        else 'Elite' end as price_category
from	
	online_sports_rev.finance as finance
inner join
	online_sports_rev.brands as brand
on
	brand.product_id = finance.product_id
where
	brand.brand IN ('Nike', 'Adidas') 
group by
	brand.brand, price_category
order by
	total_revenue DESC;

########Correlation between Reviews and Revenue########
#######################################################
SELECT
    round((
        SUM((review.reviews - review_mean) * (finance.revenue - revenue_mean)) /
        (COUNT(*) * STDDEV_POP(review.reviews) * STDDEV_POP(finance.revenue))
    ),5) AS review_rev_corr
FROM
    online_sports_rev.reviews AS review
INNER JOIN 
    online_sports_rev.finance AS finance
ON
    finance.product_id = review.product_id
CROSS JOIN
    (
        SELECT 
            AVG(reviews) AS review_mean,
            AVG(revenue) AS revenue_mean
        FROM 
            online_sports_rev.reviews,
            online_sports_rev.finance
    ) AS means;

########Average Rating for Each Description############
#######################################################
with description_lengths as (
select
	info.product_id as product_id,
	length(info.description) as length_description
from
	online_sports_rev.info as info)
select
	case
		when len.length_description > 0 and len.length_description  < 100 then "0-100"
        when len.length_description  >= 100 and len.length_description  < 200 then "100-200"
        when len.length_description  >= 200 and len.length_description  < 300 then "200-300"
        when len.length_description  >= 300 and len.length_description  < 400 then "300-400"
        when len.length_description  >= 400 and len.length_description  < 500 then "400-500"
        when len.length_description  >= 500 and len.length_description  < 600 then "500-600"
        else "Greater Than or Equal to 600" end as description_length_category,
	round(avg(review.reviews),0) as average_reviews,
    round(avg(rating),2) as average_rating
from
	description_lengths as len
inner join 
	online_sports_rev.reviews as review
on
	review.product_id = len.product_id
group by 
	description_length_category
order by
	description_length_category DESC;
	

#############Reviews per Brand per Month###############
#######################################################
select
	brand.brand,
    MONTH(traffic.last_visited) as month,
    count(*)  as num_reviews
from
	online_sports_rev.brands as brand
inner join 
	online_sports_rev.traffic as traffic
on 
	traffic.product_id = brand.product_id
inner join
	online_sports_rev.reviews as review
on
	review.product_id = brand.product_id
group by
	brand.brand, month
having
	brand.brand IN ('Nike', 'Adidas')
	and month is not null
order by brand.brand, month;
    
#####Number of Footwear Product and Average Revenue for Each Brand#####
#######################################################################
With footwear as (
select
	info.description as desc_product, 
    finance.revenue as rev,
    brand.brand as brand
from
	online_sports_rev.brands as brand
inner join
	online_sports_rev.info as info
on 
	info.product_id = brand.product_id
inner join 
	online_sports_rev.finance as finance
on
	finance.product_id = brand.product_id
where
	(info.description LIKE '%shoe%'
    or info.description LIKE '%trainer%'
    or info.description LIKE '%foot%')
    and info.description is not null
)
select 
	brand,
	count(*) as footwear_product_count,
	round(avg(rev),2) as  median_footwear_revenue
from footwear
where
	brand IN ('Nike', 'Adidas')
group by
	brand;

####This is not Grouped By Brand####
####################################    
With footwear as (
select
	info.description as desc_product, 
    finance.revenue as rev,
    brand.brand as brand
from
	online_sports_rev.brands as brand
inner join
	online_sports_rev.info as info
on 
	info.product_id = brand.product_id
inner join 
	online_sports_rev.finance as finance
on
	finance.product_id = brand.product_id
where
	(info.description LIKE '%shoe%'
    or info.description LIKE '%trainer%'
    or info.description LIKE '%foot%')
    and info.description is not null
)
select
	count(*) as footwear_product_count,
	round(avg(rev),2) as  median_footwear_revenue
from 
	footwear
where
	brand IN ('Nike', 'Adidas');

#####Number of Non Footwear Product and Average Revenue for Each Brand#####
###########################################################################
With footwear as (
select
	info.description as desc_product, 
    finance.revenue as rev,
    brand.brand as brand
from
	online_sports_rev.brands as brand
inner join
	online_sports_rev.info as info
on 
	info.product_id = brand.product_id
inner join 
	online_sports_rev.finance as finance
on
	finance.product_id = brand.product_id
where
	(info.description NOT LIKE '%shoe%'
    and info.description NOT LIKE '%trainer%'
    and info.description NOT LIKE '%foot%')
    and info.description is not null
)
select
	brand,
	count(*) as clothing_product_count,
	round(avg(rev),2) as  median_clothing_revenue
from footwear
where
	brand IN ('Nike', 'Adidas')
group by
	brand;
    
####This is not Grouped By Brand####
####################################       
With footwear as (
select
	info.description as desc_product, 
    finance.revenue as rev,
    brand.brand as brand
from
	online_sports_rev.brands as brand
inner join
	online_sports_rev.info as info
on 
	info.product_id = brand.product_id
inner join 
	online_sports_rev.finance as finance
on
	finance.product_id = brand.product_id
where
	(info.description NOT LIKE '%shoe%'
    and info.description NOT LIKE '%trainer%'
    and info.description NOT LIKE '%foot%')
    and info.description is not null
)
select
	count(*) as clothing_product_count,
	round(avg(rev),2) as  median_clothing_revenue
from footwear
where
	brand IN ('Nike', 'Adidas');
