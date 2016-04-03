DROP TABLE IF EXISTS foursquare_regions;
CREATE TABLE foursquare_regions (
  id serial PRIMARY KEY,
  width double precision NOT NULL,
  locked_at timestamp with time zone,
  count integer NOT NULL DEFAULT 0,
  last_fetched timestamp,
  split boolean NOT NULL DEFAULT false,
  geom geometry(Polygon, 4326) NOT NULL
);

CREATE INDEX foursquare_regions_geom_gist ON foursquare_regions USING GIST(geom);

INSERT INTO foursquare_regions (geom, width)
  WITH cells AS (
    SELECT CDB_RectangleGrid(ST_Transform(ST_SetSRID(ST_Extent(geom), 3857), 4326), 0.1, 0.1) geom
    FROM superunits
  )
  SELECT
    DISTINCT cells.geom,
    0.1 AS width
  FROM cells
  INNER JOIN superunits ON ST_Intersects(superunits.geom, ST_Transform(cells.geom, ST_SRID(superunits.geom)));
