DROP TABLE IF EXISTS aeb_by_bg;

CREATE TABLE aeb_by_bg (
	bg_id int,
	geom geometry,
	aeb real,
	pv real,
	dr_factor real
) PARTITION BY LIST(dr_factor);

CREATE TABLE aeb_by_bg_p04 PARTITION OF aeb_by_bg FOR
VALUES
	IN (0.04);

CREATE TABLE aeb_by_bg_p07 PARTITION OF aeb_by_bg FOR
VALUES
	IN (0.07);

INSERT INTO aeb_by_bg 
WITH q AS (
	SELECT
		q1.*,
		aeb * dr_factor as pv,
		p as dr_factor
	FROM
		(
			SELECT
				bg.id,
				ST_Transform(bg.geom, 4326) geom,
				SUM(aeb) as aeb
			FROM
				nsi_with_aeb nsi,
				florida_blockgroup_bounds bg
			WHERE
				ST_Intersects(ST_Transform(bg.geom, 4326), nsi.geom)
			GROUP BY
				1,
				2
		) q1,
		(
			SELECT
				p,
				sum(pow(1 + p, - yr)) as dr_factor
			FROM
				(
					VALUES
						(0.04),
						(0.07)
				) perc(p),
				(
					SELECT
						generate_series(0, 30) as yr
				) q1
			GROUP BY
				1
		) q2
)
SELECT * 
FROM q
UNION ALL
SELECT
	id, 
	ST_Transform(geom, 4326) as geom, 
	0,
	0,
	0.04
FROM 
	florida_blockgroup_bounds
WHERE id NOT IN (select id from q)
UNION ALL
SELECT
	id, 
	ST_Transform(geom, 4326) as geom, 
	0,
	0,
	0.07
FROM 
	florida_blockgroup_bounds
WHERE id NOT IN (select id from q);

CREATE TABLE aeb_by_bg_p07_2 as SELECT * FROM aeb_by_bg WHERE dr_factor > 0.05;
CREATE TABLE aeb_by_bg_p04_2 as SELECT * FROM aeb_by_bg WHERE dr_factor < 0.05;