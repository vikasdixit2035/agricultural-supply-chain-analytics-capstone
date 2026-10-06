SET search_path TO agri_capstone;

-- 1) Farm master category normalization
UPDATE dim_farms
SET region = CASE
        WHEN LOWER(TRIM(region))='uttar pradesh' THEN 'Uttar Pradesh'
        ELSE TRIM(region)
    END,
    certification = CASE
        WHEN LOWER(TRIM(certification))='globalgap' THEN 'GlobalG.A.P.'
        ELSE TRIM(certification)
    END,
    supplier_tier = TRIM(supplier_tier);

-- 2) Harvest / procurement corrections
UPDATE fact_harvest_lots
SET purchase_price_inr_per_kg = CASE
        WHEN purchase_price_inr_per_kg > market_reference_price_inr_per_kg*10
        THEN purchase_price_inr_per_kg/100.0
        ELSE purchase_price_inr_per_kg
    END,
    quality_grade = CASE
        WHEN LOWER(TRIM(quality_grade))='grade a' THEN 'A'
        ELSE TRIM(quality_grade)
    END;

-- accepted_qty is a derived field and can be safely reconstructed here.
UPDATE fact_harvest_lots
SET accepted_qty_kg = harvest_qty_kg-rejected_qty_kg
WHERE accepted_qty_kg IS NULL;

-- 3) Remove deliberately duplicated inbound shipment rows.
DELETE FROM fact_inbound_shipments a
USING fact_inbound_shipments b
WHERE a.ctid < b.ctid
  AND a.inbound_shipment_id=b.inbound_shipment_id;

-- 4) Correct order KPI scale and reconstruct missing OTIF.
UPDATE fact_customer_orders
SET fill_rate = CASE WHEN fill_rate>1 THEN fill_rate/100.0 ELSE fill_rate END;

UPDATE fact_customer_orders
SET otif_flag = CASE
        WHEN fill_rate>=0.98 AND actual_delivery_date<=promised_delivery_date THEN 1
        ELSE 0
    END
WHERE otif_flag IS NULL;

-- 5) Quality checks after cleaning.
-- These should return zero rows / violations.
SELECT * FROM fact_customer_orders WHERE fill_rate<0 OR fill_rate>1;
SELECT inbound_shipment_id,COUNT(*)
FROM fact_inbound_shipments
GROUP BY inbound_shipment_id
HAVING COUNT(*)>1;
SELECT * FROM fact_harvest_lots WHERE accepted_qty_kg IS NULL;
