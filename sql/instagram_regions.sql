DROP TABLE IF EXISTS instagram_regions;
CREATE TABLE instagram_regions (
  id serial PRIMARY KEY,
  center geometry(Point, 4326) NOT NULL,
  radius double precision NOT NULL,
  locked_at timestamp with time zone,
  count integer NOT NULL DEFAULT 0,
  last_fetched timestamp,
  split boolean NOT NULL DEFAULT false,
  geom geometry(Polygon, 3857) NOT NULL UNIQUE
);

CREATE INDEX instagram_regions_geom_gist ON instagram_regions USING GIST(geom);

INSERT INTO instagram_regions (center, radius, geom)
  SELECT
    ST_Transform(ST_Centroid(geom), 4326) AS center,
    5000::double precision AS radius,
    geom
  FROM (
    SELECT GetIntersectingHexagons(ST_SetSRID(ST_Extent(geom), (SELECT ST_SRID(geom) FROM superunits LIMIT 1)), 5000) geom
    FROM superunits
  ) AS _;
