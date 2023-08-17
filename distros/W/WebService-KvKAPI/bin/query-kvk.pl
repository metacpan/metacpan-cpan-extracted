#!perl
use warnings;
use strict;

# This file is covered by the EUPL, please see the LICENSE file for more
# information
#
# ABSTRACT: Query the Dutch Chamber of Commerce via the CLI
# PODNAME: query-kvk.pl

use Data::Dumper;
use Getopt::Long;
use Pod::Usage;
use WebService::KvKAPI;

my %options = ();

GetOptions(
    \%options, qw(
        help|h
        man|m
        hostname=s

        spoof
        profile|profiel|basic-profile=i
        owner|eigenaar=i
        mainLocation|main-location|hoofdvestiging=i
        locations|vestigingen=i
        geoData|geo

        location_profile|location-profile|vestigingsprofiel=i

        apiKey|api-key=s
        kvkNummer|kvkNumber|kvk-nummer=s
        rsin=s
        vestigingsnummer|branchNumber=s
        handelsnaam|tradeName=s
        straatnaam|street=s
        postcode|postalCode=s
        huisnummer|houseNumber=s
        plaats|woonplaats|stad|city=s
        type=s
        InclusiefInactieveRegistraties|inactief|inactive
        pagina|page=i
        aantal|amount=i
    )
);

if ($options{man}) {
    pod2usage({ verbose => 2, exitval => 0 });
}
if ($options{help}) {
    pod2usage({ verbose => 1, exitval => 0 });
}
if (!keys %options) {
    pod2usage({ verbose => 1, exitval => 1 });
}

my $api_key = delete $options{apiKey};

if (!$api_key && !$options{spoof}) {
    warn "Enabling spoofmode, no api key set", $/;
    $options{spoof} = 1;
}

my $api = WebService::KvKAPI->new(
    $options{hostname} ? (api_host => $options{hostname}) : (),
    $options{spoof} ? (spoof => 1) : ( api_key => $api_key ),
);
delete $options{spoof};

my $result;

if (!keys %options) {
    pod2usage({ verbose => 1, exitval => 1 });
}

if (exists $options{profile}) {
    $result = $api->get_basic_profile($options{profile}, $options{geoData});
}
elsif (exists $options{owner}) {
    $result = $api->get_owner($options{owner}, $options{geoData});
}
elsif (exists $options{mainLocation}) {
    $result
        = $api->get_main_location($options{mainLocation}, $options{geoData});
}
elsif (exists $options{locations}) {
    $result = $api->get_main_location($options{locations});
}

# location profile
elsif (exists $options{location_profile}) {
    $result = $api->get_location_profile($options{location_profile}, $options{geoData});
}
# default to search
else {
    $result = $api->search(%options);
}

if ($result) {
    print Dumper $result;
}
else {
    print "No results for your query.", $/;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

query-kvk.pl - Query the Dutch Chamber of Commerce via the CLI

=head1 VERSION

version 0.105

=head1 SYNOPSIS

query-kvk.pl [ OPTIONS ]

=head1 DESCRIPTION

Query the Kamer van Koophandel API via the command line. This tool supports all
the calls that the KvK has made publicly available. By default you can search
the KvK if you provide search terms.

Please see L<the KvK developer page|https://developers.kvk.nl> for more
information on how to use the API.

=head1 NAME

query-kvk.pl - Query the KvK API from the CLI

=head1 OPTIONS

=over

=item * --help

This help

=item * --spoof

Use the test API from the KvK, does not require an API key

=item * --hostname

Use a different hostname instead of the B<api.kvk.nl>.

=item * --api-key | --apikey | --apiKey

The API key from the KvK

=item * --profile | --profiel <coc-number>

Get the basic profile of the given company.

=item * --owner | --eigenaar <coc-number>

Get the owner details of the given company.

=item * --main-location | --hoofdvestiging | --mainLocation <coc-number>

Get the main location of the given company

=item * --locations | --vestigingen <coc-number>

Get all the locations of the given company

=item * --location-profile | --vestigingsprofiel <location-number>

Get the location profile of a location ID

=item * --geo | --geoData

Include geo data in the result

=back

=head2 SEARCH OPTIONS

The following options are here for searching purposes and are used when none of
the other options above are used.

=over

=item * --kvknummer | --coc-number | --kvk-nummer | --kvkNumber <number>

A KvK number

=item * --location-number | --vestigingsnummer | --branchNumber <number>

A branch number

=item * --tradename | --handelsnaam | --tradeName <name>

The tradename at the KvK

=item * --street | --straat

The streetname

=item * --house-number | --huisnummer | --houseNumber

The house number

=item * --postal-code | --postcode | --zipcode

The zipcode

=item * --city | --stad | --woonplaats | --plaats

The city

=item * --type

Search of particular types.  Allowed values are: C<hoofdvestiging>,
C<nevenvestiging>, C<rechtspersoon>.

=item * --InclusiefInactieveRegistraties | --inactive | --inactief

Include inactive registrations

=item * --page | --pagina

Select the page. Defaults to 1

=item * --amount | --aantal

Select the amount of results you get back. Defaults to 10.

=back

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Mintlab / Zaaksysteem.nl / xxllnc, see CONTRIBUTORS file for others.

This is free software, licensed under:

  The European Union Public License (EUPL) v1.1

=cut
