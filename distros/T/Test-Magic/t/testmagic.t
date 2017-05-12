#!/usr/bin/perl
use strict;
use warnings;
use Scalar::Util 'weaken';
use Test::More tests => 20;
BEGIN {unshift @INC, '../lib'}
require Test::Magic;

diag "Test::Magic $Test::Magic::VERSION";

my ($plan, @tap) = split /^(?=ok|not ok)/m, (-d 't' ? `$^X t/testmagic.sub`
                                                    : `$^X testmagic.sub`);

BAIL_OUT 'error running subtests' unless $plan =~ /1\.\.20/;

my %plan = (
     1 => [qr/got: 1.+expected: 2/s],
     2 => [qr/got: 3.+expected: 7/s],
     3 => 'pass',
     4 => 'pass',
     5 => [qr/2.+<.+1/s],
     6 => 'pass',
     7 => 'pass',
     8 => [qr/str.+tt/s],
     9 => 'pass',
    10 => 'pass',
    11 => [qr/0.+>=.+1/s],
    12 => [qr/str.+matches.+(?:xism|\?\^):t/s],
    13 => 'pass',
    14 => 'pass',
    15 => [qr/'x'.+(?:xism|\?\^):y/s],
    16 => [qr/'x'.+gt.+'z'/s],
    17 => 'pass',
    18 => [qr/got.+'1'.+expected.+'2'/s],
    19 => [qr/got.+'1 2 3'.+expected.+ARRAY/s],
    20 => [qr/got.+\bb\b.+'2'.+expected.+\bb\b.+'3'/s],
);

for my $plan (@plan{sort {$a <=> $b} keys %plan}) {
    my $test = shift @tap;
    my ($name) = $test =~ /-(.+)/;
    if ($plan eq 'pass') {
        like $test, qr/^ok/, $name;
    } else {
        for my $check (@$plan) {
            like $test, $check, $name;
        }
    }
}
