DROP TABLE IF EXISTS nsi_with_aeb;

CREATE TABLE nsi_with_aeb AS
SELECT
    oid,
    ST_SetSRID(ST_POINT(longitude, latitude), 4326) as geom,
    bddf_id,
    annual_expected_loss_without,
    annual_expected_loss_with,
    annual_expected_loss_without - annual_expected_loss_with as aeb
FROM
    (
        SELECT
            oid,
            latitude,
            longitude,
            bddf_id,
            SUM(
                CASE
                    WHEN mangrove_status = 'without' THEN 1
                    ELSE 0
                END * (bldg_loss_usd + content_loss_usd + inv_loss_usd) / return_period
            ) as annual_expected_loss_without,
            SUM(
                CASE
                    WHEN mangrove_status = 'with2010' THEN 1
                    ELSE 0
                END * (bldg_loss_usd + content_loss_usd + inv_loss_usd) / return_period
            ) as annual_expected_loss_with
        FROM
            (
                SELECT
                    oid,
                    latitude,
                    longitude,
                    bddf_id,
                    bldg_loss_usd,
                    content_loss_usd,
                    inv_loss_usd,
                    SPLIT_PART(grid_name, '_', 1) as mangrove_status,
                    SPLIT_PART(grid_name, '_', 5) :: int as return_period
                FROM
                    nsi_applied_ddf
                WHERE
                    bddf_id != 0
            ) q
        GROUP BY
            1,
            2,
            3,
            4
    ) q;

CREATE INDEX ON nsi_with_aeb USING gist(geom);