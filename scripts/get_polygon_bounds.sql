CREATE TABLE with_rp50_bounds AS
SELECT ST_Transform(ST_SetSRID(geom, 54034), 4326) as geom  FROM
(
SELECT 
	ST_Polygon(ST_SetBandNodataValue(rast, 0)) as geom
FROM
	public.with2010_twl_tc_tr_050
)q
WHERE ST_Area(geom) > 0
;