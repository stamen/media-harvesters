DROP TABLE IF EXISTS superunits;
CREATE TABLE superunits AS
  SELECT
    ogc_fid AS superunit_id,
    geom
  FROM superunits_temp