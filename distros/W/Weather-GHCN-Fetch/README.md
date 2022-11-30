# Weather::GHCN - modules for accessing the NOAA Global Historical Climatology Network database 

The Weather::GHCN module library provides classes that can be used to develop
applications that access weather data collected by the U.S. National
Oceanic and Atmospheric Administration.  The modules enable the
retrieval of the surface station weather data and metadata that NOAA
publishes as the Global Historical Climatology Network (GHCN) data
repository.  This repository is fed by weather data sources from around
the world.

## NOAA GHCN data sources

The main data sources are:

  https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/all/
  https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/ghcnd-stations.txt
  https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/ghcnd-inventory.txt

NOAA also provides a readme file here:

https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt

## Application scripts

This package includes a set of application scripts, as well as modules
they are built from (see lib\Weather\GHCN\App).  These scripts, which
will be installed in perl/site/bin (or the bin for your local::lib) 
are fully functional applications built around the Weather::GHCN::App
modules:

- **ghcn_fetch**, fetches station and/or weather data for reporting
- **ghcn_extremes**, reports temperature extremes
- **ghcn_station_counts**, counts active stations by year
- **ghcn_cacheutil**, lists and removes cache content

The output from the first three scripts is tab-separated and designed 
for easy import into Excel (or similar) for analysis, reporting and 
charting. **ghcn_extremes** and **ghcn_station_counts** are designed 
to take the output from **ghcn_fetch** via pipeline.  

## Testing

The **t** folder will be initialized during installation with a 
**ghcn_cache** folder.  This folder contains cached web pages from the
 NOAA ghcn/daily folders noted above so that tests which load station or 
weather data will execute more quickly.  Also so that no internet 
access is required for the install.  

Tests were designed to use data that should be stable as time 
progresses.  If tests are failing due to data, you can refresh the 
cache by running:

    perl 00_initialize_test_env.t clean

This causes the script to delete the cache, forcing the subsequent 
tests to do fetches of the latest pages when required.  (When the 
**clean** argument is omitted, as it is when **prove** runs the tests,
 it leaves the cache alone and the subsequent tests will use cached 
data.)

Unfortunately, the cache provided with the package contains files
that are unreadable on non-Windows platforms.  Consequently, the
cache must be cleared so it can be loaded with fresh pages.  
When 00_initialize_test_env.t, it will detect whether it is on a
non-Windows platform and, if so, will enable 'clean'.  Thus,
testing on non-Windows takes longer and requires internet access.

Hopefully, in a future release, this limitation will be removed.