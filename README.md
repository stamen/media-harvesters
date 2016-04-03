www.caliparks.org Social Media Harvesters
==================================================
Mapping social media activity in parks and other open spaces. This repository contains the Heroku-based Node.js social
media harvesters. Most of this code has been copied over from the [local-harvester branch](https://github.com/stamen/parks.stamen.com/tree/local-harvester) of the repository.
These harvesters collect geotagged content from Flickr, Foursquare, and Instagram. (currently Twitter is handled using a separate codebase)

  * [About the Project](#about-the-project)
  * [Getting Started Locally](#getting-started-locally)
    * [overview of environment variables](#overview-of-environment-variables)
    * [overview of the database tables](#overview-of-the-database-tables)
    * [harvest ye photos](#harvest-ye-photos)
  * [Setting Up CPAD Superunits DB](#setting-up-cpad-superunits-db)
  * [Setting Up Custom Shapefiles and GeoJSON DB](#setting-up-custom-shapefiles-and-geojson-db)
  * [Foursquare Harvesting](#foursquare-harvesting)
  * [Flickr Harvesting](#flickr-harvesting)
  * [Instagram Harvesting](#instagram-harvesting)
  * [About the Algorithms](#about-the-algorithms)


About the Project
=======================
We are collecting all geocoded tweets, flickr photos, instagram photos, and foursquare venues (and check-in counts) within
the boundaries of every open space listed in the [California Protected Areas Database (CPAD)](http://calands.org), specifically
the CPAD "superunits". In this document "parks" and "open spaces" are used interchangeably, but we really mean "superunits".

Getting Started Locally
=======================
The following steps have been tested on Mac and Debian systems

overview of environment variables
-------------------------------------------
0. The application uses `foreman` and `make` to execute commands. Both use environment variables from the `.env` file
in the root directory. Copy the `sample.env` to an `.env` file and fill it out. In various spots the directions talk about
the expected values if you're unsure how to fill them out right now:

    ```bash
	DATABASE_URL=postgres://username@hostname:port/dbname # required
    TARGET_GEOJSON_OR_SHAPEFILE_ABSPATH=YOURPATHHERE
    FLICKR_CLIENT_ID=YOURCLIENTIDHERE
    FLICKR_CLIENT_SECRET=YOURCLIENTSECRETHERE
    FOURSQUARE_CLIENT_ID=YOURCLIENTIDHERE
    FOURSQUARE_CLIENT_SECRET=YOURCLIENTSECRETHERE
    INSTAGRAM_ACCESS_TOKEN=YOURACCESSTOKENHERE
    ```

overview of the database tables
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

0. Each harvester works with their own specific tables and a shared `superunits` table. For example, the output tables
that are generated to run the Instagram harvester for CPAD park areas are listed below. For more information about
setting up the CPAD database read the section [Setting Up CPAD Superunits DB](#setting-up-cpad-superunits-db)

    ```bash
    # a table of CPAD superunit polygon geometries from a downloaded CPAD shapefile
    cpad_2015b

    # a table of CPAD superunit geometries, the same ones above, with some column names changed
    superunits

    # smaller hexagon geometries derived from the table `superunits` geometries
    instagram_reqions

    # point geometries indicating the (lng,lat) of where Instagram photos were found after running the harvesters
    instagram_photos
    ```

0. Let's play with some sample data in this repository to setup custom park areas based on our own datasets.
Read the section [Setting Up Custom Shapefiles and GeoJSON](#setting-up-custom-shapefiles-and-geojson-db)

0. Move on to the [Harvesting Ye Photos Section](#harvest-ye-photos)

harvest ye photos
------------------------------------------
With the database setup, the next step is to run the Node.js harvesters which query Flickr, Foursquare or Instagram for photos related to the loaded park areas.
We can kick off these harvesters using `foreman` commands such as:

    ```bash
    $ foreman run instagram
    ```

For future consideration, note that the `foreman` harvester commands
will run the table creation and loading `make` commands that we manually called in [Getting Started Locally](#getting-started-locally) above. So you can
rely on only running `foreman` from now on. Review the harvester-specific sections [Foursquare Harvesting](#foursquare-harvesting),
[Flickr Harvesting](#flickr-harvesting), [Instagram Harvesting](#instagram-harvesting) for instructions on running each


Setting Up CPAD Superunits DB
==============================
If you want to use CPAD park geometries to seed the database then all you have to do is run this command for the appropriate harvester.
Here we are setting up CPAD geometries for an Instagram harvester:

```bash
make db/instagram_cpad
```


Setting Up Custom Shapefiles and GeoJSON DB
============================================
Use your own park geometries to seed the database and influence where the harvesters collect social media. Let's play with some sample data in this repository to setup custom park areas

0. The `Makefile` command `db/instagram_generic` can load our own Shapefile or GeoJSON datasets into the `superunits` table
( it can also load a Shapefile inside a zipfile ). There are several datasets in this repository's `testdata/` directory. They include:

    ```bash
    # a GeoJSON file in WGS-84
    test.json

    # a Shapefile in Pseudo Mercator
    test_epsg_3857

    # a zipfile that contains a Shapefile
    # called `test_epsg_3310.shp` in the root directory
    # in California Albers
    test_epsg_3310.zip

    # a zipfile that contains a Shapefile
    # called `test_epsg_3310.shp` in a `subfolders/` directory
    # in California Albers
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

Foursquare Harvesting
=======================
Harvesting the venues the first time (determining the existence of venues in each park) is the hard part. This should be re-run periodically to catch any new venues that appear. [more details needed here]

To collect venues the first time: 

Locally: `foreman run foursquare_venues`

To update the checkin counts for already-harvested venues:

Locally: `foreman run foursquare_update`

Flickr Harvesting
===================
*	Command-line node app queries Flickr API for bounding box of each park. To run locally: `foreman run flickr`
*	Node.js app saves harvested photos to the table `flickr_photos`
*	Then `make flickrParkTable` uniquifies the table, and inserts the results into `park_flickr_photos`

Instagram Harvesting
=======================
0. In late 2015 Instagram started requiring an `access_token` for API requests. If you don't have one, go sign up for an Instagram account and
then [register the harvester](https://www.instagram.com/developer/clients/manage/). Registering your application should
generate a `Cliend ID` and `Client Secret` that you'll want save for later. The instructions below are a summary of those found on
[Instagram](https://www.instagram.com/developer/authentication/):

0. Now authorize the harvester we registered to make requests on behalf of your Instagram account placing this URL into your browser.
Note: the `redirect_uri` has to match the `redirect_uri` you specified in the registration form. Likewise, `client_id` should match your
`Client ID`.

    ```bash
    https://api.instagram.com/oauth/authorize/?client_id=CLIENT-ID&redirect_uri=REDIRECT-URI&response_type=token&scope=basic+public_content
    ```

0. At this point, Instagram presents the user with a login screen and then a confirmation screen where you grant the harvester. Once granted,
you will be redirected to the `redirect_uri` in the URL and there should be a parameter called `auth_token` at the end of it. Here's what that redirect URL
might look like if your `redirect_uri` was registered as `localhost`:

    ```bash
    http://localhost/#access_token=1234456.1234567.13423546766708
    ```

0. Take the `access_token` and save it the `.env` as `INSTAGRAM_ACCESS_TOKEN`:

    ```bash
    INSTAGRAM_ACCESS_TOKEN=1234456.1234567.13423546766708
    ```
0. The harvester is all setup to run against Instagram. Change to the root harvester directory, the one with the `Makefile` in it.
To run locally type `foreman run instagram`. The CLI node app queries Instagram API for an array of circles covering each park.

0. The app saves harvested photos to the table `instagram_photos`

About the Algorithms
======================

Add more here (including screenshots).

For a summary of what the different harvesters do, and how they do it, read this blog post: [Mapping the Intersection Between Social Media and Open Spaces in California](http://content.stamen.com/mapping_the_intersection_between_social_media_and_open_spaces_in_ca)

