#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Tests for the Perl modules L<Tie::Subset::Array>.

=head1 Author, Copyright, and License

Copyright (c) 2018 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut

use FindBin ();
use lib $FindBin::Bin;
use Tie_Subset_Testlib;

use Test::More;

BEGIN { use_ok 'Tie::Subset::Array' }

## no critic (RequireTestLabels)

# tie-ing
#             0  1  2  3  4  5  6  7  8  9 10 11
my @array = (11,22,33,44,55,66,77,88,99);
tie my @subset, 'Tie::Subset::Array', \@array, [2..5,7,9,11];
# 0 1 2 3 4 5 6
# 2,3,4,5,7,9,11
is_deeply \@subset, [33,44,55,66,88,undef,undef] or diag explain \@subset;
is @subset, 7;
is_deeply \@array, [11,22,33,44,55,66,77,88,99];
isa_ok tied(@subset), 'Tie::Subset::Array';

subtest 'Tie::Subset' => sub {
	use_ok 'Tie::Subset';
	# basically a copy of the "tie-ing" tests, but with Tie::Subset instead of ::Array
	my @aa = (11,22,33,44,55,66,77,88,99);
	tie my @ss, 'Tie::Subset', \@aa, [2..5,7,9,11];
	is_deeply \@ss, [33,44,55,66,88,undef,undef];
	is @ss, 7;
	is_deeply \@aa, [11,22,33,44,55,66,77,88,99];
	isa_ok tied(@ss), 'Tie::Subset::Array';
};

# Fetching
is $subset[0], 33;
is $subset[1], 44;
is $subset[2], 55;
is $subset[3], 66;
is $subset[4], 88;
is $subset[5], undef;
is $subset[6], undef;
is $subset[7], undef;
is $subset[8], undef;
is $subset[-1], undef;

# Storing
ok $subset[1]=42;
{
	# author tests make warnings fatal, disable that here
	no warnings FATAL=>'all'; use warnings;  ## no critic (ProhibitNoWarnings)
	my @w = warns {
		ok !defined($subset[7]=999);
		ok !defined($subset[11]=999);
	};
	is grep({/\bstoring values outside of the subset\b/i} @w), 2;
}
is_deeply \@subset, [33,42,55,66,88,undef,undef] or diag explain \@subset;
is_deeply \@array, [11,22,33,42,55,66,77,88,99];
$subset[-1]=123;
is_deeply \@subset, [33,42,55,66,88,undef,123] or diag explain \@subset;
is_deeply \@array, [11,22,33,42,55,66,77,88,99,undef,undef,123];
@subset[5,3]=(456);
is_deeply \@subset, [33,42,55,undef,88,456,123] or diag explain \@subset;
is_deeply \@array, [11,22,33,42,55,undef,77,88,99,456,undef,123];

#TODO Later: Tests for "not supported" features

done_testing;
