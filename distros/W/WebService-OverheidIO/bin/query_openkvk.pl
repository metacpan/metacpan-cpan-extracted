#!perl
use warnings;
use strict;

# This file is covered by the EUPL, please see the LICENSE file for more
# information
#
# ABSTRACT: Query the openKvK via the CLI
# PODNAME: query_openkvk.pl

use Data::Dumper;
use Getopt::Long;
use Pod::Usage;
use WebService::OverheidIO::KvK;

my %options = ();

GetOptions(\%options, qw(
    help|h
    apiKey=s
    query=s
    dossiernummer=s
    vestigingsnummer=s
    handelsnaam=s
    straat=s
    huisnummer=s
    postcode=s
));

if ($options{help}) {
    pod2usage({verbose => 1, exitval => 0});
}

my $api_key = delete $options{apiKey};
my $query   = delete $options{query};

if (!$api_key) {
    die "Need an API key";
}

my $api = WebService::OverheidIO::KvK->new(
    key => $api_key,
);

if (!keys %options) {
    pod2usage({verbose => 1, exitval => 1});
}


print Dumper $api->search($query// undef, filter => \%options);

__END__

=pod

=encoding UTF-8

=head1 NAME

query_openkvk.pl - Query the openKvK via the CLI

=head1 VERSION

version 1.2

=head1 SYNOPSIS

query_kvk.pl --help [ OPTIONS ]

=head1 NAME

query_kvk.pl - Generate the KvK from the CLI

=head1 OPTIONS

=over

=item * --help

This help

=item * --dossiernummer

A KvK number

=item * --vestigingsnummer

A branch number

=item * --handelsnaam

The name of the company

=item * --straat

Street

=item * --postcode

The zipcode

=item * --query

A freeform query possibility

=item * --apiKey

The API key from the OverheidIO website

=back

=head1 AUTHOR

Wesley Schwengle <wesley@mintlab.nl>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Mintlab BV.

This is free software, licensed under:

  The European Union Public License (EUPL) v1.1

=cut
