parks.stamen.com social media harvesters
=========
Mapping social media activity in parks and other open spaces.

This repository contains the Heroku-based node.js social media harvesters.

Most of this code has been copied over from the [local-harvester branch](https://github.com/stamen/parks.stamen.com/tree/local-harvester) of the repository.

These harvesters collect geotagged content from Flickr, Foursquare, and Instagram. (currently Twitter is handled using a separate codebase).

More about the project
=====================

We are collecting all geocoded tweets, flickr photos, instagram photos, and foursquare venues (and check-in counts) within
the boundaries of every open space listed in the [California Protected Areas Database (CPAD)](http://calands.org), specifically
the CPAD "superunits". In this document "parks" and "open spaces" are used interchangeably, but we really mean "superunits".

Getting Started Locally
=============================

Setting up environment variables
-------------------------------------------
0. The application uses `foreman` and `make` to execute commands. Both use environment variables from the `.env` in this directory

0. Copy the `sample.env` to an `.env` file and fill it out appropriately. Some of these environment variables are harvester specific.
The `Makefile` requires a couple as noted below. The expected values for these variables will be talked about at different points in
the directions below in case you're unsure how to fill them out right now:

    ```bash
	DATABASE_URL=postgres://username@hostname:port/dbname # required
    TARGET_GEOJSON_OR_SHAPEFILE_ABSPATH=YOURPATHHERE # required
    FLICKR_CLIENT_ID=YOURCLIENTIDHERE
    FLICKR_CLIENT_SECRET=YOURCLIENTSECRETHERE
    FOURSQUARE_CLIENT_ID=YOURCLIENTIDHERE
    FOURSQUARE_CLIENT_SECRET=YOURCLIENTSECRETHERE
    INSTAGRAM_CLIENT_ID=YOURCLIENTIDHERE
    INSTAGRAM_CLIENT_SECRET=YOURCLIENTSECRETHERE
    INSTAGRAM_ACCESS_TOKEN=YOURACCESSTOKENHERE
    ```


Setting up the database tables
--------------------------------
0. Install `PostgreSQL 9.x` and `PostGIS 2.x` onto your developer system

0. Make sure the user you'll run commands as is also a [PostgreSQL Superuser](http://www.postgresql.org/docs/9.2/static/sql-createrole.html):

    ```bash
    rancho@trusty64$ sudo -u postgres psql -c "CREATE ROLE rancho LOGIN SUPERUSER;"
    ```

0. Make sure the `DATABASE_URL` environment variable is filled out, it's required by the `Makefile`:

    ```bash
    # currently the command to create the database defaults
    # to creating a database named after the user running the command
    # so the connection string `postgres://username@hostname:port/dbname` becomes
    DATABASE_URL=postgres://rancho@localhost:5432/rancho
    ```

0. Each harvester works with their own specific tables and a shared `superunits` table. For example, running the command
`make db/instagram_cpad` would produce these output tables for CPAD areas:

    ```bash
    # a table of CPAD superunit polygon geometries from a download CPAD shapefile
    cpad_2015b

    # a table of CPAD superunit geometries, the same ones above, with some column names changed
    superunits

    # smaller hexagon geometries derived from the table `superunits` geometries
    instagram_reqions

    # point geometries indicating the Lat/Lng of where Instagram photos were found
    instagram_photos
    ```

0. Let's play with some sample data in this repository to setup custom park areas

0. The `Makefile` command `db/instagram_generic` can load our own Shapefile and GeoJSON datasets into the `superunits` table
( it can also load Shapefiles inside of zipfiles ). There are several datasets in this repository's `testdata/` directory. They include:

    ```bash
    # a GeoJSON file in WGS-84
    test.json

    # a Shapefile in Pseudo Mercator
    test_epsg_3857

    # a zipfile that contains a Shapefile
    # called `test_epsg_3310.shp` in the root directory
    # in a California Albers
    test_epsg_3310.zip

    # a zipfile that contains a Shapefile
    # called `test_epsg_3310.shp` in a `subfolders/` directory
    # in a California Albers
    test_epsg_3310_in_subfolder.zip
    ```

0. Pick one dataset from `testdata/` and copy the absolute path to it. Because it has the most complicated path,
this example will use `test_epsg_3310_in_subfolder.zip`. Now update the `.env` file with the absolute path:

    ```bash
    # note the full path to the Shapefile includes the child folder
    TARGET_GEOJSON_OR_SHAPEFILE_ABSPATH=/usr/local/src/dev/harvester/testdata/test_epsg_3310_in_subfolder.zip/subfolders/test_epsg_3310.shp
    ```

0. Change to the root harvester directory, the one with the `Makefile` in it

0. Load the dataset and create the required Instagram tables:

    ```bash
    $ make db/instagram_generic
    ```

0. Here's the intended output tables and data we care about:

    ```bash
    $ psql -c "\d"
                   List of relations
     Schema |           Name           |   Type   | Owner
    --------+--------------------------+----------+--------
     public | instagram_photos         | table    | rancho
     public | instagram_regions        | table    | rancho
     public | superunits               | table    | rancho


    $ psql -c "SELECT count(*) from superunits;"
     count
    -------
        85
    (1 row)
    ```

Harvest Photos
------------------------------------------

With the database setup, the next move is to query Flickr, Foursquare or Instagram for photos related to the park areas that were loaded.
We can kick off these workers using `foreman` commands such as `$ foreman run instagram`. For future runs, note that the `foreman` harvester commands
will automatically setup the required tables and load the data that we manually loaded with `make` commands in the last few steps. So you can solely
rely on running them. Review the following harvester-specific sections for instructions on running each.

Foursquare harvesting
=======================

Harvesting the venues the first time (determining the existence of venues in each park) is the hard part. This should be re-run periodically to catch any new venues that appear. [more details needed here]

To collect venues the first time: 

Locally: `foreman run foursquare_venues`

To update the checkin counts for already-harvested venues:

Locally: `foreman run foursquare_update`

Flickr harvesting
===================

*	Command-line node app queries Flickr API for bounding box of each park. To run locally: `foreman run flickr`
*	Node app saves harvested photos to the table `flickr_photos`
*	Then `make flickrParkTable` uniquifies the table, and inserts the results into `park_flickr_photos`

Instagram harvesting
=======================

*	Command-line node app queries Instagram API for an array of circles covering of each park. To run locally: `foreman run instagram`
*	Node app saves harvested photos to the table `instagram_photos`
*	Then `make instagramParkTable` uniquifies the table, and inserts the results into `park_instagram_photos`

About the algorithms
======================

Add more here (including screenshots).

For a summary of what the different harvesters do, and how they do it, read this blog post: [Mapping the Intersection Between Social Media and Open Spaces in California](http://content.stamen.com/mapping_the_intersection_between_social_media_and_open_spaces_in_ca)

