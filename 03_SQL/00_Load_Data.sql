-- Replace <RAW_FOLDER> with the absolute path to 02_Data/Raw. Run inside psql.
SET search_path TO agri_capstone;
\copy dim_farms FROM '<RAW_FOLDER>/dim_farms.csv' CSV HEADER;
\copy dim_products FROM '<RAW_FOLDER>/dim_products.csv' CSV HEADER;
\copy dim_warehouses FROM '<RAW_FOLDER>/dim_warehouses.csv' CSV HEADER;
\copy dim_carriers FROM '<RAW_FOLDER>/dim_carriers.csv' CSV HEADER;
\copy dim_customers FROM '<RAW_FOLDER>/dim_customers.csv' CSV HEADER;
\copy fact_weather_monthly FROM '<RAW_FOLDER>/fact_weather_monthly.csv' CSV HEADER;
\copy fact_market_prices FROM '<RAW_FOLDER>/fact_market_prices.csv' CSV HEADER;
\copy fact_procurement_contracts FROM '<RAW_FOLDER>/fact_procurement_contracts.csv' CSV HEADER;
\copy fact_harvest_lots FROM '<RAW_FOLDER>/fact_harvest_lots.csv' CSV HEADER;
\copy fact_quality_inspections FROM '<RAW_FOLDER>/fact_quality_inspections.csv' CSV HEADER;
\copy fact_inbound_shipments FROM '<RAW_FOLDER>/fact_inbound_shipments.csv' CSV HEADER;
\copy fact_inventory_lot_status FROM '<RAW_FOLDER>/fact_inventory_lot_status.csv' CSV HEADER;
\copy fact_customer_orders FROM '<RAW_FOLDER>/fact_customer_orders.csv' CSV HEADER;
\copy fact_lot_allocations FROM '<RAW_FOLDER>/fact_lot_allocations.csv' CSV HEADER;
\copy fact_outbound_shipments FROM '<RAW_FOLDER>/fact_outbound_shipments.csv' CSV HEADER;
