=head1 NAME

Time::OlsonTZ::Data - Olson timezone data

=head1 SYNOPSIS

    use Time::OlsonTZ::Data qw(olson_version);

    $version = olson_version;

    use Time::OlsonTZ::Data qw(
	olson_canonical_names olson_link_names olson_all_names
	olson_links olson_country_selection);

    $names = olson_canonical_names;
    $names = olson_link_names;
    $names = olson_all_names;
    $links = olson_links;
    $countries = olson_country_selection;

    use Time::OlsonTZ::Data qw(olson_tzfile);

    $filename = olson_tzfile("America/New_York");

=head1 DESCRIPTION

This module encapsulates the Olson timezone database, providing binary
tzfiles and ancillary data.  Each version of this module encapsulates
a particular version of the timezone database.  It is intended to be
regularly updated, as the timezone database changes.

=cut

package Time::OlsonTZ::Data;

{ use 5.006; }
use warnings;
use strict;

our $VERSION = "0.<?version_numeric?>";

use parent "Exporter";
our @EXPORT_OK = qw(
	olson_version olson_code_version olson_data_version
	olson_canonical_names olson_link_names olson_all_names
	olson_links
	olson_country_selection
	olson_tzfile
);

my($datavol, $datadir);
sub _data_file($) {
	my($upath) = @_;
	unless(defined $datadir) {
		require File::Spec;
		($datavol, $datadir, undef) =
			File::Spec->splitpath($INC{"Time/OlsonTZ/Data.pm"});
	}
	my @nameparts = split(/\//, $upath);
	my $filename = pop(@nameparts);
	return File::Spec->catpath($datavol,
		File::Spec->catdir($datadir, "Data", @nameparts), $filename);
}

=head1 FUNCTIONS

=head2 Basic information

=over

=item olson_version

Returns the version number of the database that this module encapsulates.
Version numbers for the Olson database currently consist of a year number
and a lowercase letter, such as "C<2010k>"; they are not guaranteed to
retain this format in the future.

=cut

use constant olson_version => "<?version_lettered?>";

=item olson_code_version

Returns the version number of the code part of the database that this
module encapsulates.  This is now always the same as the value returned
by L</olson_version>.  Until late 2012 the database was distributed in
two parts, each with their own version number, so this was a distinct
piece of information.

=cut

use constant olson_code_version => "<?version_lettered?>";

=item olson_data_version

Returns the version number of the data part of the database that this
module encapsulates.  This is now always the same as the value returned
by L</olson_version>.  Until late 2012 the database was distributed in
two parts, each with their own version number, so this was a distinct
piece of information.

=cut

use constant olson_data_version => "<?version_lettered?>";

=back

=head2 Zone metadata

=over

=item olson_canonical_names

Returns the set of timezone names that this version of the database
defines as canonical.  These are the timezone names that are directly
associated with a set of observance data.  The return value is a reference
to a hash, in which the keys are the canonical timezone names and the
values are all C<undef>.

=cut

my $cn = q(+{ map { ($_ => undef) } <?canonical_names_list?> });
sub olson_canonical_names() {
	$cn = eval($cn) || die $@ if ref($cn) eq "";
	return $cn;
}

=item olson_link_names

Returns the set of timezone names that this version of the database
defines as links.  These are the timezone names that are aliases for
other names.  The return value is a reference to a hash, in which the
keys are the link timezone names and the values are all C<undef>.

=cut

sub olson_links();

my $ln;
sub olson_link_names() {
	return $ln ||= { map { ($_ => undef) } keys %{olson_links()} };
}

=item olson_all_names

Returns the set of timezone names that this version of the
database defines.  These are the L</olson_canonical_names> and the
L</olson_link_names>.  The return value is a reference to a hash, in
which the keys are the timezone names and the values are all C<undef>.

=cut

my $an;
sub olson_all_names() {
	return $an ||= {
		%{olson_canonical_names()},
		%{olson_link_names()},
	};
}

=item olson_links

Returns details of the timezone name links in this version of the
database.  Each link defines one timezone name as an alias for some
other timezone name.  The return value is a reference to a hash, in
which the keys are the aliases and each value is the canonical name of
the timezone to which that alias refers.  All such canonical names can
be found in the L</olson_canonical_names> hash.

=cut

my $li = q(+<?links_hash?>);
sub olson_links() {
	$li = eval($li) || die $@ if ref($li) eq "";
	return $li;
}

=item olson_country_selection

Returns information about how timezones relate to countries, intended
to aid humans in selecting a geographical timezone.  This information
is derived from the C<zone.tab> and C<iso3166.tab> files in the database
source.

The return value is a reference to a hash, keyed by (ISO 3166 alpha-2
uppercase) country code.  The value for each country is a hash containing
these values:

=over

=item B<alpha2_code>

The ISO 3166 alpha-2 uppercase country code.

=item B<olson_name>

An English name for the country, possibly in a modified form, optimised
to help humans find the right entry in alphabetical lists.  This is
not necessarily identical to the country's standard short or long name.
(For other forms of the name, consult a database of countries, keying
by the country code.)

=item B<regions>

Information about the regions of the country that use distinct
timezones.  This is a hash, keyed by English description of the region.
The description is empty if there is only one region.  The value for
each region is a hash containing these values:

=over

=item B<olson_description>

Brief English description of the region, used to distinguish between
the regions of a single country.  Empty string if the country has only
one region for timezone purposes.  (This is the same string used as the
key in the B<regions> hash.)

=item B<timezone_name>

Name of the Olson timezone used in this region.  The named timezone is
guaranteed to exist in the database, but not necessarily as a canonical
name (it may be a link).  Typically, where there are aliases or identical
canonical zones, a name is chosen that refers to a location in the
country of interest.

=item B<location_coords>

Geographical coordinates of some point within the location referred to in
the timezone name.  This is a latitude and longitude, in ISO 6709 format.

=back

=back

This data structure is intended to help a human select the appropriate
timezone based on political geography, specifically working from a
selection of country.  It is of essentially no use for any other purpose.
It is not strictly guaranteed that every geographical timezone in the
database is listed somewhere in this structure, so it is of limited use
in providing information about an already-selected timezone.  It does
not include non-geographic timezones at all.  It also does not claim
to be a comprehensive list of countries, and does not make any claims
regarding the political status of any entity listed: the "country"
classification is loose, and used only for identification purposes.

=cut

my $cs;
sub olson_country_selection() {
	return $cs ||= do {
		my $fn = _data_file("country_selection.tzp");
		$@ = ""; do($fn) || die($@ eq "" ? "$fn: $!" : $@);
	}
}

=back

=head2 Zone data

=over

=item olson_tzfile(NAME)

Returns the pathname of the binary tzfile (in L<tzfile(5)> format)
describing the timezone named I<NAME> in the Olson database.  C<die>s if
the name does not exist in this version of the database.  The tzfile
is of at least version 2 of the format, and so does not suffer a Y2038
(32-bit time_t) problem.

=cut

sub olson_tzfile($) {
	my($tzname) = @_;
	$tzname = olson_links()->{$tzname} if exists olson_links()->{$tzname};
	unless(exists olson_canonical_names()->{$tzname}) {
		require Carp;
		Carp::croak("no such timezone `$tzname' ".
			"in the Olson @{[olson_version]} database");
	}
	return _data_file($tzname.".tz");
}

=back

=head1 BUGS

The Olson timezone database probably contains errors in the older
historical data.  These will be corrected, as they are discovered,
in future versions of the database.

Because legislatures commonly change civil timezone rules, in
unpredictable ways and often with little advance notice, the current
timezone data is liable to get out of date quite quickly.  The Olson
timezone database is frequently updated to keep it accurate for current
dates.  Frequently updating installations of this module from CPAN should
keep it similarly accurate.

For the same reason, the future data in the database is liable to be
very inaccurate.  The database includes, for each timezone, the current
best guess regarding its future behaviour, usually consisting of the
current rules being left unchanged indefinitely.  (In most cases it is
unlikely that the rules will actually never be changed, but the current
rules still constitute the best guess available of future behaviour.)

Because this module is intended to be frequently updated, long-running
programs (such as clock displays) will experience the module being
updated while in use.  This can happen with any module, but is of
particular interest with this one.  The behaviour in this situation is
not guaranteed, but here is a guide to current behaviour.  The running
module code is of course not influenced by the C<.pm> file changing.
The ancillary data is all currently stored in the module code, and so
will be equally unaffected.  Tzfiles pointed to by the module, however,
will change visibly.  Newly reading a tzfile is liable to see a newer
version of the zone's data than the module's metadata suggests.  A tzfile
could also theoretically disappear, if a zone's canonical name changes
(so the former canonical name becomes a link).  To avoid weirdness,
it is recommended to read in all required tzfiles near the start of
a program's run, so that it doesn't matter if the files subsequently
change due to an update.

=head1 SEE ALSO

L<App::olson>,
L<DateTime::TimeZone::Olson>,
L<DateTime::TimeZone::Tzfile>,
L<Time::OlsonTZ::Download>,
L<tzfile(5)>

=head1 AUTHOR

The Olson timezone database was compiled by Arthur David Olson, Paul
Eggert, and many others.  It is maintained by the denizens of the mailing
list <tz@iana.org> (formerly <tz@elsie.nci.nih.gov>).

The C<Time::OlsonTZ::Data> Perl module wrapper for the database was
developed by Andrew Main (Zefram) <zefram@fysh.org>.

=head1 COPYRIGHT

The Olson timezone database is is the public domain.

The C<Time::OlsonTZ::Data> Perl module wrapper for the database is
Copyright (C) 2010, 2011, 2012, 2013, 2014, 2017, 2018, 2019, 2020
Andrew Main (Zefram) <zefram@fysh.org>.

=head1 LICENSE

No license is required to do anything with public domain materials.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
