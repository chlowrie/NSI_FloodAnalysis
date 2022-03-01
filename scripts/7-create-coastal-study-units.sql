/*
    Combine tesselas and FL keys
    Clip to a coastal buffer (20km)
    Generate mangrove areas
*/

CREATE TABLE fl_coastal_studyunits_20km_cutoff_w_mangrovearea AS
WITH study_units as
(
	SELECT 
		*
	FROM
	(
		SELECT 
			id, 
			geom,
			row_number() over (partition by id order by st_area(st_transform(geom, 32617)) desc) as r
		FROM
		(
			SELECT 
				(ST_Dump(ST_Intersection(base.geom, cutoff_20k.geom))).geom as geom,
				id
			FROM
			(
				SELECT id+1000 as id, geom FROM fl_keys
				UNION ALL
				SELECT id, geom FROM "FL_teselas_5km"
			)base,
			(
				SELECT 
					ST_Transform(ST_Buffer(ST_Transform(ST_Boundary(ST_UNION(geom)), 32617), 20000), 4326) as geom 
				FROM 
					florida_county_bounds
			)cutoff_20k
		)q
	)q
	WHERE 
		(id != 133 and r = 1)
		or
		(id = 133 and r=2)
), study_units_with_mangroves as (
	SELECT 
		study_units.id, 
		study_units.geom,
		SUM(
			ST_Area(ST_Intersection(mangroves.geom_32617, ST_Transform(study_units.geom, 32617)))
		) * 0.0001 as mangrove_area_hectares
	FROM
		study_units,
		"GMW_2010_v2_clippedToFL" mangroves
	WHERE mangroves.geom && study_units.geom
	GROUP BY 1,2
)
SELECT 
	* 
FROM study_units_with_mangroves
UNION ALL
SELECT 
	id, geom, 0
FROM study_units
WHERE id NOT IN (SELECT id FROM study_units_with_mangroves);

CREATE INDEX ON fl_coastal_studyunits_20km_cutoff_w_mangrovearea USING gist(geom)