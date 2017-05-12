#!perl -T

use strict;
use warnings;
use Test::More;

eval "use Test::CheckManifest 1.01";
plan skip_all => "Test::CheckManifest 1.01 required" if $@;
ok_manifest();
