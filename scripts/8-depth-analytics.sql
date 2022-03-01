-- SELECT bddf_id, cnt, cnt / sum(cnt) over ()
-- FROM
-- (
-- SELECT bddf_id, count(*) as cnt
-- FROM nsi_with_aeb
-- GROUP BY 1
-- )q
-- GROUP BY 1,2
-- ORDER BY 3 DESC;

-- SELECT depth_m, split_part(grid_name, '_', 1) as mangr_stat, split_part(grid_name, '_', 5) as rp, bddf_id, sum(loss) as total_loss, sum(loss / (split_part(grid_name, '_', 5)::float)) as aeb
-- FROM
-- (
-- 	SELECT 
-- 		floor(depth_grid / 3.2) as depth_m, 
-- 		bddf_id,
-- 		bldg_loss_usd + content_loss_usd + inv_loss_usd as loss,
-- 		grid_name
-- -- 		split_part(grid_name, '_', 5) as rp,
-- -- 		CASE
-- -- 			WHEN split_part(grid_name, '_', 1) like 'without' THEN 'without'
-- -- 			ELSE 'with' END as mangrove_status
-- 	FROM nsi_applied_ddf 
-- )q
-- GROUP BY 1,2,3,4
SELECT 
	bddf_id,
	depth_with,
	depth_without,
	sum(loss_with) as loss_with,
	sum(loss_without) as loss_without,
	count(*)
FROM
(
SELECT 
	oid,
	bddf_id,
	sum(depth_with) as depth_with,
	sum(depth_without) as depth_without,
	sum(loss_with) as loss_with,
	sum(loss_without) as loss_without
FROM
(
SELECT oid,
	bddf_id, 
	CASE 
		WHEN split_part(grid_name, '_', 1) LIKE 'with2010'
		THEN floor(least(depth_in_struc, 10))
		ELSE null
	END as depth_with,
	CASE 
		WHEN split_part(grid_name, '_', 1) LIKE 'without'
		THEN floor(least(depth_in_struc, 10))
		ELSE null
	END as depth_without,
	CASE 
		WHEN split_part(grid_name, '_', 1) LIKE 'with2010'
		THEN bldg_loss_usd + content_loss_usd + inv_loss_usd
		ELSE null
	END as loss_with,
	CASE 
		WHEN split_part(grid_name, '_', 1) LIKE 'without'
		THEN bldg_loss_usd + content_loss_usd + inv_loss_usd
		ELSE null
	END as loss_without,
	split_part(grid_name, '_', 5) as rp
FROM nsi_applied_ddf
WHERE split_part(grid_name, '_', 5)::int = 50
)q
GROUP BY 1,2
)q
GROUP BY 1,2,3


SELECT 
	mang, rp, bddf_id,
	sum(cost*perc_dmg_1 )as dmg_basic_grid,
	sum(cost*perc_dmg_1 / (rp::float)) as aeb_basic_grid,
	sum(cost*perc_dmg_2 )as dmg_basic_struc,
	sum(cost*perc_dmg_2 / (rp::float)) as aeb_basic_struc,
	sum(dmg_adv) as dmg_adv,
	sum(dmg_adv / (rp::float)) as aeb_adv
FROM
	(
	SELECT 
		cost + content_cost_usd + inventory_cost_usd as cost,
		least(depth_grid / (5.0 * 3.2), 1.0) as perc_dmg_1,
		least(depth_in_struc / (5.0 * 3.2), 1.0) as perc_dmg_2,
		split_part(grid_name, '_', 1) as mang,
		split_part(grid_name, '_', 5)::int as rp,
		bldg_loss_usd + content_loss_usd + inv_loss_usd as dmg_adv,
		bddf_id
	FROM
		nsi_applied_ddf
	)q
GROUP BY 1,2,3
-- SELECT * FROM nsi_applied_ddf WHERE bddf_id = 658 LIMIT 100
