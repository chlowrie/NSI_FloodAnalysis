# Requires prep script to have run
# Also requires going through the (somewhat annoying) steps here: https://cloud.google.com/sql/docs/postgres/import-export/importing
# 1. Copy local files to Cloud Storage
gsutil cp FAST_outputs/prepped/* gs://nsi-fast-outputs

# 2. Add Cloud Storage to Postgres DB
for i in w wo
    do
    for j in 010 025 050 100
    do
        gcloud sql import csv florida-mangroves-econ-analysis gs://nsi-fast-outputs/FL_${i}_${j}_wgs84.csv --database=postgres --table=nsi_applied_ddf
    done
done

# pg_dump -U postgres -h 35.226.20.131 postgres --format=t > db_backup_0916.sql 

psql -d postgres -U postgres -h 35.226.20.131 -c "
    ALTER TABLE nsi_applied_ddf
    ADD COLUMN geom geometry;

    UPDATE nsi_applied_ddf
    SET geom = ST_SetSRID(ST_POINT(longitude, latitude), 4326);
"