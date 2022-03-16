--2.1: Create the total AEB table, by building
-- This will store the AEB, geometry, and SLR
-- And loss with marsh restored, loss with current marsh, and the difference between the two
-- Could be modified to store more columns
-- 
-- NOTE that this is just an approximation.  
-- To get the actual value, you need to fit a curve and integrate 
DROP TABLE IF EXISTS nsi_with_aeb;
CREATE TABLE nsi_with_aeb AS
SELECT
    oid,
    ST_SetSRID(ST_POINT(longitude, latitude), 4326) as geom,
    bddf_id,
    slr,
    annual_expected_loss_restored,
    annual_expected_loss_existing,
    annual_expected_loss_existing - annual_expected_loss_restored as aeb
FROM
    (
        SELECT
            oid,
            latitude,
            longitude,
            bddf_id,
            slr,
            SUM(
                CASE
                    WHEN restoration_status = 'existing' THEN 1
                    ELSE 0
                END * (bldg_loss_usd + content_loss_usd + inv_loss_usd) / return_period
            ) as annual_expected_loss_existing,
            SUM(
                CASE
                    WHEN restoration_status = 'restored' THEN 1
                    ELSE 0
                END * (bldg_loss_usd + content_loss_usd + inv_loss_usd) / return_period
            ) as annual_expected_loss_restored
        FROM
            (
                SELECT
                    oid,
                    latitude,
                    longitude,
                    bddf_id,
                    bldg_loss_usd,
                    content_loss_usd,
                    inv_loss_usd,
                    restoration_status,
                    slr,
                    return_period
                FROM
                    nsi_applied_ddf
                WHERE
                    -- bddf_id = 0 corresponds to 'not flooded' under that scenario
                    -- This is the only case where a building can have two bddf_ids (if one of them is zero).
                    -- If there are two nonzero bddf_id values, you've made a mistake in running FAST
                    -- Likely by running with CoastalA in some scenarios, CoastalV in others.
                    bddf_id != 0
            ) q
        GROUP BY
            1,
            2,
            3,
            4,
            5
    ) q;


--2.2: Create the Annual Expected Benefit PER STORM table, by building
-- This will store the AEB, geometry, SLR, and storm return period
-- And loss with marsh restored, loss with current marsh, and the difference between the two
DROP TABLE IF EXISTS nsi_with_ae_by_rp;
CREATE TABLE nsi_with_ae_by_rp AS
SELECT
    oid,
    ST_SetSRID(ST_POINT(longitude, latitude), 4326) as geom,
    bddf_id,
    slr,
	return_period,
    annual_expected_loss_restored,
    annual_expected_loss_existing,
    annual_expected_loss_existing - annual_expected_loss_restored as aeb
FROM
    (
        SELECT
            oid,
            latitude,
            longitude,
            bddf_id,
            slr,
		    return_period,
		SUM(
            CASE
                WHEN restoration_status = 'existing' THEN 1
                ELSE 0
            END * (bldg_loss_usd + content_loss_usd + inv_loss_usd) / return_period) as annual_expected_loss_existing,
		SUM(
            CASE
                WHEN restoration_status = 'restored' THEN 1
                ELSE 0
            END * (bldg_loss_usd + content_loss_usd + inv_loss_usd) / return_period) as annual_expected_loss_restored
        FROM
            (
                SELECT
                    oid,
                    latitude,
                    longitude,
                    bddf_id,
                    bldg_loss_usd,
                    content_loss_usd,
                    inv_loss_usd,
                    restoration_status,
                    slr,
                    return_period
                FROM
                    nsi_applied_ddf
                WHERE
                    bddf_id != 0
            ) q
        GROUP BY
            1,
            2,
            3,
            4,
            5,
 			6
    ) q;

--2.3: Create the Expected Loss/Benefit per Storm table, by building
-- Unweighted Table, for use in Curve Fitting
DROP TABLE IF EXISTS nsi_with_expected_damages_unweighted;
CREATE TABLE nsi_with_expected_damages_unweighted AS
SELECT
    oid,
    ST_SetSRID(ST_POINT(longitude, latitude), 4326) as geom,
    bddf_id,
    slr,
    return_period,
    expected_loss_restored,
    expected_loss_existing,
    expected_loss_existing - expected_loss_restored as expected_benefit
FROM
    (
        SELECT
            oid,
            latitude,
            longitude,
            bddf_id,
            slr,
            return_period,
            SUM(
                CASE
                    WHEN restoration_status = 'existing' THEN 1
                    ELSE 0
                END * (bldg_loss_usd + content_loss_usd + inv_loss_usd) 
            ) as expected_loss_existing,
            SUM(
                CASE
                    WHEN restoration_status = 'restored' THEN 1
                    ELSE 0
                END * (bldg_loss_usd + content_loss_usd + inv_loss_usd) 
            ) as expected_loss_restored
        FROM
            (
                SELECT
                    oid,
                    latitude,
                    longitude,
                    bddf_id,
                    bldg_loss_usd,
                    content_loss_usd,
                    inv_loss_usd,
                    restoration_status,
                    slr,
                    return_period
                FROM
                    nsi_applied_ddf
                WHERE
                    -- bddf_id = 0 corresponds to 'not flooded' under that scenario
                    bddf_id != 0
            ) q
        GROUP BY
            1,
            2,
            3,
            4,
            5,
            6
    ) q;

--2.4:  Create indices.
-- This index is necessary for queries to execute quickly
-- (as opposed to the index on nsi_applied_ddf)
CREATE INDEX ON nsi_with_aeb USING gist(geom);
CREATE INDEX ON nsi_with_ae_by_rp USING gist(geom);

--2.5: Sanity Checks
-- Expected Damages by Return Period, SLR
SELECT 
	slr, 
	return_period, 
	SUM(annual_expected_loss_restored) as ae_restored,
	SUM(annual_expected_loss_existing) as ae_existing,
	SUM(aeb)::numeric::money as aeb
FROM nsi_with_ae_by_rp
GROUP BY 1,2
ORDER BY 1,2;

-- Building Average Expected Damage
SELECT 
	slr,
	return_period,
	marsh_benefit,
	avg(aeb)::numeric::money
FROM
(
SELECT 
	aeb,
	slr,
	return_period,
	CASE WHEN aeb > 0 THEN 'positive'
		ELSE 'negative' END AS marsh_benefit
FROM 
	nsi_with_ae_by_rp
)q
GROUP BY 1,2,3
ORDER BY 1,2,3;


-- N BDDF_IDs per Building
-- Should not be more than 1
SELECT 
	oid, count(DISTINCT bddf_id)
FROM nsi_with_aeb
GROUP BY 1
ORDER BY 2 DESC;


-- RESULTS
-- Simple sum across weighted return periods
SELECT slr, SUM(aeb)::numeric::money
FROM nsi_with_aeb
GROUP BY 1
ORDER BY 1
;







