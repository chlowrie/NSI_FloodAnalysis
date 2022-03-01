DROP TABLE IF EXISTS fl_studyunit_5km_aggs;
CREATE TABLE fl_studyunit_5km_aggs (
    id int,
    geom geometry,
    mangr_area_hr real,
    grid_name text,
    bldg_loss_usd numeric,
    content_loss_usd numeric,
    inv_loss_usd numeric,
	mangr_stat text,
	rp int
) PARTITION BY LIST(grid_name) ;

CREATE TABLE fl_studyunit_5km_aggs_with_rp010 PARTITION OF fl_studyunit_5km_aggs FOR VALUES IN ('w_010_wgs84.tif');
CREATE TABLE fl_studyunit_5km_aggs_with_rp025 PARTITION OF fl_studyunit_5km_aggs FOR VALUES IN ('w_025_wgs84.tif');
CREATE TABLE fl_studyunit_5km_aggs_with_rp050 PARTITION OF fl_studyunit_5km_aggs FOR VALUES IN ('w_050_wgs84.tif');
CREATE TABLE fl_studyunit_5km_aggs_with_rp100 PARTITION OF fl_studyunit_5km_aggs FOR VALUES IN ('w_100_wgs84.tif');
CREATE TABLE fl_studyunit_5km_aggs_without_rp010 PARTITION OF fl_studyunit_5km_aggs FOR VALUES IN ('wo_010_wgs84.tif');
CREATE TABLE fl_studyunit_5km_aggs_without_rp025 PARTITION OF fl_studyunit_5km_aggs FOR VALUES IN ('wo_025_wgs84.tif');
CREATE TABLE fl_studyunit_5km_aggs_without_rp050 PARTITION OF fl_studyunit_5km_aggs FOR VALUES IN ('wo_050_wgs84.tif');
CREATE TABLE fl_studyunit_5km_aggs_without_rp100 PARTITION OF fl_studyunit_5km_aggs FOR VALUES IN ('wo_100_wgs84.tif');

INSERT INTO fl_studyunit_5km_aggs
SELECT 
    grids.id,
    grids.geom,
    grids.mangr_area_hr,
    dmgs.grid_name,
    SUM(bldg_loss_usd),
    SUM(content_loss_usd),
    SUM(inv_loss_usd),
    SPLIT_PART(grid_name, '_', 1) as mangr_stat,
    SPLIT_PART(grid_name, '_', 2)::int as rp
FROM 
    (
        SELECT * FROM studyunits_5km_longshore_15km_crossshore_w_mangrovearea
        UNION ALL
        SELECT id+1000, mangr_area_hr, geom FROM fl_keys_w_mangrove_area
    ) grids,
    nsi_applied_ddf dmgs
WHERE
    ST_Intersects(grids.geom, dmgs.geom)
GROUP BY 1,2,3,4;

DROP TABLE IF EXISTS fl_studyunit_5km_aeb_draft;
CREATE TABLE fl_studyunit_5km_aeb_draft as
WITH q1 AS (
    SELECT 
        id, geom, mangr_area_hr,
        mangr_stat, 
        SUM(total_loss*prob) as p_total, 
        SUM(bldg_loss_usd*prob) as p_bldg, 
        SUM(content_loss_usd*prob) as p_content,
        SUM(inv_loss_usd*prob) as p_inv
    FROM
    (SELECT 
        id, geom, mangr_area_hr,
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
        fl_studyunit_5km_aggs
    ) q
    GROUP BY 1,2,3,4
)
SELECT 
    wo_mang.id, wo_mang.geom, wo_mang.mangr_area_hr,
    COALESCE(wo_mang.p_total, 0) - COALESCE(w_mang.p_total, 0) as aeb
FROM
    (SELECT * FROM q1 WHERE mangr_stat = 'w') w_mang
FULL OUTER JOIN
    (SELECT * FROM q1 WHERE mangr_stat = 'wo') wo_mang
USING (id)
ORDER BY 1;