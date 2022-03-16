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