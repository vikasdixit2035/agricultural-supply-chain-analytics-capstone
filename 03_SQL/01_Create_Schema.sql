CREATE SCHEMA IF NOT EXISTS agri_capstone;
SET search_path TO agri_capstone;

CREATE TABLE dim_farms (
  farm_id VARCHAR(20) PRIMARY KEY,
  farm_name VARCHAR(100),
  region VARCHAR(60),
  cooperative_id VARCHAR(20),
  supplier_tier VARCHAR(30),
  hectares NUMERIC(12,2),
  irrigation_type VARCHAR(30),
  certification VARCHAR(40),
  primary_product_id VARCHAR(30),
  reliability_score_source NUMERIC(8,4),
  quality_capability_source NUMERIC(8,4),
  digital_maturity_score NUMERIC(8,4)
);

CREATE TABLE dim_products (
  product_id VARCHAR(30) PRIMARY KEY,
  product_name VARCHAR(80),
  category VARCHAR(30),
  storage_class VARCHAR(30),
  nominal_shelf_life_days INTEGER,
  normal_shrinkage_pct NUMERIC(8,4),
  baseline_market_price_inr_per_kg NUMERIC(12,2),
  perishability_rank INTEGER
);

CREATE TABLE dim_warehouses (
  warehouse_id VARCHAR(20) PRIMARY KEY,
  warehouse_name VARCHAR(100),
  region VARCHAR(60),
  warehouse_type VARCHAR(30),
  capacity_tonnes NUMERIC(14,2),
  cold_capacity_tonnes NUMERIC(14,2),
  target_inventory_days INTEGER
);

CREATE TABLE dim_carriers (
  carrier_id VARCHAR(20) PRIMARY KEY,
  carrier_name VARCHAR(80),
  fleet_type VARCHAR(30),
  contract_rate_inr_per_tonne_km NUMERIC(12,2),
  base_reliability NUMERIC(8,4)
);

CREATE TABLE dim_customers (
  customer_id VARCHAR(20) PRIMARY KEY,
  customer_name VARCHAR(80),
  customer_type VARCHAR(40),
  region VARCHAR(60),
  service_tier VARCHAR(10),
  target_fill_rate NUMERIC(8,4)
);

CREATE TABLE fact_harvest_lots (
  lot_id VARCHAR(30) PRIMARY KEY,
  farm_id VARCHAR(20),
  product_id VARCHAR(30),
  harvest_date DATE,
  lot_area_hectares NUMERIC(12,2),
  expected_yield_tonnes NUMERIC(14,2),
  actual_yield_tonnes NUMERIC(14,2),
  harvest_qty_kg NUMERIC(16,2),
  market_reference_price_inr_per_kg NUMERIC(12,2),
  purchase_price_inr_per_kg NUMERIC(12,2),
  quality_grade VARCHAR(20),
  moisture_measure NUMERIC(12,2),
  brix_score NUMERIC(12,2),
  pesticide_test_pass BOOLEAN,
  accepted_qty_kg NUMERIC(16,2),
  rejected_qty_kg NUMERIC(16,2),
  expiry_date DATE
);

CREATE TABLE fact_quality_inspections (
  inspection_id VARCHAR(30) PRIMARY KEY,
  lot_id VARCHAR(30),
  farm_id VARCHAR(20),
  product_id VARCHAR(30),
  harvest_date DATE,
  quality_grade VARCHAR(20),
  moisture_measure NUMERIC(12,2),
  brix_score NUMERIC(12,2),
  pesticide_test_pass BOOLEAN,
  accepted_qty_kg NUMERIC(16,2),
  rejected_qty_kg NUMERIC(16,2),
  inspection_status VARCHAR(20),
  quality_hold_hours NUMERIC(12,2)
);

CREATE TABLE fact_inbound_shipments (
  inbound_shipment_id VARCHAR(30),
  lot_id VARCHAR(30),
  warehouse_id VARCHAR(20),
  carrier_id VARCHAR(20),
  dispatch_date DATE,
  distance_km NUMERIC(12,2),
  scheduled_transit_hours NUMERIC(12,2),
  actual_transit_hours NUMERIC(12,2),
  delay_hours NUMERIC(12,2),
  reefer_required BOOLEAN,
  temperature_excursion_hours NUMERIC(12,2),
  freight_cost_inr NUMERIC(16,2),
  received_qty_kg NUMERIC(16,2),
  transport_loss_kg NUMERIC(16,2),
  warehouse_receipt_date TIMESTAMP
);

CREATE TABLE fact_inventory_lot_status (
  lot_id VARCHAR(30),
  product_id VARCHAR(30),
  warehouse_id VARCHAR(20),
  receipt_datetime TIMESTAMP,
  expiry_date DATE,
  received_qty_kg NUMERIC(16,2),
  temperature_excursion_hours NUMERIC(12,2),
  allocated_qty_kg NUMERIC(16,2),
  remaining_qty_kg NUMERIC(16,2),
  age_days_at_end INTEGER,
  estimated_spoilage_qty_kg NUMERIC(16,2),
  usable_closing_qty_kg NUMERIC(16,2),
  days_to_expiry_at_end INTEGER,
  inventory_status VARCHAR(30)
);

CREATE TABLE fact_customer_orders (
  order_id VARCHAR(30) PRIMARY KEY,
  customer_id VARCHAR(20),
  order_date DATE,
  product_id VARCHAR(30),
  ordered_qty_kg NUMERIC(16,2),
  unit_sell_price_inr_per_kg NUMERIC(12,2),
  promised_delivery_date DATE,
  delivered_qty_kg NUMERIC(16,2),
  actual_delivery_date DATE,
  customer_rejected_qty_kg NUMERIC(16,2),
  fill_rate NUMERIC(8,4),
  otif_flag INTEGER,
  net_sales_inr NUMERIC(18,2)
);

CREATE TABLE fact_lot_allocations (
  allocation_id VARCHAR(30) PRIMARY KEY,
  order_id VARCHAR(30),
  lot_id VARCHAR(30),
  warehouse_id VARCHAR(20),
  product_id VARCHAR(30),
  allocated_qty_kg NUMERIC(16,2),
  lot_expiry_date DATE,
  lot_harvest_date DATE
);

CREATE TABLE fact_outbound_shipments (
  outbound_shipment_id VARCHAR(30) PRIMARY KEY,
  order_id VARCHAR(30),
  warehouse_id VARCHAR(20),
  carrier_id VARCHAR(20),
  promised_delivery_date DATE,
  actual_delivery_date DATE,
  delivered_qty_kg NUMERIC(16,2),
  customer_rejected_qty_kg NUMERIC(16,2),
  source_lot_temperature_excursion_hours NUMERIC(12,2)
);

CREATE TABLE fact_market_prices (
  month DATE,
  product_id VARCHAR(30),
  market_reference_price_inr_per_kg NUMERIC(12,2)
);

CREATE TABLE fact_weather_monthly (
  month DATE,
  region VARCHAR(60),
  rainfall_mm NUMERIC(12,2),
  avg_temperature_c NUMERIC(12,2),
  temperature_anomaly_c NUMERIC(12,2),
  weather_risk_flag VARCHAR(30)
);

CREATE TABLE fact_procurement_contracts (
  contract_id VARCHAR(30) PRIMARY KEY,
  farm_id VARCHAR(20),
  product_id VARCHAR(30),
  contract_start DATE,
  contract_end DATE,
  contract_price_inr_per_kg NUMERIC(12,2),
  payment_terms_days INTEGER,
  pricing_mechanism VARCHAR(30)
);

