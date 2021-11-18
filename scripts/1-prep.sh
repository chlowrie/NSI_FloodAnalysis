# for i in `ls FAST_outputs/FL*`
# do
#     sed -i '1d' ${i}
# done

# psql -h 35.226.20.131 -d postgres -U postgres -f scripts/create_nsi_table.sql

pg_dump -t nsi_sample_area -h 35.226.20.131 -d postgres -U postgres | psql -h 35.226.20.131 -d mangroves_pub -U postgres

export PGPASSWORD=roqfuf-0xidti

for i in `ls flood_extents/*.tif`
do
    raster2pgsql -I -t 500x500 ${i} | \
        psql -d postgres -U postgres -h 35.226.20.131
done

# pg_dump -h 35.226.20.131 -d postgres -U postgres -t county_aeb_draft | \
    # psql -h 35.226.20.131 -U postgres mangroves_pub

pg_dump -h 35.226.20.131 -d postgres -U postgres -t florida_inland_w_flood_buffer_15k | \
    psql -h 35.226.20.131 -U postgres mangroves_pub