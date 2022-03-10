-- All scenarios should have the same building count, provided the came from the same NSI data
-- If there is ever a difference, something went wrong
SELECT grid_name, count(*) FROM nsi_applied_ddf GROUP BY 1;

------------------------------------------------------------
------------------------------------------------------------
------------------------------------------------------------

-- bddf_id = 0 corresponds to 'not flooded' under that scenario
-- This is the only case where a building can have two bddf_ids (if one of them is zero).
-- If there are two nonzero bddf_id values, you've made a mistake in running FAST
-- Likely by running with CoastalA in some scenarios, CoastalV in others.

SELECT oid, count(distinct bddf_id)
FROM nsi_applied_ddf
WHERE bddf_id != 0
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- EXPECTED RETURN: 
-- some building id, 1
-- If the count != 1, something went wrong

------------------------------------------------------------
------------------------------------------------------------
------------------------------------------------------------


-- Theoretically, the number of buildings flooded should monotonically increase with return period
-- Note that as of March 9th, 2022, this isn't the case with the San Mateo outputs.  RP20 has fewer buildings flooded than RP1.
SELECT 
    restoration_status, slr, return_period, count(*)
FROM 
    nsi_applied_ddf
WHERE 
    bddf_id != 0
GROUP BY 
    restoration_status, slr, return_period
ORDER BY 
    restoration_status, 
    slr ASC, 
    return_period ASC;

------------------------------------------------------------
------------------------------------------------------------
------------------------------------------------------------