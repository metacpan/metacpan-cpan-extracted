# Weather::GHCN::Fetch.pm - class for creating applications that fetch NOAA GHCN data

## no critic (Documentation::RequirePodAtEnd)
## no critic [ValuesAndExpressions::ProhibitVersionStrings]
## no critic [TestingAndDebugging::RequireUseWarnings]

use v5.18;  # minimum for Object::Pad

package Weather::GHCN::Fetch;

our $VERSION = 'v0.0.011';

=head1 NAME

Weather::GHCN::Fetch - Access the NOAA GHCN Global Historical Climatology Network repository

=head1 VERSION

version v0.0.011

=head1 DESCRIPTION

The B<Weather::GHCN >module library provides classes that can be used to develop
applications that access weather data collected by the U.S. National
Oceanic and Atmospheric Administration.  The modules enable the
retrieval of the surface station weather data and metadata that NOAA
publishes as the Global Historical Climatology Network (GHCN) data
repository, which is fed by weather data sources from around
the world.

=head1 NOAA GHCN DATA SOURCES

The main data sources are:

=over 4

=item

L<https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/all/>

=item

L<https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/ghcnd-stations.txt>

=item

L<https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/ghcnd-inventory.txt>

=back

NOAA also provides a readme file here:

=over 4

=item

L<https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt>

=back

=head1 APPLICATION SCRIPTS

The B<Weather::GHCN::Fetch> package includes fully functional application
scripts that are based on B<Weather::GHCN::App> modules.  These are:

=over 4

=item B<ghcn_fetch>

Fetches station and/or weather data for reporting.

=item B<ghcn_extremes>

Reports temperature extremes, including heatwaves and coldwaves, from
station-level daily weather retrieved by B<ghcn_fetch>.

=item B<ghcn_station_counts>

Take a list of stations found by B<ghcn_fetch>, examines the active
date range, and produces a count of stations that were active in
each year of the range.

=back

The output from all scripts is tab-separated and designed for easy
import into Excel (or similar) for analysis, reporting and charting.
B<ghcn_extremes> and B<ghcn_station_counts> are designed to take the
output from B<ghcn_fetch> via pipeline.

Each script has a B<-help> option that documents its features and options.

=head1 APPLICATION MODULES

The application scripts are mostly just a thin veneer over corresponding
modules in the B<Weather::GHCN::App> namespace.  That and the POD
necessary for B<-help> and B<-usage>.

The application scripts are built upon the API modules, primarily
B<Weather::GHCN::StationTable>.

=head1 API MODULES

The API modules are the heart of the package, encapsulating the logic
necessary for accessing the GHCN repository, downloading station
metadata and daily weather data, managing the plethora of options
supported by the B<ghcn_fetch> application, etc.

The modules are:

    Weather::GHCN::StationTable
    Weather::GHCN::Station
    Weather::GHCN::Common
    Weather::GHCN::CountryCodes
    Weather::GHCN::Measures
    Weather::GHCN::Options
    Weather::GHCN::TimingStats

This module, B<Weather::GHCN::Fetch>, is actually just a stub that
provides documentation and a primary module name for the distribution.

=head1 EXAMPLES

The primary usefulness of this package comes from the application
scripts.  For example of the types of reports that can be generated,
see the EXAMPLES section of the help documentation for B<ghcn_fetch>.

=head1 AUTHOR

Gary Puckering (jgpuckering@rogers.com)

=head1 LICENSE AND COPYRIGHT

Copyright 2022, Gary Puckering

=cut

1;
