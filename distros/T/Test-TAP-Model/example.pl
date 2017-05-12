#!/usr/bin/perl

use strict;
use warnings;

use Test::TAP::Model;
use Data::Dumper;

my $straps = Test::TAP::Model->new;

$straps->run_tests(@ARGV ? @ARGV : glob("t/*.t"));

print Dumper($straps->structure);

__END__

=pod

=head1 NAME

example.pl - a simple serializing test harness

=head1 SYNOPSIS

	$ perl example.pl t/foo.t t/bar.t > results.pl

This program will run either it's command line arguments or C<glob("t/*.t")>,
and use L<Data::Dumper> to print the results to standard output.

=head1 SEE ALSO

yaml_harness in the pugs repo

=cut
