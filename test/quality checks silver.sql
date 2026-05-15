/*
=========================================================================================
Quality checks
=========================================================================================
Scripts purpose:
This script performs verious quality checks for data consistency, accuracy,
and standerdization across the 'silver' schemas. it inclouds checks for:
 - Null or duplicate primary key
 - Unwanted spaces in string fields.
 - Data standerdization and consistency.
 - Invalid date ranges and orders.
 - Data consistency between related fields.
=========================================================================================
*/

--=====================================================
-- Checking 'bronze.crm_cust_info'
--=====================================================

-- Check for nulls or duplicates in primary key
-- Expectation: No result

SELECT 
cst_id,
COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL

-- Check fro unwanted sapces
-- Expactation: No results

SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)

-- Data standardization & consistency

SELECT DISTINCT cst_material_status
FROM bronze.crm_cust_info


--=====================================================
-- Checking 'silver.crm_cust_info'
--=====================================================

-- Check for nulls or duplicates in primary key
-- Expectation: No result

SELECT 
cst_id,
COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL

-- Check fro unwanted sapces
-- Expactation: No results

SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)

-- Data standardization & consistency

SELECT DISTINCT cst_material_status
FROM silver.crm_cust_info


SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info

--=====================================================
-- Checking 'bronze.crm_prd_info'
--=====================================================

-- Check for nulls or duplicates in primary key
-- Expectation: No result

SELECT 
prd_id,
COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL

-- Check fro unwanted sapces
-- Expactation: No results

SELECT prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

-- Check for nulls or nagative numbers
-- Expactation: No results
SELECT COALESCE (prd_cost,0)
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR  COALESCE (prd_cost,0) IS NULL

-- Data standardization & consistency

SELECT DISTINCT prd_line
FROM bronze.crm_prd_info

-- Check for ivalid date orders 
SELECT *
FROM bronze.crm_prd_info
WHERE prd_end_dt > prd_start_dt

--=====================================================
-- Checking 'silver.crm_prd_info'
--=====================================================

-- Check for nulls or duplicates in primary key
-- Expectation: No result

SELECT 
prd_id,
COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL

-- Check fro unwanted sapces
-- Expactation: No results

SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

-- Check for nulls or nagative numbers
-- Expactation: No results
SELECT COALESCE (prd_cost,0)
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR  COALESCE (prd_cost,0) IS NULL

-- Data standardization & consistency

SELECT DISTINCT prd_line
FROM silver.crm_prd_info

-- Check for ivalid date orders 
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt

--=====================================================
-- Checking 'bronze.crm_sales_details'
--=====================================================

-- Check for ivalid date orders 
SELECT
NULLIF(sls_due_dt,0)
FROM bronze.crm_sales_details
WHERE  sls_due_dt <= 0
OR LEN(sls_due_dt) != 8
OR sls_due_dt < 19000101
OR sls_due_dt > 20500101;

SELECT
*
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- Check data cosistency: Between sales, Quantity, and price
-- >> Sales = Quantity * Price
-- >> Values must not be NULL, zero, or negative.

SELECT DISTINCT
	sls_sales AS old_sls_sales,
	sls_quantity,
	sls_price AS old_sls_price,
CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
	THEN sls_quantity * ABS(sls_price)
	ELSE sls_sales 
END AS sls_sales,

CASE WHEN sls_price IS NULL OR sls_price <= 0
	THEN sls_sales / NULLIF(sls_quantity,0)
 ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price 
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0  OR sls_quantity <= 0 OR sls_price <= 0

--=====================================================
-- Checking 'silver.crm_sales_details'
--=====================================================

-- Check for ivalid date orders 

SELECT
*
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- Check data cosistency: Between sales, Quantity, and price
-- >> Sales = Quantity * Price
-- >> Values must not be NULL, zero, or negative.

SELECT DISTINCT
	sls_quantity,
CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
	THEN sls_quantity * ABS(sls_price)
	ELSE sls_sales 
END AS sls_sales,

CASE WHEN sls_price IS NULL OR sls_price <= 0
	THEN sls_sales / NULLIF(sls_quantity,0)
 ELSE sls_price
END AS sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price 
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0  OR sls_quantity <= 0 OR sls_price <= 0;

SELECT * FROM silver.crm_sales_details


--=====================================================
-- Checking 'bronze.crm_cust_info'
--=====================================================


 -- Check primary key

 SELECT DISTINCT
 cid,
 REPLACE(cid,'-','')
 FROM bronze.erp_loc_a101
 WHERE REPLACE(cid,'-','') NOT IN (SELECT cst_key FROM bronze.crm_cust_info)

 SELECT
 *
 FROM bronze.crm_cust_info


 -- Data standardization & consistency

 SELECT DISTINCT
 cntry,
 CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	 WHEN TRIM(cntry) IN ('US','USA' ) THEN 'United State'
	 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
	 ELSE cntry
END AS cntry
 FROM bronze.erp_loc_a101

--=====================================================
-- Checking 'silver.erp_loc_a101'
--=====================================================

 -- Check primary key

 

SELECT DISTINCT
 cid
 FROM silver.erp_loc_a101
 WHERE cid NOT IN (SELECT cst_key FROM bronze.crm_cust_info)



 -- Data standardization & consistency

 SELECT DISTINCT
 cntry
 FROM silver.erp_loc_a101

--=====================================================
-- Checking 'bronze.erp_px_cat_g1V2'
--=====================================================

 -- Check primary key

 SELECT DISTINCT
 id
 FROM bronze.erp_px_cat_g1V2
 WHERE id NOT IN (SELECT cat_id FROM silver.crm_prd_info)

 -- Check for unwanted spaces

 SELECT * FROM bronze.erp_px_cat_g1V2
 WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)

 -- Data standardization & consistency

 SELECT DISTINCT
 maintenance
 FROM bronze.erp_px_cat_g1V2

--=====================================================
-- Checking 'silver.erp_px_cat_g1V2'
--=====================================================

 -- Check primary key

 SELECT DISTINCT
 id
 FROM silver.erp_px_cat_g1V2
 WHERE id NOT IN (SELECT cat_id FROM silver.crm_prd_info)

 -- Check for unwanted spaces

 SELECT * FROM silver.erp_px_cat_g1V2
 WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)

 -- Data standardization & consistency

 SELECT DISTINCT
 maintenance
 FROM silver.erp_px_cat_g1V2
