SELECT 
	SUM(gdp.value * 
		st_area(st_intersection(v.geom, gdp.geom)) / 
			st_area(gdp.geom) *
		least(v.flood_height / 5.0, 1.0)) as total_dmg
FROM
(
	SELECT *
	FROM
	(
		SELECT ST_TRansform(ST_SetSRID((ST_PixelAsPolygons(rast)).geom, 54034), 4326) as geom,
			(ST_PixelAsPolygons(rast)).val as flood_height
		FROM 
			public.with2010_twl_tc_tr_050 pix,
			florida_blockgroup_bounds bg
		WHERE 
			ST_Intersects(
				bg.geom,
				st_transform(st_setsrid(rast, 54034), 4269)
			)
	)q
	WHERE flood_height > 0
)v,
gdp_nsi_comparison gdp
WHERE ST_Intersects(gdp.geom, v.geom)
;

-- SELECT ST_SRID(geom) from gdp_nsi_comparison LIMIT 1;