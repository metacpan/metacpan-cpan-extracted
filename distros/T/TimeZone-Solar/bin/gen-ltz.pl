#!/usr/bin/perl 
# ABSTRACT: generate longitude-based solar timezone info files
# PODNAME: gen-ltz.pl
# CREATED: 09/14/2020
# part of Perl implementation of solar timezones library
#
# Copyright © 2020-2022 Ian Kluft. This program is free software; you can
# redistribute it and/or modify it under the terms of the GNU General Public
# License Version 3. See  https://www.gnu.org/licenses/gpl-3.0-standalone.html

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2018);
## use critic (Modules::RequireExplicitPackage)

use utf8;
use autodie;
use feature qw(say);
use Carp    qw(croak);

# generate standard 1-hour-wide (15 degrees longitude) time zones
# input parameter: integer hours from GMT in the range
# These correspond to the GMT+x/GMT-x time zones, except with boundaries defined by longitude lines.
sub gen_hour_tz
{
    my $hour = int(shift);
    if ( $hour < -12 or $hour > 12 ) {
        croak "hour parameter must be -12 to +12 inclusive";
    }

    # Hours line up with time zones. So it's a equal to time zone offset.
    my $sign       = ( $hour >= 0 ) ? "+" : "-";
    my $offset_hr  = abs($hour);
    my $offset_min = 0;

    # generate strings from time zone parameters
    my $zone_abbrev = sprintf( "%s%s%02d",  "Solar", $sign, $offset_hr );
    my $zone_name   = sprintf( "%s/%s",     "Solar", $zone_abbrev );
    my $offset_str  = sprintf( "%s%d:%02d", $sign,   $offset_hr, $offset_min );

    # output time zone data
    say "# Solar Time by hourly increment: $sign $offset_hr";
    say "# " . join( "\t", qw(Zone NAME ), "", qw(STDOFF RULES FORMAT [UNTIL]) );
    say join( "\t", "Zone", $zone_name, $offset_str, "-", $zone_abbrev );
    say "";
    return;
}

# generate longitude-based solar time zone info
# input parameter: integer degrees of longitude in the range 180 to -180, Solar Time Zone centered on the meridian,
# including one half degree either side of the meridian. Each time zone is named for its 1-degree-wide range.
# The exception is at the Solar Date Line, where +12 and -12 time zones are one half degree wide.
sub gen_lon_tz
{
    my $deg = int(shift);
    if ( $deg < -180 or $deg > 180 ) {
        croak "deg parameter must be -180 to +180 inclusive";
    }

    # use integer degrees to compute time zone parameters: longitude, east/west sign and minutes offset
    # $deg>=0: positive degrees (east longitude), straightforward assignments of data
    # $deg<0: negative degrees (west longitude)
    my $lon  = abs($deg);
    my $ew   = ( $deg >= 0 ) ? "E" : "W";
    my $sign = ( $deg >= 0 ) ? ""  : "-";

    # derive time zone parameters from 4 minutes of offset for each degree of longitude
    my $offset     = 4 * abs($deg);
    my $offset_hr  = int( abs($offset) / 60 );
    my $offset_min = abs($offset) % 60;

    # generate strings from time zone parameters
    my $zone_abbrev = sprintf( "%s%03d%s",  "Lon",   $lon, $ew );
    my $zone_name   = sprintf( "%s/%s",     "Solar", $zone_abbrev );
    my $offset_str  = sprintf( "%s%d:%02d", $sign,   $offset_hr, $offset_min );

    # output time zone data
    say "# Solar Time by degree of longitude: $lon $ew";
    say "# " . join( "\t", qw(Zone NAME ), "", qw(STDOFF RULES FORMAT [UNTIL]) );
    say join( "\t", "Zone", $zone_name, $offset_str, "-", $zone_abbrev );
    say "";
    return;
}

#
# main
#

# generate solar time zones in increments of 15 degrees of longitude (STHxxE/STHxxW)
# standard 1-hour-wide time zones
foreach my $hour ( -12 .. 12 ) {
    gen_hour_tz($hour);
}

# generate solar time zones in incrememnts of 4 minutes / 1 degree of longitude (STLxxxE/STxxxW)
# hyperlocal 4-minute-wide time zones for conversion to/from niche uses of local solar time
foreach my $deg ( -180 .. 180 ) {
    gen_lon_tz($deg);
}

exit 0;

__END__

=pod

=encoding UTF-8

=head1 NAME

gen-ltz.pl - generate longitude-based solar timezone info files

=head1 VERSION

version 0.2.1

=head1 USAGE

    gen-ltz.pl > output-file

=head1 OPTIONS

none

=head1 EXIT STATUS

The program returns the standard Unix exit codes of 0 for success and non-zero for errors.

=head1 LICENSE

TimeZone::Solar is Open Source software licensed under the GNU General Public License Version 3.
See L<https://www.gnu.org/licenses/gpl-3.0-standalone.html>.

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Ian Kluft <ian.kluft+github@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ian Kluft.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
