DROP TABLE IF EXISTS aeb_by_county;
CREATE TABLE aeb_by_county (
    county_id int,
    geom geometry,
    display_geom geometry,
    aeb real,
	pv real,
	dr_factor real
) PARTITION BY LIST(dr_factor);

CREATE TABLE aeb_by_county_p04 PARTITION OF aeb_by_county FOR VALUES IN (0.04);
CREATE TABLE aeb_by_county_p07 PARTITION OF aeb_by_county FOR VALUES IN (0.07);

INSERT INTO aeb_by_county
SELECT 
	q1.*,
	aeb*dr_factor as pv,
	p as dr_factor
FROM
(
	SELECT
		counties.id, ST_Transform(counties.geom, 4326) geom, 
		st_difference(
			ST_Transform(counties.geom, 4326), 
			ST_Transform(
				st_buffer(
					st_transform(
						st_boundary(counties.geom), 
						32617
					), 
					100
				), 
				4326
			)
		) as display_geom,
		SUM(aeb) as aeb
	FROM
		nsi_with_aeb nsi,
		florida_county_bounds counties
	WHERE ST_Intersects(ST_Transform(counties.geom, 4326), nsi.geom)
	GROUP BY 1, 2
)q1,
(
	SELECT p, sum(pow(1+p, -yr)) as dr_factor
	FROM
		(VALUES (0.04), (0.07)) perc(p),
		(SELECT generate_series(0,30) as yr) q1
	GROUP BY 1
)q2;
`
