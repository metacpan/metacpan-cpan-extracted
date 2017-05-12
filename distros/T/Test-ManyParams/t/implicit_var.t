#!/usr/bin/perl

use strict;
use warnings;

use Test::ManyParams;
use Test::More tests => 2 * 12;

use constant ARG => "passed arg";
use constant VAL => "no arg";

use constant TEST_ROUTINES => (
    sub {all_ok    {$_ eq ARG} [ARG], "all_ok(1 param)"},
    sub {all_are   {$_}  ARG,  [ARG], "all_are(1 param)"},
    sub {all_arent {$_}  VAL,  [ARG], "all_arent(1 param)"},
    sub {any_ok    {$_ eq ARG} [ARG], "any_ok(1 param)"},
    sub {any_is    {$_}  ARG,  [ARG], "any_is(1 param)"},
    
    sub {most_ok   {$_ eq ARG} [(ARG) x 10] => 2, "most_ok(1 param)"},

    sub {all_ok    {$_ eq VAL} [ [ARG], [ARG] ], "all_ok(2 param)"},
    sub {all_are   {$_}  VAL,  [ [ARG], [ARG] ], "all_are(2 param)"},
    sub {all_arent {$_}  ARG,  [ [ARG], [ARG] ], "all_arent(2 param)"},
    sub {any_ok    {$_ eq VAL} [ [ARG], [ARG] ], "any_ok(2 param)"},
    sub {any_is    {$_}  VAL,  [ [ARG], [ARG] ], "any_is(2 param)"},
    
    sub {most_ok   {$_ eq VAL} [ [ARG], [(ARG) x 10] ] => 2, "most_ok(2 param)"},
);

foreach my $testsub (TEST_ROUTINES) {
    local $_ = VAL;
    $testsub->();
    is $_, VAL, '$_ wasn\'t changed by $testsub';
}
