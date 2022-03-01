/*
	Get mangrove area per study unit.
	Mangroves are 2010 from Global Mangrove Watch
*/

-- FL Keys 
DROP TABLE IF EXISTS fl_keys_w_mangrove_area;
CREATE TABLE fl_keys_w_mangrove_area AS
SELECT 
	fl_keys.id as id,
	SUM(COALESCE(ST_Area(ST_Intersection(ST_Transform(fl_keys.geom, 32617), mang.geom_32617)), 0))*0.0001 as mangr_area_hr,
	fl_keys.geom
FROM 
	fl_key_aeb_draft fl_keys,
	public."GMW_2010_v2_clippedToFL" mang
GROUP BY 1,3;


-- Coastal Study Units, rest of Florida	
-- 15km crossshore clip
DROP TABLE IF EXISTS public.studyunits_5km_longshore_15km_crossshore_w_mangrovearea;
CREATE TABLE public.studyunits_5km_longshore_15km_crossshore_w_mangrovearea AS
SELECT 
	fl.id as id,
	SUM(COALESCE(ST_Area(ST_Intersection(fl.geom, mang.geom_32617)), 0))*0.0001 as mangr_area_hr,
	st_transform(fl.geom, 4326) as geom
FROM 
	public.studyunits_5km_longshore_15km_crossshore fl,
	public."GMW_2010_v2_clippedToFL" mang
GROUP BY 1,3


-- Coastal Study Units, rest of Florida	
-- 15km crossshore clip
DROP TABLE IF EXISTS public.studyunits_5km_w_mangrovearea;
CREATE TABLE public.studyunits_5km_w_mangrovearea AS
SELECT 
	fl.id as id,
	SUM(COALESCE(ST_Area(ST_Intersection(ST_Transform(fl.geom, 32617), mang.geom_32617)), 0))*0.0001 as mangr_area_hr,
	fl.geom as geom
FROM 
	public."FL_teselas_5km" fl,
	public."GMW_2010_v2_clippedToFL" mang
GROUP BY 1,3