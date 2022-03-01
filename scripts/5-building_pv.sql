-- Create PV table and join with 0 value tesselas
-- Requies grids to be created.
DROP TABLE IF EXISTS fl_studyunit_5km_aeb_npv_5p_30yr;
CREATE TABLE fl_studyunit_5km_aeb_pv_5p_30yr AS
WITH nonzero as (
	SELECT 
		id, geom, mangr_area_hr, aeb,
		sum(aeb * dr_factor) as pv
	FROM
	(
		SELECT 
			pow(1.05, -x) as dr_factor, x as dr, 30 as term
		FROM
			generate_series(0,30) as x
	)q1,
	fl_studyunit_5km_aeb_draft q2
	GROUP BY 1,2,3,4
)
SELECT 
	*
FROM nonzero
UNION ALL
SELECT 
	id, geom, mangr_area_hr, 0, 0
FROM studyunits_5km_longshore_15km_crossshore_w_mangrovearea q
WHERE q.id NOT IN (SELECT id from nonzero)
ORDER BY 1