#!perl
use warnings;
use strict;

# This file is covered by the EUPL, please see the LICENSE file for more
# information
#
# ABSTRACT: Query the Dutch Chamber of Commerce via the CLI
# PODNAME: query_kvk.pl

use Data::Dumper;
use Getopt::Long;
use Pod::Usage;
use WebService::KvKAPI;

my %options = ();

GetOptions(
    \%options, qw(
        help|h
        man|m

        spoof
        profile|profiel=i
        owner|eigenaar=i
        mainLocation|main-location|hoofdvestiging=i
        locations|vestigingen=i
        geoData|geo

        location_profile|vestigingsprofiel=i

        apiKey|apikey=s
        kvkNummer|kvkNumber=s
        rsin=s
        vestigingsnummer|branchNumber=s
        handelsnaam|tradeName=s
        straatnaam|street=s
        postcode|postalCode=s
        huisnummer|houseNumber=s
        plaats|woonplaats|stad|city=s
        type=s
        InclusiefInactieveRegistraties|inactief|inactive
        pagina=i
        aantal=i
    )
);

if ($options{help}) {
    pod2usage({ verbose => 1, exitval => 0 });
}
if ($options{man}) {
    pod2usage({ verbose => 2, exitval => 0 });
}

my $api_key = delete $options{apiKey};

if (!$api_key && !$options{spoof}) {
    pod2usage({ verbose => 1, exitval => 1 });
}

my $api = WebService::KvKAPI->new(
    $options{spoof} ? (spoof => 1) : ( api_key => $api_key ),
);
my $result;

if (!keys %options) {
    pod2usage({ verbose => 1, exitval => 1 });
}

if ($options{profile}) {
    $result = $api->get_basic_profile($options{profile}, $options{geoData});
}
elsif ($options{owner}) {
    $result = $api->get_owner($options{owner}, $options{geoData});
}
elsif ($options{mainLocation}) {
    $result
        = $api->get_main_location($options{mainLocation}, $options{geoData});
}
elsif ($options{locations}) {
    $result = $api->get_main_location($options{locations});
}

# location profile
elsif ($options{location_profile}) {
    $result = $api->get_location_profile($options{location_profile});
}

# default to search
else {
    $result = $api->search(%options);
}

print Dumper $result;

__END__

=pod

=encoding UTF-8

=head1 NAME

query_kvk.pl - Query the Dutch Chamber of Commerce via the CLI

=head1 VERSION

version 0.101

=head1 SYNOPSIS

query_kvk.pl [ OPTIONS ]

=head1 DESCRIPTION

Query the Kamer van Koophandel API via the command line. This tool supports all
the calls that the KvK has made publicly available. By default you can search
the KvK if you provide search terms.

Please see L<the KvK developer page|https://developers.kvk.nl> for more
information on how to use the API.

=head1 NAME

query_kvk.pl - Query the KvK API from the CLI

=head1 OPTIONS

=over

=item * --help

This help

=item * --api-key | --apikey | --apiKey

The API key from the KvK

=item * --profile | --profiel <coc-number>

Get the basic profile of the given company.

=item * --owner | --eigenaar <coc-number>

Get the owner details of the given company.

=item * --locations | --vestigingen <coc-number>

Get all the locations of the given company

=item * --location-profile | --vestigingsprofiel <location-number>

=back

=head2 SEARCH OPTIONS

The following options are here for searching purposes and are used when none of
the other options above are used.

=over

=item * --coc-number | --kvk-nummer | --kvkNumber <number>

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

=item * --city | --stad | --woonplaats

The city

=back

=head1 AUTHOR

Wesley Schwengle <wesley@mintlab.nl>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Mintlab / Zaaksysteem.nl.

This is free software, licensed under:

  The European Union Public License (EUPL) v1.1

=cut
