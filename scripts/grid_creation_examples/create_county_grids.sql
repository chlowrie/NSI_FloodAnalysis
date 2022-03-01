DROP TABLE IF EXISTS county_aggs;
CREATE TABLE county_aggs (
    id int,
    geom geometry,
    grid_name text,
    bldg_loss_usd real,
    content_loss_usd real,
    inv_loss_usd real,
	mangr_stat text,
	rp int
) PARTITION BY LIST(grid_name) ;

CREATE TABLE county_aggs_with_rp010 PARTITION OF county_aggs FOR VALUES IN ('w_010_wgs84.tif');
CREATE TABLE county_aggs_with_rp025 PARTITION OF county_aggs FOR VALUES IN ('w_025_wgs84.tif');
CREATE TABLE county_aggs_with_rp050 PARTITION OF county_aggs FOR VALUES IN ('w_050_wgs84.tif');
CREATE TABLE county_aggs_with_rp100 PARTITION OF county_aggs FOR VALUES IN ('w_100_wgs84.tif');
CREATE TABLE county_aggs_without_rp010 PARTITION OF county_aggs FOR VALUES IN ('wo_010_wgs84.tif');
CREATE TABLE county_aggs_without_rp025 PARTITION OF county_aggs FOR VALUES IN ('wo_025_wgs84.tif');
CREATE TABLE county_aggs_without_rp050 PARTITION OF county_aggs FOR VALUES IN ('wo_050_wgs84.tif');
CREATE TABLE county_aggs_without_rp100 PARTITION OF county_aggs FOR VALUES IN ('wo_100_wgs84.tif');

CREATE INDEX ON florida_county_bounds USING gist(geom_4326);

INSERT INTO county_aggs
SELECT 
    grids.id,
    grids.geom,
    dmgs.grid_name,
    SUM(bldg_loss_usd),
    SUM(content_loss_usd),
    SUM(inv_loss_usd),
    SPLIT_PART(grid_name, '_', 1) as mangr_stat,
    SPLIT_PART(grid_name, '_', 2)::int as rp
FROM 
    florida_county_bounds grids,
    nsi_applied_ddf dmgs
WHERE 
    ST_INTERSECTS(grids.geom_4326, dmgs.geom)
GROUP BY 1,2,3;

DROP TABLE IF EXISTS county_aeb_draft;
CREATE TABLE county_aeb_draft as
WITH q1 AS (
    SELECT 
        id, geom, 
        mangr_stat, 
        SUM(total_loss*prob) as p_total, 
        SUM(bldg_loss_usd*prob) as p_bldg, 
        SUM(content_loss_usd*prob) as p_content,
        SUM(inv_loss_usd*prob) as p_inv
    FROM
    (SELECT 
        id, geom, 
        mangr_stat,
        CASE 
            WHEN rp=10 THEN 0.1
            WHEN rp=25 THEN 0.04
            WHEN rp=50 THEN 0.02
            WHEN rp=100 THEN 0.01
        END as prob,
        bldg_loss_usd + content_loss_usd + inv_loss_usd as total_loss,
        bldg_loss_usd,
        content_loss_usd,
        inv_loss_usd
    FROM 
        county_aggs
    ) q
    GROUP BY 1,2,3
)
SELECT 
    wo_mang.id, wo_mang.geom,
    COALESCE(wo_mang.p_total, 0) - COALESCE(w_mang.p_total, 0) as aeb
FROM
    (SELECT * FROM q1 WHERE mangr_stat = 'w') w_mang
FULL OUTER JOIN
    (SELECT * FROM q1 WHERE mangr_stat = 'wo') wo_mang
USING (id)
ORDER BY 1;