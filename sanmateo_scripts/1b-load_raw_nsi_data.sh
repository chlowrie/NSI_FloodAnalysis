#1.2: UPLOAD STEP
# Likely need to replace the path to your own FAST outputs
for i in 0e1 0e20 0e100 0r1 0r20 0r100 1e1 1e20 1e100 1r1 1r20 1r100
do
psql -d sanmateo -c "
    COPY nsi_applied_ddf
    FROM '/mnt/d/FAST/UDF/SanMateoNSI_wgs84_prepped_flooddepth_${i}_wgs_ft.csv'
    DELIMITER ','
    CSV HEADER;
"
done
