SET search_path TO agri_capstone;

-- ============================================================
-- Agricultural Supply Chain Analytics — 50 Reference Solutions
-- PostgreSQL
-- ============================================================

-- Q01. Profile farms by region, supplier tier, irrigation type and certification.
SELECT region, supplier_tier, irrigation_type, certification,
       COUNT(*) AS farms,
       SUM(hectares) AS hectares
FROM dim_farms
GROUP BY 1,2,3,4
ORDER BY farms DESC;

-- Q02. Calculate total harvest, accepted quantity and procurement spend.
SELECT SUM(harvest_qty_kg) AS harvest_kg,
       SUM(accepted_qty_kg) AS accepted_kg,
       SUM(rejected_qty_kg) AS rejected_kg,
       SUM(accepted_qty_kg * purchase_price_inr_per_kg) AS procurement_spend_inr
FROM fact_harvest_lots;

-- Q03. Calculate yield attainment by product and region.
SELECT h.product_id,
       f.region,
       SUM(h.actual_yield_tonnes) / NULLIF(SUM(h.expected_yield_tonnes),0) AS yield_attainment
FROM fact_harvest_lots h
JOIN dim_farms f USING (farm_id)
GROUP BY 1,2
ORDER BY 1,3;

-- Q04. Identify farms with yield attainment below 80%.
SELECT farm_id,
       COUNT(*) AS lots,
       SUM(actual_yield_tonnes) / NULLIF(SUM(expected_yield_tonnes),0) AS yield_attainment
FROM fact_harvest_lots
GROUP BY farm_id
HAVING SUM(actual_yield_tonnes) / NULLIF(SUM(expected_yield_tonnes),0) < 0.80
ORDER BY yield_attainment;

-- Q05. Calculate quality rejection rate by product.
SELECT product_id,
       SUM(rejected_qty_kg) / NULLIF(SUM(harvest_qty_kg),0) AS rejection_rate,
       SUM(rejected_qty_kg) AS rejected_kg
FROM fact_harvest_lots
GROUP BY product_id
ORDER BY rejection_rate DESC;

-- Q06. Calculate Grade A share by farm and product.
SELECT farm_id,
       product_id,
       COUNT(*) AS lots,
       AVG((quality_grade='A')::int::numeric) AS grade_a_lot_share,
       SUM(accepted_qty_kg) FILTER (WHERE quality_grade='A') /
       NULLIF(SUM(accepted_qty_kg),0) AS grade_a_volume_share
FROM fact_harvest_lots
GROUP BY 1,2
ORDER BY grade_a_volume_share DESC NULLS LAST;

-- Q07. Compare pesticide pass rate by certification.
SELECT f.certification,
       COUNT(*) AS inspected_lots,
       COUNT(*) FILTER (WHERE h.pesticide_test_pass IS NULL) AS missing_tests,
       AVG(h.pesticide_test_pass::int::numeric) AS pesticide_pass_rate
FROM fact_harvest_lots h
JOIN dim_farms f USING (farm_id)
GROUP BY f.certification
ORDER BY pesticide_pass_rate DESC NULLS LAST;

-- Q08. Calculate procurement price variance vs market reference price.
SELECT product_id,
       SUM(accepted_qty_kg * purchase_price_inr_per_kg) / NULLIF(SUM(accepted_qty_kg),0) AS weighted_purchase_price,
       SUM(accepted_qty_kg * market_reference_price_inr_per_kg) / NULLIF(SUM(accepted_qty_kg),0) AS weighted_market_price,
       SUM(accepted_qty_kg * (purchase_price_inr_per_kg-market_reference_price_inr_per_kg)) AS ppv_inr,
       SUM(accepted_qty_kg * (purchase_price_inr_per_kg-market_reference_price_inr_per_kg)) /
       NULLIF(SUM(accepted_qty_kg * market_reference_price_inr_per_kg),0) AS ppv_pct
FROM fact_harvest_lots
GROUP BY product_id
ORDER BY ppv_pct DESC;

-- Q09. Identify farms consistently buying above market.
SELECT farm_id,
       COUNT(*) AS lots,
       AVG((purchase_price_inr_per_kg-market_reference_price_inr_per_kg) /
           NULLIF(market_reference_price_inr_per_kg,0)) AS avg_ppv_pct,
       AVG((purchase_price_inr_per_kg > market_reference_price_inr_per_kg*1.05)::int::numeric) AS share_lots_over_5pct_market
FROM fact_harvest_lots
GROUP BY farm_id
HAVING COUNT(*) >= 5
   AND AVG((purchase_price_inr_per_kg-market_reference_price_inr_per_kg) /
           NULLIF(market_reference_price_inr_per_kg,0)) > 0.05
ORDER BY avg_ppv_pct DESC;

-- Q10. Calculate procurement spend concentration by farm/cooperative.
WITH farm_spend AS (
    SELECT h.farm_id,
           f.cooperative_id,
           SUM(h.accepted_qty_kg*h.purchase_price_inr_per_kg) AS spend_inr
    FROM fact_harvest_lots h
    JOIN dim_farms f USING (farm_id)
    GROUP BY 1,2
), ranked AS (
    SELECT *,
           spend_inr/SUM(spend_inr) OVER() AS total_spend_share,
           SUM(spend_inr) OVER(PARTITION BY cooperative_id) AS cooperative_spend_inr,
           ROW_NUMBER() OVER(ORDER BY spend_inr DESC) AS farm_rank
    FROM farm_spend
)
SELECT farm_id, cooperative_id, spend_inr, total_spend_share,
       cooperative_spend_inr, farm_rank
FROM ranked
ORDER BY spend_inr DESC;

-- Q11. Calculate inbound transport loss rate by carrier.
SELECT carrier_id,
       COUNT(*) AS shipments,
       SUM(transport_loss_kg) AS transport_loss_kg,
       SUM(transport_loss_kg) /
       NULLIF(SUM(received_qty_kg+transport_loss_kg),0) AS transport_loss_rate
FROM fact_inbound_shipments
GROUP BY carrier_id
ORDER BY transport_loss_rate DESC;

-- Q12. Calculate average delay and on-time inbound performance by carrier.
SELECT carrier_id,
       COUNT(*) AS shipments,
       AVG(delay_hours) AS avg_delay_hours,
       AVG((delay_hours<=2)::int::numeric) AS inbound_on_time_rate
FROM fact_inbound_shipments
GROUP BY carrier_id
ORDER BY avg_delay_hours DESC;

-- Q13. Calculate temperature-excursion rate by carrier and storage class.
SELECT i.carrier_id,
       p.storage_class,
       COUNT(*) AS shipments,
       AVG((i.temperature_excursion_hours>2)::int::numeric) AS excursion_rate,
       AVG(i.temperature_excursion_hours) AS avg_excursion_hours
FROM fact_inbound_shipments i
JOIN fact_harvest_lots h USING (lot_id)
JOIN dim_products p USING (product_id)
GROUP BY 1,2
ORDER BY excursion_rate DESC, shipments DESC;

-- Q14. Compare reefer-required shipments by fleet type.
SELECT c.fleet_type,
       i.reefer_required,
       COUNT(*) AS shipments,
       AVG((i.temperature_excursion_hours>2)::int::numeric) AS excursion_rate,
       AVG(i.delay_hours) AS avg_delay_hours,
       SUM(i.transport_loss_kg)/NULLIF(SUM(i.received_qty_kg+i.transport_loss_kg),0) AS loss_rate
FROM fact_inbound_shipments i
JOIN dim_carriers c USING (carrier_id)
GROUP BY 1,2
ORDER BY 1,2;

-- Q15. Calculate freight cost per kg and per tonne-km.
SELECT carrier_id,
       SUM(freight_cost_inr)/NULLIF(SUM(received_qty_kg),0) AS freight_inr_per_received_kg,
       SUM(freight_cost_inr) /
       NULLIF(SUM(distance_km*(received_qty_kg+transport_loss_kg)/1000.0),0) AS inr_per_tonne_km
FROM fact_inbound_shipments
GROUP BY carrier_id
ORDER BY freight_inr_per_received_kg DESC;

-- Q16. Identify lanes/shipments with high freight cost and high delay.
WITH x AS (
    SELECT i.inbound_shipment_id,
           h.farm_id,
           f.region AS source_region,
           i.warehouse_id,
           w.region AS destination_region,
           i.carrier_id,
           i.distance_km,
           i.delay_hours,
           i.freight_cost_inr/NULLIF(i.received_qty_kg,0) AS freight_inr_per_kg
    FROM fact_inbound_shipments i
    JOIN fact_harvest_lots h USING (lot_id)
    JOIN dim_farms f USING (farm_id)
    JOIN dim_warehouses w USING (warehouse_id)
), cut AS (
    SELECT *,
           PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY freight_inr_per_kg) OVER() AS p75_freight,
           PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY delay_hours) OVER() AS p75_delay
    FROM x
)
SELECT *
FROM cut
WHERE freight_inr_per_kg >= p75_freight
  AND delay_hours >= p75_delay
ORDER BY freight_inr_per_kg DESC, delay_hours DESC;

-- Q17. Calculate spoilage quantity and value by warehouse.
SELECT i.warehouse_id,
       SUM(i.estimated_spoilage_qty_kg) AS spoilage_kg,
       SUM(i.estimated_spoilage_qty_kg*p.baseline_market_price_inr_per_kg) AS spoilage_value_inr
FROM fact_inventory_lot_status i
JOIN dim_products p USING (product_id)
GROUP BY i.warehouse_id
ORDER BY spoilage_value_inr DESC;

-- Q18. Calculate spoilage rate by product and storage class.
SELECT i.product_id,
       p.storage_class,
       SUM(i.estimated_spoilage_qty_kg) /
       NULLIF(SUM(i.remaining_qty_kg),0) AS spoilage_rate,
       SUM(i.estimated_spoilage_qty_kg) AS spoilage_kg
FROM fact_inventory_lot_status i
JOIN dim_products p USING (product_id)
GROUP BY 1,2
ORDER BY spoilage_rate DESC NULLS LAST;

-- Q19. Identify expired and critical-shelf-life inventory.
SELECT warehouse_id,
       product_id,
       COUNT(*) FILTER (WHERE inventory_status='Expired') AS expired_lots,
       COUNT(*) FILTER (WHERE inventory_status='Critical Shelf Life') AS critical_lots,
       SUM(usable_closing_qty_kg) FILTER (WHERE inventory_status IN ('Expired','Critical Shelf Life')) AS risk_stock_kg
FROM fact_inventory_lot_status
GROUP BY 1,2
HAVING COUNT(*) FILTER (WHERE inventory_status IN ('Expired','Critical Shelf Life')) > 0
ORDER BY risk_stock_kg DESC NULLS LAST;

-- Q20. Calculate inventory value at risk by warehouse/product.
SELECT i.warehouse_id,
       i.product_id,
       SUM(i.usable_closing_qty_kg*p.baseline_market_price_inr_per_kg) AS inventory_value_at_risk_inr
FROM fact_inventory_lot_status i
JOIN dim_products p USING (product_id)
WHERE i.inventory_status IN ('At Risk','Critical Shelf Life','Expired')
GROUP BY 1,2
ORDER BY inventory_value_at_risk_inr DESC;

-- Q21. Measure average inventory age by product.
SELECT product_id,
       AVG(age_days_at_end) AS avg_inventory_age_days,
       PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY age_days_at_end) AS p90_age_days
FROM fact_inventory_lot_status
WHERE usable_closing_qty_kg>0
GROUP BY product_id
ORDER BY avg_inventory_age_days DESC;

-- Q22. Identify products where ageing exceeds target shelf-life thresholds.
SELECT i.product_id,
       p.nominal_shelf_life_days,
       AVG(i.age_days_at_end) AS avg_age_days,
       AVG((i.age_days_at_end > 0.60*p.nominal_shelf_life_days)::int::numeric) AS share_lots_over_60pct_shelf_life
FROM fact_inventory_lot_status i
JOIN dim_products p USING (product_id)
WHERE i.usable_closing_qty_kg>0
GROUP BY i.product_id,p.nominal_shelf_life_days
HAVING AVG(i.age_days_at_end) > 0.60*p.nominal_shelf_life_days
ORDER BY avg_age_days DESC;

-- Q23. Calculate customer fill rate by product/customer type.
SELECT o.product_id,
       c.customer_type,
       SUM(o.delivered_qty_kg)/NULLIF(SUM(o.ordered_qty_kg),0) AS weighted_fill_rate,
       AVG(o.fill_rate) AS avg_order_fill_rate,
       COUNT(*) AS orders
FROM fact_customer_orders o
JOIN dim_customers c USING (customer_id)
GROUP BY 1,2
ORDER BY weighted_fill_rate;

-- Q24. Calculate OTIF by customer and service tier.
SELECT o.customer_id,
       c.service_tier,
       COUNT(*) AS orders,
       AVG(o.otif_flag::numeric) AS otif_rate
FROM fact_customer_orders o
JOIN dim_customers c USING (customer_id)
GROUP BY 1,2
ORDER BY otif_rate, orders DESC;

-- Q25. Identify customers with service below target fill rate.
SELECT o.customer_id,
       c.customer_type,
       c.service_tier,
       c.target_fill_rate,
       SUM(o.delivered_qty_kg)/NULLIF(SUM(o.ordered_qty_kg),0) AS actual_fill_rate,
       c.target_fill_rate - SUM(o.delivered_qty_kg)/NULLIF(SUM(o.ordered_qty_kg),0) AS gap_to_target
FROM fact_customer_orders o
JOIN dim_customers c USING (customer_id)
GROUP BY o.customer_id,c.customer_type,c.service_tier,c.target_fill_rate
HAVING SUM(o.delivered_qty_kg)/NULLIF(SUM(o.ordered_qty_kg),0) < c.target_fill_rate
ORDER BY gap_to_target DESC;

-- Q26. Calculate customer rejection rate by product.
SELECT product_id,
       SUM(customer_rejected_qty_kg)/NULLIF(SUM(delivered_qty_kg),0) AS customer_rejection_rate,
       SUM(customer_rejected_qty_kg) AS rejected_kg
FROM fact_customer_orders
GROUP BY product_id
ORDER BY customer_rejection_rate DESC;

-- Q27. Estimate sales lost from unfilled demand.
SELECT product_id,
       SUM(GREATEST(ordered_qty_kg-delivered_qty_kg,0)) AS unfilled_qty_kg,
       SUM(GREATEST(ordered_qty_kg-delivered_qty_kg,0)*unit_sell_price_inr_per_kg) AS estimated_unfilled_sales_inr
FROM fact_customer_orders
GROUP BY product_id
ORDER BY estimated_unfilled_sales_inr DESC;

-- Q28. Calculate gross margin by order using landed cost.
WITH lot_cost AS (
    SELECT a.order_id,
           a.allocated_qty_kg,
           h.purchase_price_inr_per_kg,
           i.freight_cost_inr/NULLIF(i.received_qty_kg+i.transport_loss_kg,0) AS inbound_freight_inr_per_kg
    FROM fact_lot_allocations a
    JOIN fact_harvest_lots h USING (lot_id)
    JOIN fact_inbound_shipments i USING (lot_id)
    WHERE a.lot_id IS NOT NULL
), order_cost AS (
    SELECT order_id,
           SUM(allocated_qty_kg*(purchase_price_inr_per_kg+inbound_freight_inr_per_kg)) AS landed_cost_inr
    FROM lot_cost
    GROUP BY order_id
)
SELECT o.order_id,
       o.net_sales_inr,
       c.landed_cost_inr,
       o.net_sales_inr-c.landed_cost_inr AS gross_margin_inr,
       (o.net_sales_inr-c.landed_cost_inr)/NULLIF(o.net_sales_inr,0) AS gross_margin_pct
FROM fact_customer_orders o
JOIN order_cost c USING (order_id)
ORDER BY gross_margin_inr DESC;

-- Q29. Rank products by gross margin percentage.
WITH lot_cost AS (
    SELECT a.order_id,
           a.allocated_qty_kg,
           h.purchase_price_inr_per_kg,
           i.freight_cost_inr/NULLIF(i.received_qty_kg+i.transport_loss_kg,0) AS freight_per_kg
    FROM fact_lot_allocations a
    JOIN fact_harvest_lots h USING (lot_id)
    JOIN fact_inbound_shipments i USING (lot_id)
    WHERE a.lot_id IS NOT NULL
), cost_by_order AS (
    SELECT order_id,
           SUM(allocated_qty_kg*(purchase_price_inr_per_kg+freight_per_kg)) AS landed_cost_inr
    FROM lot_cost
    GROUP BY order_id
)
SELECT o.product_id,
       SUM(o.net_sales_inr) AS net_sales_inr,
       SUM(c.landed_cost_inr) AS landed_cost_inr,
       SUM(o.net_sales_inr-c.landed_cost_inr) AS gross_margin_inr,
       SUM(o.net_sales_inr-c.landed_cost_inr)/NULLIF(SUM(o.net_sales_inr),0) AS gross_margin_pct
FROM fact_customer_orders o
JOIN cost_by_order c USING (order_id)
GROUP BY o.product_id
ORDER BY gross_margin_pct DESC;

-- Q30. Calculate contribution of temperature excursions to customer rejection.
SELECT CASE WHEN source_lot_temperature_excursion_hours>2 THEN 'Excursion' ELSE 'No Excursion' END AS cold_chain_group,
       COUNT(*) AS shipments,
       SUM(customer_rejected_qty_kg)/NULLIF(SUM(delivered_qty_kg),0) AS customer_rejection_rate,
       AVG(source_lot_temperature_excursion_hours) AS avg_excursion_hours
FROM fact_outbound_shipments
GROUP BY 1
ORDER BY customer_rejection_rate DESC;

-- Q31. Calculate days of shelf life remaining at dispatch.
SELECT a.product_id,
       AVG(a.lot_expiry_date-o.order_date) AS avg_days_shelf_life_remaining,
       PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY (a.lot_expiry_date-o.order_date)) AS p10_days_remaining,
       COUNT(*) AS allocated_orders
FROM fact_lot_allocations a
JOIN fact_customer_orders o USING (order_id)
WHERE a.lot_id IS NOT NULL
GROUP BY a.product_id
ORDER BY avg_days_shelf_life_remaining;

-- Q32. Identify aged dispatches / FEFO shelf-life risk.
SELECT a.order_id,
       a.lot_id,
       a.product_id,
       a.warehouse_id,
       (a.lot_expiry_date-o.order_date) AS days_remaining_at_dispatch,
       (o.order_date-a.lot_harvest_date) AS lot_age_days,
       a.allocated_qty_kg
FROM fact_lot_allocations a
JOIN fact_customer_orders o USING (order_id)
WHERE a.lot_id IS NOT NULL
  AND (a.lot_expiry_date-o.order_date) <= 7
ORDER BY days_remaining_at_dispatch, allocated_qty_kg DESC;

-- Q33. Build complete farm-to-customer lineage for a selected lot.
-- Replace the literal below with any lot_id, for example one returned from Q32.
SELECT a.lot_id,
       h.farm_id,
       f.farm_name,
       h.product_id,
       h.harvest_date,
       i.inbound_shipment_id,
       i.warehouse_id,
       i.carrier_id AS inbound_carrier_id,
       a.order_id,
       o.customer_id,
       c.customer_name,
       o.order_date,
       ob.outbound_shipment_id,
       ob.carrier_id AS outbound_carrier_id,
       ob.actual_delivery_date,
       a.allocated_qty_kg
FROM fact_lot_allocations a
JOIN fact_harvest_lots h USING (lot_id)
JOIN dim_farms f USING (farm_id)
JOIN fact_inbound_shipments i USING (lot_id)
JOIN fact_customer_orders o USING (order_id)
JOIN dim_customers c USING (customer_id)
JOIN fact_outbound_shipments ob USING (order_id)
WHERE a.lot_id='LOT0000001'
ORDER BY o.order_date,o.order_id;

-- Q34. Find every order/customer affected by a simulated recall lot.
-- Replace the lot ID with the lot used for your recall simulation.
SELECT a.lot_id,
       o.order_id,
       o.customer_id,
       c.customer_name,
       c.customer_type,
       o.order_date,
       o.actual_delivery_date,
       a.allocated_qty_kg,
       o.customer_rejected_qty_kg
FROM fact_lot_allocations a
JOIN fact_customer_orders o USING (order_id)
JOIN dim_customers c USING (customer_id)
WHERE a.lot_id='LOT0000001'
ORDER BY o.order_date,o.order_id;

-- Q35. Calculate monthly demand by product.
SELECT DATE_TRUNC('month',order_date)::date AS month,
       product_id,
       SUM(ordered_qty_kg) AS demand_kg,
       COUNT(*) AS orders
FROM fact_customer_orders
GROUP BY 1,2
ORDER BY 1,2;

-- Q36. Build forecast error metrics for the holdout period.
-- Reference SQL model: 3-month moving-average forecast; final 3 months are the holdout.
WITH monthly AS (
    SELECT DATE_TRUNC('month',order_date)::date AS month,
           product_id,
           SUM(ordered_qty_kg) AS actual_demand_kg
    FROM fact_customer_orders
    GROUP BY 1,2
), fc AS (
    SELECT *,
           AVG(actual_demand_kg) OVER(
               PARTITION BY product_id ORDER BY month
               ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
           ) AS forecast_demand_kg,
           DENSE_RANK() OVER(ORDER BY month DESC) AS month_rank_desc
    FROM monthly
)
SELECT month,product_id,actual_demand_kg,forecast_demand_kg,
       actual_demand_kg-forecast_demand_kg AS error_kg,
       ABS(actual_demand_kg-forecast_demand_kg) AS abs_error_kg,
       ABS(actual_demand_kg-forecast_demand_kg)/NULLIF(actual_demand_kg,0) AS ape
FROM fc
WHERE month_rank_desc<=3
  AND forecast_demand_kg IS NOT NULL
ORDER BY month,product_id;

-- Q37. Calculate WAPE by product.
WITH monthly AS (
    SELECT DATE_TRUNC('month',order_date)::date AS month,
           product_id,
           SUM(ordered_qty_kg) AS actual_demand_kg
    FROM fact_customer_orders
    GROUP BY 1,2
), fc AS (
    SELECT *,
           AVG(actual_demand_kg) OVER(
               PARTITION BY product_id ORDER BY month
               ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
           ) AS forecast_demand_kg,
           DENSE_RANK() OVER(ORDER BY month DESC) AS month_rank_desc
    FROM monthly
)
SELECT product_id,
       SUM(ABS(actual_demand_kg-forecast_demand_kg))/NULLIF(SUM(actual_demand_kg),0) AS wape
FROM fc
WHERE month_rank_desc<=3
  AND forecast_demand_kg IS NOT NULL
GROUP BY product_id
ORDER BY wape;

-- Q38. Calculate safety stock using demand variability and lead time.
-- Assumes 95% service level (z = 1.645).
WITH daily_demand AS (
    SELECT order_date,
           product_id,
           SUM(ordered_qty_kg) AS demand_kg
    FROM fact_customer_orders
    GROUP BY 1,2
), demand_stats AS (
    SELECT product_id,
           AVG(demand_kg) AS avg_daily_demand_kg,
           STDDEV_SAMP(demand_kg) AS std_daily_demand_kg
    FROM daily_demand
    GROUP BY product_id
), lead_time AS (
    SELECT h.product_id,
           AVG(i.actual_transit_hours/24.0) AS avg_lead_time_days
    FROM fact_inbound_shipments i
    JOIN fact_harvest_lots h USING (lot_id)
    GROUP BY h.product_id
)
SELECT d.product_id,
       d.avg_daily_demand_kg,
       d.std_daily_demand_kg,
       l.avg_lead_time_days,
       1.645*d.std_daily_demand_kg*SQRT(GREATEST(l.avg_lead_time_days,0.01)) AS safety_stock_kg
FROM demand_stats d
JOIN lead_time l USING (product_id)
ORDER BY safety_stock_kg DESC;

-- Q39. Calculate reorder points by product.
WITH daily_demand AS (
    SELECT order_date,
           product_id,
           SUM(ordered_qty_kg) AS demand_kg
    FROM fact_customer_orders
    GROUP BY 1,2
), demand_stats AS (
    SELECT product_id,
           AVG(demand_kg) AS avg_daily_demand_kg,
           STDDEV_SAMP(demand_kg) AS std_daily_demand_kg
    FROM daily_demand
    GROUP BY product_id
), lead_time AS (
    SELECT h.product_id,
           AVG(i.actual_transit_hours/24.0) AS avg_lead_time_days
    FROM fact_inbound_shipments i
    JOIN fact_harvest_lots h USING (lot_id)
    GROUP BY h.product_id
)
SELECT d.product_id,
       d.avg_daily_demand_kg,
       l.avg_lead_time_days,
       1.645*d.std_daily_demand_kg*SQRT(GREATEST(l.avg_lead_time_days,0.01)) AS safety_stock_kg,
       d.avg_daily_demand_kg*l.avg_lead_time_days +
       1.645*d.std_daily_demand_kg*SQRT(GREATEST(l.avg_lead_time_days,0.01)) AS reorder_point_kg
FROM demand_stats d
JOIN lead_time l USING (product_id)
ORDER BY reorder_point_kg DESC;

-- Q40. Compare safety stock with perishability / shelf life.
WITH daily_demand AS (
    SELECT order_date,product_id,SUM(ordered_qty_kg) AS demand_kg
    FROM fact_customer_orders
    GROUP BY 1,2
), ds AS (
    SELECT product_id,AVG(demand_kg) AS avg_daily_demand_kg,STDDEV_SAMP(demand_kg) AS std_daily_demand_kg
    FROM daily_demand
    GROUP BY product_id
), lt AS (
    SELECT h.product_id,AVG(i.actual_transit_hours/24.0) AS avg_lead_time_days
    FROM fact_inbound_shipments i
    JOIN fact_harvest_lots h USING (lot_id)
    GROUP BY h.product_id
), ss AS (
    SELECT ds.product_id,
           1.645*ds.std_daily_demand_kg*SQRT(GREATEST(lt.avg_lead_time_days,0.01)) AS safety_stock_kg,
           ds.avg_daily_demand_kg
    FROM ds JOIN lt USING (product_id)
)
SELECT ss.product_id,
       p.perishability_rank,
       p.nominal_shelf_life_days,
       ss.safety_stock_kg,
       ss.safety_stock_kg/NULLIF(ss.avg_daily_demand_kg,0) AS safety_stock_days,
       (ss.safety_stock_kg/NULLIF(ss.avg_daily_demand_kg,0))/NULLIF(p.nominal_shelf_life_days,0) AS safety_stock_as_share_of_shelf_life
FROM ss
JOIN dim_products p USING (product_id)
ORDER BY safety_stock_as_share_of_shelf_life DESC;

-- Q41. Calculate supplier performance score using yield, quality, price and compliance.
WITH farm_metrics AS (
    SELECT farm_id,
           SUM(actual_yield_tonnes)/NULLIF(SUM(expected_yield_tonnes),0) AS yield_attainment,
           1-SUM(rejected_qty_kg)/NULLIF(SUM(harvest_qty_kg),0) AS quality_acceptance,
           AVG(pesticide_test_pass::int::numeric) AS compliance_rate,
           AVG(LEAST(1.0, market_reference_price_inr_per_kg/NULLIF(purchase_price_inr_per_kg,0))) AS price_score,
           SUM(accepted_qty_kg*purchase_price_inr_per_kg) AS procurement_spend_inr
    FROM fact_harvest_lots
    GROUP BY farm_id
)
SELECT farm_id,
       yield_attainment,quality_acceptance,compliance_rate,price_score,procurement_spend_inr,
       100*(0.30*LEAST(yield_attainment,1.0)
           +0.30*quality_acceptance
           +0.25*COALESCE(compliance_rate,0)
           +0.15*price_score) AS supplier_score
FROM farm_metrics
ORDER BY supplier_score DESC;

-- Q42. Rank high-risk suppliers by procurement exposure.
WITH score AS (
    SELECT farm_id,
           SUM(accepted_qty_kg*purchase_price_inr_per_kg) AS procurement_spend_inr,
           SUM(actual_yield_tonnes)/NULLIF(SUM(expected_yield_tonnes),0) AS yield_attainment,
           SUM(rejected_qty_kg)/NULLIF(SUM(harvest_qty_kg),0) AS rejection_rate,
           AVG(pesticide_test_pass::int::numeric) AS compliance_rate,
           AVG((purchase_price_inr_per_kg-market_reference_price_inr_per_kg)/NULLIF(market_reference_price_inr_per_kg,0)) AS avg_ppv_pct
    FROM fact_harvest_lots
    GROUP BY farm_id
), risk AS (
    SELECT *,
           100*(0.30*GREATEST(0,1-yield_attainment)
               +0.30*rejection_rate
               +0.25*(1-COALESCE(compliance_rate,0))
               +0.15*GREATEST(avg_ppv_pct,0)) AS risk_score
    FROM score
)
SELECT *, procurement_spend_inr*risk_score/100.0 AS risk_weighted_procurement_exposure_inr
FROM risk
ORDER BY risk_weighted_procurement_exposure_inr DESC;

-- Q43. Calculate carrier cold-chain score.
WITH c AS (
    SELECT carrier_id,
           AVG(LEAST(delay_hours/24.0,1.0)) AS delay_penalty,
           AVG((temperature_excursion_hours>2)::int::numeric) AS excursion_rate,
           SUM(transport_loss_kg)/NULLIF(SUM(received_qty_kg+transport_loss_kg),0) AS loss_rate,
           SUM(freight_cost_inr)/NULLIF(SUM(received_qty_kg),0) AS freight_inr_per_kg
    FROM fact_inbound_shipments
    GROUP BY carrier_id
), norm AS (
    SELECT *,
           freight_inr_per_kg/NULLIF(MAX(freight_inr_per_kg) OVER(),0) AS freight_cost_index
    FROM c
)
SELECT carrier_id,delay_penalty,excursion_rate,loss_rate,freight_inr_per_kg,
       100*(1-(0.25*LEAST(delay_penalty,1)
              +0.35*LEAST(excursion_rate,1)
              +0.30*LEAST(loss_rate*5,1)
              +0.10*LEAST(freight_cost_index,1))) AS carrier_cold_chain_score
FROM norm
ORDER BY carrier_cold_chain_score DESC;

-- Q44. Rank warehouses by spoilage + shelf-life risk.
WITH w AS (
    SELECT warehouse_id,
           SUM(estimated_spoilage_qty_kg) AS spoilage_kg,
           SUM(remaining_qty_kg) AS remaining_qty_kg,
           SUM(usable_closing_qty_kg) FILTER (WHERE inventory_status IN ('Expired','Critical Shelf Life','At Risk')) AS shelf_life_risk_kg,
           SUM(usable_closing_qty_kg) AS usable_closing_qty_kg
    FROM fact_inventory_lot_status
    GROUP BY warehouse_id
)
SELECT warehouse_id,
       spoilage_kg/NULLIF(remaining_qty_kg,0) AS spoilage_rate,
       shelf_life_risk_kg/NULLIF(usable_closing_qty_kg,0) AS shelf_life_risk_rate,
       100*(0.60*LEAST(spoilage_kg/NULLIF(remaining_qty_kg,0),1)
           +0.40*LEAST(shelf_life_risk_kg/NULLIF(usable_closing_qty_kg,0),1)) AS warehouse_risk_score
FROM w
ORDER BY warehouse_risk_score DESC NULLS LAST;

-- Q45. Compare weather-risk months with yield attainment.
SELECT w.weather_risk_flag,
       COUNT(*) AS lots,
       SUM(h.actual_yield_tonnes)/NULLIF(SUM(h.expected_yield_tonnes),0) AS yield_attainment
FROM fact_harvest_lots h
JOIN dim_farms f USING (farm_id)
JOIN fact_weather_monthly w
  ON w.region=f.region
 AND w.month=DATE_TRUNC('month',h.harvest_date)::date
GROUP BY w.weather_risk_flag
ORDER BY yield_attainment;

-- Q46. Compare irrigation type with yield stability.
SELECT f.irrigation_type,
       AVG(h.actual_yield_tonnes/h.expected_yield_tonnes) AS avg_yield_attainment,
       STDDEV_SAMP(h.actual_yield_tonnes/h.expected_yield_tonnes) AS yield_variability,
       COUNT(*) AS lots
FROM fact_harvest_lots h
JOIN dim_farms f USING (farm_id)
GROUP BY f.irrigation_type
ORDER BY yield_variability;

-- Q47. Calculate working-capital inventory exposure by product.
SELECT i.product_id,
       SUM(i.usable_closing_qty_kg) AS usable_closing_qty_kg,
       SUM(i.usable_closing_qty_kg*p.baseline_market_price_inr_per_kg) AS closing_inventory_value_inr,
       SUM(i.usable_closing_qty_kg*p.baseline_market_price_inr_per_kg)
         FILTER (WHERE i.inventory_status IN ('At Risk','Critical Shelf Life','Expired')) AS risk_inventory_value_inr
FROM fact_inventory_lot_status i
JOIN dim_products p USING (product_id)
GROUP BY i.product_id
ORDER BY closing_inventory_value_inr DESC;

-- Q48. Quantify addressable spoilage, service and quality opportunity pools.
SELECT 'Cold-chain spoilage exposure' AS opportunity,
       SUM(i.estimated_spoilage_qty_kg*p.baseline_market_price_inr_per_kg)
         FILTER (WHERE p.storage_class IN ('Cold','Cool') AND i.temperature_excursion_hours>2) AS addressable_pool_inr
FROM fact_inventory_lot_status i
JOIN dim_products p USING (product_id)
UNION ALL
SELECT 'Supplier quality rejection',
       SUM(rejected_qty_kg*purchase_price_inr_per_kg)
FROM fact_harvest_lots
UNION ALL
SELECT 'Unfilled customer demand',
       SUM(GREATEST(ordered_qty_kg-delivered_qty_kg,0)*unit_sell_price_inr_per_kg)
FROM fact_customer_orders
UNION ALL
SELECT 'Expiry / spoilage exposure',
       SUM(i.estimated_spoilage_qty_kg*p.baseline_market_price_inr_per_kg)
FROM fact_inventory_lot_status i
JOIN dim_products p USING (product_id);

-- Q49. Create an executive supply-chain scorecard.
SELECT
    (SELECT SUM(accepted_qty_kg*purchase_price_inr_per_kg) FROM fact_harvest_lots) AS procurement_spend_inr,
    (SELECT SUM(actual_yield_tonnes)/NULLIF(SUM(expected_yield_tonnes),0) FROM fact_harvest_lots) AS yield_attainment,
    (SELECT SUM(rejected_qty_kg)/NULLIF(SUM(harvest_qty_kg),0) FROM fact_harvest_lots) AS quality_rejection_rate,
    (SELECT SUM(transport_loss_kg)/NULLIF(SUM(received_qty_kg+transport_loss_kg),0) FROM fact_inbound_shipments) AS inbound_loss_rate,
    (SELECT AVG((temperature_excursion_hours>2)::int::numeric) FROM fact_inbound_shipments WHERE reefer_required) AS cold_chain_excursion_rate,
    (SELECT SUM(estimated_spoilage_qty_kg)/NULLIF(SUM(remaining_qty_kg),0) FROM fact_inventory_lot_status) AS spoilage_rate,
    (SELECT SUM(delivered_qty_kg)/NULLIF(SUM(ordered_qty_kg),0) FROM fact_customer_orders) AS weighted_fill_rate,
    (SELECT AVG(otif_flag::numeric) FROM fact_customer_orders) AS otif,
    (SELECT SUM(customer_rejected_qty_kg)/NULLIF(SUM(delivered_qty_kg),0) FROM fact_customer_orders) AS customer_rejection_rate;

-- Q50. Rank management interventions by low/base/high estimated financial impact.
WITH pools AS (
    SELECT 'Cold-chain excursion reduction' AS initiative,
           SUM(i.estimated_spoilage_qty_kg*p.baseline_market_price_inr_per_kg)
             FILTER (WHERE p.storage_class IN ('Cold','Cool') AND i.temperature_excursion_hours>2) AS pool_inr,
           0.08::numeric AS low_capture,0.18::numeric AS base_capture,0.30::numeric AS high_capture
    FROM fact_inventory_lot_status i JOIN dim_products p USING(product_id)
    UNION ALL
    SELECT 'Supplier quality improvement',
           SUM(rejected_qty_kg*purchase_price_inr_per_kg),0.06,0.12,0.20
    FROM fact_harvest_lots
    UNION ALL
    SELECT 'Fill-rate recovery',
           SUM(GREATEST(ordered_qty_kg-delivered_qty_kg,0)*unit_sell_price_inr_per_kg),0.10,0.25,0.40
    FROM fact_customer_orders
    UNION ALL
    SELECT 'Inventory expiry reduction',
           SUM(i.estimated_spoilage_qty_kg*p.baseline_market_price_inr_per_kg),0.05,0.12,0.22
    FROM fact_inventory_lot_status i JOIN dim_products p USING(product_id)
)
SELECT initiative,pool_inr,
       pool_inr*low_capture AS low_impact_inr,
       pool_inr*base_capture AS base_impact_inr,
       pool_inr*high_capture AS high_impact_inr,
       RANK() OVER(ORDER BY pool_inr*base_capture DESC) AS base_case_priority_rank
FROM pools
ORDER BY base_case_priority_rank;
