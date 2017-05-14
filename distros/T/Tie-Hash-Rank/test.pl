#!/usr/bin/perl -w

my $loaded;

use strict;

BEGIN { $| = 1; print "1..4\n"; }
END { print "not ok 1\n" unless $loaded; }

use Tie::Hash::Rank;

$loaded=1;
print "ok 1\n";

# Create a T::H::R with all the defaults ...
tie my %scores, 'Tie::Hash::Rank';
%scores=qw(Adams 78 Davies 35 Edwards 84 Thomas 78);

# Check to see if it ranks correctly :-)
print "not " unless(
  $scores{Edwards} == 1 &&
  $scores{Adams}   == 2 &&
  $scores{Thomas}  == 2 &&
  $scores{Davies}  == 4
);
print "ok 2\n";

# Check that FIRSTKEY and NEXTKEY work
print "not " unless(join('', sort keys %scores) eq 'AdamsDaviesEdwardsThomas');
print "ok 3\n";

# Create a T::H::R with none of the defaults ...
tie %scores, 'Tie::Hash::Rank', (
	EQUALITYPREFIX => '*',
	EQUALITYSUFFIX => '=',
	RECALCULATE => 'onfetch',
	ALGORITHM => '$DATA{$a} <=> $DATA{$b}'
);
%scores=qw(Adams 78 Davies 35 Edwards 84 Thomas 78);

# Check to see if it still does everything right
print "not " unless(
  $scores{Edwards} eq '4' &&
  $scores{Adams}   eq '*2=' &&
  $scores{Thomas}  eq '*2=' &&
  $scores{Davies}  eq '1' &&
  join('', sort keys %scores) eq 'AdamsDaviesEdwardsThomas'
);
print "ok 4\n";

