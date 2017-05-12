use strict;
use Test;

BEGIN { plan tests => 9 };

use Tie::SymlinkTree;

ok(1); #1

my %ref;
ok(tie my %test, 'Tie::SymlinkTree', './t/data'); #2

undef %test;
ok(join(",",keys %test),join(",",keys %ref)); #3

ok(exists $test{''},exists $ref{''}); #4

$test{'a'} = 'Dahut!';
$ref{'a'} = 'Dahut!';
ok($test{'a'},$ref{'a'}); #5

ok(exists $test{'a'},exists $ref{'a'}); #6

$test{".\x{feff}"} = 'Dahut!';
$ref{".\x{feff}"} = 'Dahut!';
ok($test{".\x{feff}"},$ref{".\x{feff}"}); #7

ok(exists $test{'foo'}{'bar'},exists $ref{'foo'}{'bar'}); #8

ok(join(",",sort keys %test),join(",",sort keys %ref)); #9

