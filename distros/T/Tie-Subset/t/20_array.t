#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Tests for the Perl modules L<Tie::Subset::Array>.

=head1 Author, Copyright, and License

Copyright (c) 2018-2023 Hauke Daempfling (haukex@zero-g.net).

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

# Exists
ok exists $subset[0];
ok !exists $subset[20];
SKIP: {
	skip "work around some kind of apparent regression in 5.14 and 5.16", 1
		if $] ge '5.014' && $] lt '5.018';
	ok !exists $subset[-1];
}

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

# Errors
ok exception { tie my @foo, 'Tie::Subset::Array', [1..3], [0], 'foo' };
ok exception { tie my @foo, 'Tie::Subset::Array', {}, [0] };
ok exception { tie my @foo, 'Tie::Subset::Array', [1..3], {} };
ok exception { tie my @foo, 'Tie::Subset::Array', [1..3], ['a'] };
ok exception { tie my @foo, 'Tie::Subset::Array', [1..3], [\0] };
ok exception { tie my @foo, 'Tie::Subset' };
ok exception { Tie::Subset::TIEARRAY('Tie::Subset::Foobar', []) };

# Not Supported
{
	no warnings FATAL=>'all'; use warnings;  ## no critic (ProhibitNoWarnings)
	ok 1==grep { /\b\Qnot (yet) supported\E\b/ } warns {
		$#subset = 1;
	};
	SKIP: {
		skip "test fails on pre-5.24 Perls", 1 if $] lt '5.024';
		# Since it's only here for code coverage, it's ok to skip it
		ok 1==grep { /\b\Qnot (yet) supported\E\b/ } warns {
			@subset = ();
		};
	}
	ok 1==grep { /\b\Qnot (yet) supported\E\b/ } warns {
		push @subset, 'a';
	};
	ok 1==grep { /\b\Qnot (yet) supported\E\b/ } warns {
		pop @subset;
	};
	ok 1==grep { /\b\Qnot (yet) supported\E\b/ } warns {
		shift @subset;
	};
	ok 1==grep { /\b\Qnot (yet) supported\E\b/ } warns {
		unshift @subset, 'z';
	};
	ok 1==grep { /\b\Qnot (yet) supported\E\b/ } warns {
		splice @subset, 0, 2, 'x';
	};
	ok 1==grep { /\b\Qnot (yet) supported\E\b/ } warns {
		delete $subset[0];
	};
}

# Untie
untie @subset;
is_deeply \@subset, [];

done_testing;
