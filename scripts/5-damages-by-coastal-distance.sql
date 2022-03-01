DROP TABLE IF EXISTS nsi_with_aeb;
CREATE TABLE nsi_with_aeb AS
WITH damages as
(
	SELECT
		oid, geom, mangr_stat,
		sum(total_loss_usd * 
			CASE 
				WHEN rp=10 THEN 0.1
				WHEN rp=25 THEN 0.04
				WHEN rp=50 THEN 0.02
				WHEN rp=100 THEN 0.01
			END	  
		) as total_loss_ae
	FROM
	(
	SELECT 
		oid, 
		SPLIT_PART(grid_name, '_', 1) as mangr_stat,
		SPLIT_PART(grid_name, '_', 2)::int as rp,
		bldg_loss_usd +
		content_loss_usd +
		inv_loss_usd as total_loss_usd,
		geom
	FROM
		nsi_applied_ddf
	)q
	GROUP BY 1,2,3
)
SELECT 
    oid, geom,
    COALESCE(wo_mang.total_loss_ae, 0) - COALESCE(w_mang.total_loss_ae, 0) as aeb
FROM
    (SELECT * FROM damages WHERE mangr_stat = 'w') w_mang
FULL OUTER JOIN
    (SELECT * FROM damages WHERE mangr_stat = 'wo') wo_mang
USING (oid, geom)
;

CREATE INDEX ON nsi_with_aeb USING gist(geom);

DROP TABLE IF EXISTS damage_totals_by_coastal_distance;
CREATE TABLE damage_totals_by_coastal_distance AS
WITH coastline as (
	SELECT 
		ST_Simplify(ST_Transform(ST_UNION(geom), 32617), 100) as geom 
	FROM florida_county_bounds
), buffers AS (
	SELECT 
		st_transform(st_buffer(st_boundary(coastline.geom), d), 4326) as geom,
		d as dist,
		row_number() over (order by d asc)
	FROM
		coastline,
		(SELECT generate_series(1000, 30000, 1000) as d) distances
)
SELECT
	dist, b.geom,
	SUM(aeb) as aeb
FROM
	nsi_with_aeb nsi,
	buffers b
WHERE ST_Intersects(nsi.geom, b.geom)
GROUP BY 1,2;

SELECT dist, geom, aeb::numeric::money FROM damage_totals_by_coastal_distance;