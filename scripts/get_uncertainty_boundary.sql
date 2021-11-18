WITH q1 AS (
    SELECT ST_Union(geom) geom
    FROM florida_county_bounds
)
SELECT 
    
