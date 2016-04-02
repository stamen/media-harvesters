DROP VIEW IF EXISTS cpad_superunits;
CREATE VIEW cpad_superunits AS
  SELECT
    suid_nma AS unit_id,
    park_name AS unit_name,
    access_typ,
    mng_ag_id as manager_id,
    park_url,
    mng_agency as mng_agncy,
    layer,
    label_name,
    geom
  FROM CPAD_2015b;
