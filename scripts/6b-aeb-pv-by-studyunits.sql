DROP TABLE IF EXISTS aeb_by_studyunits;
CREATE TABLE aeb_by_studyunits (
    studyunits_id int,
    geom geometry,
    aeb real,
	mangrove_area_hectares real,
	pv real,
	dr_factor real
) PARTITION BY LIST(dr_factor);

CREATE TABLE aeb_by_studyunits_p04 PARTITION OF aeb_by_studyunits FOR VALUES IN (0.04);
CREATE TABLE aeb_by_studyunits_p07 PARTITION OF aeb_by_studyunits FOR VALUES IN (0.07);

INSERT INTO aeb_by_studyunits
WITH q AS (
	SELECT 
		q1.*,
		aeb*dr_factor as pv,
		p as dr_factor
	FROM
	(
		SELECT
			studyunits.id, 
			ST_Transform(studyunits.geom, 4326) as geom, 
			SUM(aeb) as aeb,
			mangrove_area_hectares
		FROM
			nsi_with_aeb nsi,
			fl_coastal_studyunits_20km_cutoff_w_mangrovearea studyunits
		WHERE ST_Intersects(studyunits.geom, nsi.geom)
		GROUP BY 1, 2, 4
	)q1,
	(
		SELECT p, sum(pow(1+p, -yr)) as dr_factor
		FROM
			(VALUES (0.04), (0.07)) perc(p),
			(SELECT generate_series(0,30) as yr) q1
		GROUP BY 1
	)q2
)
SELECT * 
FROM q
UNION ALL
SELECT
	id, 
	ST_Transform(geom, 4326) as geom, 
	0,
	mangr_area_hr,
	0,
	0.04
FROM 
	fl_coastal_studyunits_20km_cutoff_w_mangrovearea
WHERE id NOT IN (select id from q)
UNION ALL
SELECT
	id, 
	ST_Transform(geom, 4326) as geom, 
	0,
	mangr_area_hr,
	0,
	0.07
FROM 
	fl_coastal_studyunits_20km_cutoff_w_mangrovearea
WHERE id NOT IN (select id from q);

-- Necessary because ArcGIS Pro doesn't support loading by table partition
-- QGIS does.
DROP TABLE IF EXISTS aeb_by_studyunits_p04_2;
DROP TABLE IF EXISTS aeb_by_studyunits_p07_2;

CREATE TABLE aeb_by_studyunits_p07_2 as SELECT * FROM aeb_by_studyunits WHERE dr_factor > 0.05;
CREATE TABLE aeb_by_studyunits_p04_2 as SELECT * FROM aeb_by_studyunits WHERE dr_factor < 0.05;


