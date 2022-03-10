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