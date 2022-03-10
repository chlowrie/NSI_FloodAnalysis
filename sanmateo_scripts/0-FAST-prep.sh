#0: This step prepares the raster outputs from Rae's model for use in FEMA FAST
# Primarily, transforming to WGS84 and converting from meters to feet
# The (A>0) helps with managing nodata values
gdalwarp -t_srs EPSG:4326 -srcnodata -32767 -dstnodata 0 flooddepth_${1}.tif flooddepth_${1}_wgs.tif
gdal_calc.py -A flooddepth_${1}_wgs.tif --calc="(A>0)*A*3.28" --NoDataValue=0 --outfile=flooddepth_${1}_wgs_ft.tif


# -- implied usage --:
# for i in 1e1 1e20 1e100 1r1 1r20 1r100
# do
#     bash 0-FAST-prep.sh $i
# done

# AFTER THIS, the next step is to run through FAST