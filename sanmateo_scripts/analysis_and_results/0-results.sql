--2.5: Sanity Checks
-- Expected Damages by Return Period, SLR
SELECT 
	slr, 
	return_period, 
	SUM(annual_expected_loss_restored)::numeric::money as ae_restored,
	SUM(annual_expected_loss_existing)::numeric::money as ae_existing,
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
ORDER BY 1,2,3
;


-- N BDDF_IDs per Building
-- Should not be more than 1
SELECT 
	oid, count(DISTINCT bddf_id)
FROM nsi_with_aeb
GROUP BY 1
ORDER BY 2 DESC
;


-- RESULTS
-- Simple sum across weighted return periods
SELECT slr, SUM(aeb)::numeric::money
FROM nsi_with_aeb
GROUP BY 1
ORDER BY 1
;


-- RESULTS
-- Simple sum across unweighted return periods
SELECT 
	slr, 
	return_period, 
	SUM(expected_loss_restored)::numeric::money as expected_loss_restored,
	SUM(expected_loss_existing)::numeric::money as expected_loss_existing,
	SUM(expected_benefit)::numeric::money as expected_benefit,
    count(*)
FROM nsi_with_expected_damages_unweighted
GROUP BY 1,2
ORDER BY 1,2
;

-- AEB by containment in sites
-- DROP TABLE IF EXISTS site_contained_sample_slr0;
-- CREATE TABLE site_contained_sample_slr0 AS
SELECT 
		slr,
		geom,
		power_integral_aed(return_period, expected_loss_restored, 1, 100) as aed_restored,
		power_integral_aed(return_period, expected_loss_existing, 1, 100) as aed_existing,
		(power_integral_aed(return_period, expected_loss_existing, 1, 100) - 
			power_integral_aed(return_period, expected_loss_restored, 1, 100)) as aeb,
		(SUM(power_integral_aed(return_period, expected_loss_existing, 1, 100) - 
			power_integral_aed(return_period, expected_loss_restored, 1, 100)) OVER (PARTITION BY slr)) as total_aeb
FROM
(
	SELECT 
		slr, 
		geom,
		array_agg(return_period order by return_period asc) as return_period, 
		array_agg(expected_loss_restored order by return_period asc) as expected_loss_restored,
		array_agg(expected_loss_existing order by return_period asc) as expected_loss_existing,
		count(*) as cnt,
		count(*) over () as total_cnt
	FROM
	(
		SELECT 
			slr, 
			return_period, 
			geom,
			SUM(expected_loss_restored)::numeric as expected_loss_restored,
			SUM(expected_loss_existing)::numeric as expected_loss_existing,
			SUM(expected_benefit)::numeric as expected_benefit,
			count(*)
		FROM nsi_with_expected_damages_unweighted nsi
		WHERE EXISTS (SELECT 1 FROM all_sites WHERE ST_Contains(all_sites.geom,  nsi.geom) LIMIT 1)
		GROUP BY 1,2,3
		ORDER BY 1,2,3
	)q
	GROUP BY 1,2
)q
WHERE cnt = 3 and slr = 0


-- Total AEB by SLR
SELECT 
	slr,
	power_integral_aed(return_period, expected_loss_restored, 1, 100)::numeric::money as aed_restored,
	power_integral_aed(return_period, expected_loss_existing, 1, 100)::numeric::money as aed_existing,
	(power_integral_aed(return_period, expected_loss_existing, 1, 100) - 
		power_integral_aed(return_period, expected_loss_restored, 1, 100))::numeric::money as aeb
FROM
(
	SELECT 
		slr, 
		array_agg(return_period order by return_period asc) as return_period, 
		array_agg(expected_loss_restored order by return_period asc) as expected_loss_restored,
		array_agg(expected_loss_existing order by return_period asc) as expected_loss_existing
	FROM
	(
		SELECT 
			slr, 
			return_period, 
			SUM(expected_loss_restored)::numeric as expected_loss_restored,
			SUM(expected_loss_existing)::numeric as expected_loss_existing,
			SUM(expected_benefit)::numeric as expected_benefit
		FROM nsi_with_expected_damages_unweighted nsi
		WHERE NOT EXISTS (SELECT 1 FROM all_sites WHERE ST_Contains(all_sites.geom,  nsi.geom) LIMIT 1)
		GROUP BY 1,2
	)q
	GROUP BY 1
)q