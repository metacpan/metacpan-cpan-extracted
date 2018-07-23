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

GetOptions(\%options, qw(
    profile
    kvkNumber=s
    branchNumber=s
    apiKey=s
    mainBranch
    help|h
));

if ($options{help}) {
    pod2usage({verbose => 1, exitval => 0});
}

if (!keys %options) {
    pod2usage({verbose => 1, exitval => 1});
}

my $api = WebService::KvKAPI->new(
    api_key => delete $options{apiKey},
);

if (delete $options{mainBranch}) {
    $options{restrictToMainBranch} = 1;
}


if ($options{profile}) {
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

version 0.004

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
