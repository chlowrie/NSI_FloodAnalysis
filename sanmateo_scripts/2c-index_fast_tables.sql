--1.3 Add geometry, return period, sea level rise, restoration status columns
ALTER TABLE nsi_applied_ddf
ADD COLUMN geom geometry;

ALTER TABLE nsi_applied_ddf
ADD COLUMN slr float;

ALTER TABLE nsi_applied_ddf
ADD COLUMN return_period float;

ALTER TABLE nsi_applied_ddf
ADD COLUMN restoration_status text;

UPDATE nsi_applied_ddf
SET geom = ST_SetSRID(ST_POINT(longitude, latitude), 4326);

UPDATE nsi_applied_ddf
SET slr = (regexp_split_to_array(SPLIT_PART(grid_name, '_', 2), E'[a-z]'))[1]::float;

UPDATE nsi_applied_ddf
SET return_period = (regexp_split_to_array(SPLIT_PART(grid_name, '_', 2), E'[a-z]'))[2]::float;

UPDATE nsi_applied_ddf
SET restoration_status = CASE 
	WHEN SPLIT_PART(grid_name, '_', 2) LIKE '%e%' THEN 'existing'
	WHEN SPLIT_PART(grid_name, '_', 2) LIKE '%r%' THEN 'restored'
END;

--1.4 Add index.  Not strictly necessary, since we're not doing any geographic work with this base table, only the derivative made in the next step
CREATE INDEX ON nsi_applied_ddf USING gist(geom);
CREATE INDEX nsi_applied_ddf_oid_idx ON nsi_applied_ddf (oid);

--1.5 Sanity test
-- In general, run a few queries to make sure the upload worked.
SELECT grid_name, count(*) FROM nsi_applied_ddf GROUP BY 1