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

my %options = ();

GetOptions(\%options, qw(
    help|h
    apiKey=s
    raw=s
    mainBranch
    branch
    legalPerson
    profile
    kvkNumber=s
    branchNumber=s
    street=s
    houseNumber=s
    postalCode=s
    city=s
    tradeName=s
    q=s
    rsin=s
    pure_rsin
));

if ($options{help}) {
    pod2usage({verbose => 1, exitval => 0});
}

if (!keys %options) {
    pod2usage({verbose => 1, exitval => 1});
}

my $profile_search = delete $options{profile};
my $api_key        = delete $options{apiKey};
my $raw            = delete $options{raw};

my $api;

if ($api_key) {
    use WebService::KvKAPI;
    $api = WebService::KvKAPI->new(
        api_key => $api_key,
        $options{pure_rsin}
        ? (pure_rsin => $options{pure_rsin})
        : (),
    );
}
else {
    use WebService::KvKAPI::Spoof;
    print "Using spoof mode, no api key given", $/;

    $api = WebService::KvKAPI::Spoof->new(
        api_key => 'spoofmode',
        $options{pure_rsin}
        ? (pure_rsin => $options{pure_rsin})
        : (),
    );
}

if ($raw) {
    print Dumper $api->api_call($raw, \%options);
}
elsif ($profile_search) {
    print Dumper $api->profile(%options);
}
else {
    print Dumper $api->search(%options);
}

__END__

=pod

=encoding UTF-8

=head1 NAME

query_kvk.pl - Query the Dutch Chamber of Commerce via the CLI

=head1 VERSION

version 0.011

=head1 SYNOPSIS

query_kvk.pl --help [ OPTIONS ]

=head1 NAME

query_kvk.pl - Generate the KvK from the CLI

=head1 OPTIONS

=over

=item * --help

This help

=item * --profile

Get the C<profile> of the company (detailed information). When not provided it
does a full search.

=item * --kvkNumber

A KvK number

=item * --branchNumber

A branch number

=item * --tradeName

The tradename at the KvK

=item * --street

The streetname

=item * --houseNumber

The house number

=item * --postalCode

The zipcode

=item * --city

The city

=item * --apiKey

The API key from the KvK

=item * --mainBranch

Limit searches to main branches only. Watch out with I<Foundations> as they
often don't have a main branch.

=back

=head1 AUTHOR

Wesley Schwengle <wesley@mintlab.nl>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Mintlab / Zaaksysteem.nl.

This is free software, licensed under:

  The European Union Public License (EUPL) v1.1

=cut
