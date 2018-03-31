#!perl

use strict;
use warnings;
use lib "lib";
use Test::More tests => 1;

ok 1;

=head1 NAME

sample - Using GetOpt::Long and Pod::Usage

=head1 SYNOPSIS

sample [-help] [-man]

=head1 OPTIONS

=over 8

=item B<-help>

Print a short usage synopsis (also -?).

=item B<-man>

Print the full command manual entry.

=back

=head1 DESCRIPTION

B<This program> will read the given input files and do something
useful with the contents thereof.

=head1 FOOBAR

This is a test.

=cut
