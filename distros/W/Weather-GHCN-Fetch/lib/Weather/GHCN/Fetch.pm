# Weather::GHCN::Fetch.pm - class for creating applications that fetch NOAA GHCN data

## no critic (Documentation::RequirePodAtEnd)
## no critic [ValuesAndExpressions::ProhibitVersionStrings]
## no critic [TestingAndDebugging::RequireUseWarnings]

use v5.18;  # minimum for Object::Pad

package Weather::GHCN::Fetch;

our $VERSION = 'v0.0.009';

=head1 NAME

Weather::GHCN::Fetch - Access the NOAA GHCN Global Historical Climatology Network repository

=head1 VERSION

version v0.0.009

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
scripts.  Here are some examples:

B<List the weather stations in NY state with "New York" in the name:>

C<ghcn_fetch -country US -state NY -location "New York">

B<List the New York weather stations active between 1900 and 1920:>

C<ghcn_fetch -cou US -st NY -location "New York" -active 1900-1920>

B<Report the yearly max, min and average temperatures at JFK airport:>

C<ghcn_fetch yearly -cou US -st NY -location "New York JFK">

B<Report the monthly max, min and average temperatures at JFK airport:>

C<ghcn_fetch monthly -cou US -st NY -location "New York JFK">

B<Report the daily max, min and average temperatures at JFK airport:>

C<ghcn_fetch daily -cou US -st NY -location "New York JFK">

B<Launch the GUI for an options dialog>

C<ghcn_fetch -gui>

(requires B<Tk> and B<Tk::Getopt> to be installed)

B<Get documentation on all the options>

C<ghcn_fetch -help>

B<Find the 5-day heatwaves at the JFK airport station:>

C<ghcn_fetch id -cou US -st NY -location "New York JFK" | ghcn_extremes>

B<Find the 3-day coldwaves (<= 15C) at the JFK airport station:>

C<ghcn_fetch id -cou US -st NY -location "New York JFK" | ghcn_extremes -cold -ndays 3 -limit -15>

B<For each year between 1900 and 1950, count the number of active weather stations in NY state:>

C<ghcn_fetch id -cou US -st NY -active 1900-1950 | ghcn_station_counts>

=head1 AUTHOR

Gary Puckering (jgpuckering@rogers.com)

=head1 LICENSE AND COPYRIGHT

Copyright 2022, Gary Puckering

=cut

1;
