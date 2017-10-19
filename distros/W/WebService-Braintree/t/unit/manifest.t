#!perl -T
# vim: sw=4 ts=4 ft=perl

use 5.010_001;
use strictures 1;

use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

eval "use Test::CheckManifest 0.9";
plan skip_all => "Test::CheckManifest 0.9 required" if $@;

ok_manifest();
