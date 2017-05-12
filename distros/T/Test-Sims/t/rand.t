#!/usr/bin/perl

use strict;
use warnings;

use lib 't/lib';
use Test::More;
use MyTest;

my $names = [qw(Mal Zoe Jayne Kaylee Inara River Simon Wash Zoe Book)];

{
    package Sim::Firefly;

    use Test::Sims;

    make_rand name => $names;
}

{
    package Foo;

    Sim::Firefly->import("rand_name");

    ::rand_ok 1, 1, [ rand_name() ],                     $names, "no args";
    ::rand_ok 2, 5, [ rand_name( min => 2, max => 5 ) ], $names, "min/max";
    ::rand_ok 1, 5, [ rand_name( max => 5 ) ],           $names, "just max";
    ::rand_ok 0, 2, [ rand_name( min => 0, max => 2 ) ], $names, "min 0/max";

    my $crew = rand_name();
    ::like $crew, qr/^[a-zA-Z]+$/, "works in scalar context";
}

done_testing();
