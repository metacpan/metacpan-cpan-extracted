#!/usr/bin/perl

use Test::More;

eval "use Test::Pod::Coverage tests => 1";
plan skip_all => "Test::Pod::Covarage required for testing POD Coverage" if $@;
pod_coverage_ok ("Tk::Clock",
    { also_private => [ qr{^ Populate $}x ], },
    "Tk::Clock is covered");
