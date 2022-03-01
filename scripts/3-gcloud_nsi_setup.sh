# Requires prep script to have run
# Also requires going through the (somewhat annoying) steps here: https://cloud.google.com/sql/docs/postgres/import-export/importing
# 1. Copy local files to Cloud Storage
gsutil cp FAST_outputs/* gs://nsi-fast-outputs

# 2. Create NSI table
psql -d mangroves_pub -U postgres -h $NSI_HOST -f create_nsi_table.sql

# 3. Import Cloud Storage files to Postgres DB
for i in with without
    do
    for j in 010 025 050 100
    do
        gcloud sql import csv florida-mangroves-econ-analysis gs://nsi-fast-outputs/${i}_${j}.csv --database=postgres --table=nsi_applied_ddf
    done
done

# 4. Add a geometry column.
psql -d mangroves_pub -U postgres -h $NSI_HOST -c "
    ALTER TABLE nsi_applied_ddf
    ADD COLUMN geom geometry;

    UPDATE nsi_applied_ddf
    SET geom = ST_SetSRID(ST_POINT(longitude, latitude), 4326);
"

# 5. Create index
psql -d mangroves_pub -U postgres -h $NSI_HOST -c "
    CREATE INDEX ON nsi_applied_ddf USING gist(geom);
    CREATE INDEX ON nsi_applied_ddf USING (oid);
"

# 6. Upload aggregation geometries.  
# Hex grids, county boundaries, etc.
# These can just be uploaded through QGIS, or through GCS in the steps above.

# 7. Any intermediate steps to aggregation geometries.
# i.e. get mangrove area, clip to shoreline buffer.

# 8a. Create AEB
# 8b. Create PV