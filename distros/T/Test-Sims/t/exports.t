#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

# A class without any other exports.
{

    package Flowers;
    use Test::Sims;

    make_rand flower  => [qw(Rose Daisy Ed Bob)];
    make_rand numbers => [qw(1 2 3 4 5)];
}

# A class which already has exports
{

    package Things;

    use base "Exporter";
    our @EXPORT_OK = "stuff";

    use Test::Sims;

    sub stuff { 42 }

    make_rand stuff => [qw(this that other thing)];

    ::is_deeply \@Things::ISA, ["Exporter"], "Exporter only added to \@ISA once";
}

# Test :rand export tag
{

    package Foo;

    Flowers->import(":rand");

    ::can_ok( __PACKAGE__, "rand_flower" );
    ::can_ok( __PACKAGE__, "rand_numbers" );
}

# Test rand functions are in @EXPORT_OK
{

    package Bar;

    Flowers->import("rand_flower");

    ::can_ok( __PACKAGE__, "rand_flower" );
}

# Test rand functions are not exported by default.
{

    package Baz;

    Flowers->import();

    ::ok( !Baz->can("rand_flower"), "does not export rand by default" );
}

# Test existing exports are preserved
{

    package Wiffle;

    Things->import( "stuff", "rand_stuff" );

    ::is( stuff(), 42, "\@EXPORT_OK preserved" );
    ::can_ok( Wiffle => "rand_stuff" );
}

done_testing();
