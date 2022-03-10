CREATE OR REPLACE FUNCTION power_integral_aed(
	years float[], 
	damages float[], 
	minbound float, 
	maxbound float
) RETURNS float
AS $$
	from scipy.optimize import curve_fit
	import numpy as np
	
	def power_law(x, a, b):
		return a*np.power(x, b)
	
	def aed_integral(p, a, b):
		return a * np.power(p, -b+1) / (-b+1)
		
	plpy.info(years)
	plpy.info(damages)    
	
	parameters, covariance = curve_fit(
		f=power_law,
		xdata = years,
		ydata = damages,
		p0 = [10,10],
		bounds=(-np.inf, np.inf)
	)
	
	a, b = parameters
	
	return aed_integral(1/minbound, a, b) - aed_integral(1/maxbound, a, b)

$$ LANGUAGE plpython3u;

-- SELECT 
-- 	power_integral_aed(
-- 		ARRAY[
-- 			1, 
-- 			20,
-- 			100
-- 		], 
-- 		ARRAY[
-- 			577265532.978651,
-- 			565736435.5644119,
-- 			693987045.0368384
-- 		],
-- 		1,
-- 		100),
-- 	power_integral_aed(
-- 		ARRAY[
-- 			1, 
-- 			20,
-- 			100
-- 		], 
-- 		ARRAY[
-- 			595896839.958807,
-- 			581277087.867979,
-- 			728920221.2438828
-- 		],
-- 		1,
-- 		100),
-- 	power_integral_aed(
-- 		ARRAY[
-- 			1, 
-- 			20,
-- 			100
-- 		], 
-- 		ARRAY[
-- 			595896839.958807,
-- 			581277087.867979,
-- 			728920221.2438828
-- 		],
-- 		1,
-- 		100) - power_integral_aed(
-- 		ARRAY[
-- 			1, 
-- 			20,
-- 			100
-- 		], 
-- 		ARRAY[
-- 			577265532.978651,
-- 			565736435.5644119,
-- 			693987045.0368384
-- 		],
-- 		1,
-- 		100)

