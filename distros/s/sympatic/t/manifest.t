#!perl -T

use strict;
use warnings;
use Test::More;
use Class::Load qw(try_load_class);

$ENV{RELEASE_TESTING} or
    plan skip_all => q{no $RELEASE_TESTING (Author tests not required for installation)};

try_load_class 'Test::CheckManifest', {-version => 0.9}
    or plan skip_all => "Test::CheckManifest 0.9 required";
Test::CheckManifest::ok_manifest(
    { filter => [ qr(/\.*) ] }
);
