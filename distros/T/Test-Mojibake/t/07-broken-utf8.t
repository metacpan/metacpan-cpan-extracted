#!perl -T
use strict;
use warnings qw(all);

use Test::More;
use Test::Mojibake;

## no critic (ProhibitPackageVars, ProtectPrivateSubs)

$Test::Mojibake::use_xs = 0;

# borrowed from BRADFITZ/Unicode-CheckUTF8-1.03/t/01-all.t
my @tests = (
    ["0-unknown"        => 0 => \"\x80"],
    ["0-bad"            => 0 => \"\xc0\xc1"],
    ["1-simple"         => 1 => \"a"],
    ["2-simple"         => 1 => \"Some string!"],
    ["3-german"         => 2 => \"Stra\xc3\x9fe"],
    ["4-german-cut"     => 0 => \"Stra\xc3"],
    ["5-null"           => 0 => \"\0"],
    ["5-null2"          => 0 => \"this has a \0 null"],
    ["6-outrange"       => 0 => \"\xff"],
    ["7-overlong-1"     => 0 => \"\xc0\xaf"],
    ["8-overlong-2"     => 0 => \"\xe0\x80\xaf"],
    ["9-overlong-3"     => 0 => \"\xf0\x80\x80\xaf"],
    ["10-overlong-4"    => 0 => \"\xf8\x80\x80\x80\xaf"],
    ["11-overlong-5"    => 0 => \"\xfc\x80\x80\x80\x80\xaf"],
);

ok(Test::Mojibake::_detect_utf8($_->[2]) == $_->[1], $_->[0])
    for @tests;

done_testing(scalar @tests);
