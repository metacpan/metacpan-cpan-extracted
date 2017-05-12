#!/usr/bin/perl

use Test::More tests => 7;

use_ok("Tie::RegexpHash", 0.14);

# Rudimentary test suite of the examples given in the
# synopsis. Someday it will be oncorporated with POD::Tests.  Someday
# I'll write a real test suite. Someday....

my %hash;

tie %hash, 'Tie::RegexpHash';
ok(1);

$hash{ qr/^5(\s+|-)?gal(\.|lons?)?/i } = '5-GAL';
ok(1);

ok($hash{'5 gal'} eq "5-GAL");
ok($hash{'5GAL'}  eq "5-GAL");
ok($hash{'5  gallon'} eq "5-GAL");

$hash{'10 GALLON'} = '10-GAL';
ok($hash{'10 GALLON'} eq '10-GAL');
