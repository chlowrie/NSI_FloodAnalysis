# https://stackoverflow.com/questions/9633114/unix-script-to-remove-the-first-line-of-a-csv-file/58783212

# Warp rasters to 4326
for i in with2010 without
do
for j in 010 025 050 100
do
gdalwarp -t_srs EPSG:4326 ${i}_TWL_TC_Tr_${j}_feet.tif ${i}_TWL_TC_Tr_${j}_feet_4326.tif
done
done

# Remove header of rasters
tail -q -n +2 $IN > $OUT