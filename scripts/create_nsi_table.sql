DROP TABLE IF EXISTS nsi_applied_ddf;
CREATE TABLE nsi_applied_ddf (
    OID bigint,
    st_name text,
    cbfips text,
    dam_cat text,
    occ_type text,
    n_stories real,
    basement text,
    bldg_type text,
    first_floor_ht real,
    cost real,
    content_cost real,
    val_other real,
    val_vehic real,
    medyrblt real,
    fipsentry real,
    foundation text,
    postfirm float,
    teachers real,
    students real,
    schoolname text,
    pop2pmu65 real,
    pop2pmo65 real,
    pop2amu65 real, 
    pop2amo65 real,
    latitude real,
    longitude real,
    occ text,
    area text,
    foundation_type real,
    depth_grid real,
    depth_in_struc real,
    fl_exp real,
    soid text,
    bddf_id real,
    bldg_dmg_perc real,
    bldg_loss_usd real,
    content_cost_usd real,
    cddf_id real,
    cont_damage_perc real,
    content_loss_usd real,
    inventory_cost_usd real,
    iddf_id real,
    inv_dmg_perc real,
    inv_loss_usd real,
    debris_id text,
    debris_fin real,
    debris_str real,
    debris_fnd real,
    debris_tot real,
    restor_days_min real,
    restor_days_max real,
    grid_name text
);