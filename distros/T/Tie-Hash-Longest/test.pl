#!/usr/bin/perl -w

my $loaded;

use strict;

BEGIN { $| = 1; print "1..12\n"; }
END { print "not ok 1\n" unless $loaded; }

use Tie::Hash::Longest;

$loaded=1;
print "ok 1\n";

# Create a T::H::L and populate it
tie my %hash, 'Tie::Hash::Longest';
$hash{a} = 'ant';
$hash{b} = 'bear';
$hash{c} = 'crocodile';
$hash{ant} = 'a';
$hash{bear} = 'b';
$hash{crocodile} = 'c';

# Check to see if it stores and fetches correctly :-)
print "not " unless(
    join('', map { $_.$hash{$_} } sort keys %hash) eq
    'aantantabbearbearbccrocodilecrocodilec'
);
print "ok 2\n";

# check that longestkey/value work
print "not " unless(tied(%hash)->longestkey() eq 'crocodile');
print "ok 3\n";
print "not " unless(tied(%hash)->longestvalue() eq 'crocodile');
print "ok 4\n";

$hash{d}='D';

# Check that exists and delete work
print "not " unless(exists($hash{a}) && !exists($hash{e}));
print "ok 5\n";
print "not " unless(delete($hash{d}) && !exists($hash{d}));
print "ok 6\n";

# that delete shouldn't have even set a flag

# and that longestkey/value still work
print "not " unless(tied(%hash)->longestkey() eq 'crocodile');
print "ok 7\n";
print "not " unless(tied(%hash)->longestvalue() eq 'crocodile');
print "ok 8\n";

# now set flags by deleting the longest ...
delete $hash{crocodile};
delete $hash{c};

# check workingness ...
print "not " unless(tied(%hash)->longestkey() eq 'bear');
print "ok 9\n";
print "not " unless(tied(%hash)->longestvalue() eq 'bear');
print "ok 10\n";

# change something to make it the longest ...
$hash{a} = 'archaeopteryx';
print "not " unless(tied(%hash)->longestvalue() eq 'archaeopteryx');
print "ok 11\n";

# change something to make it shorter ...
$hash{a} = 'ant';
print "not " unless(tied(%hash)->longestvalue() eq 'bear');
print "ok 12\n";
