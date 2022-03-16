SELECT 
	slr, 
	return_period, 
	SUM(annual_expected_loss_restored) as ae_restored,
	SUM(annual_expected_loss_existing) as ae_existing,
	SUM(aeb)::numeric::money as aeb
FROM nsi_with_ae_by_rp
GROUP BY 1,2
ORDER BY 1,2;