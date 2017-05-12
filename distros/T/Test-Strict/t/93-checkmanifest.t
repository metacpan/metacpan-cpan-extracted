use strict;
use warnings;
use Test::More;

eval 'use Test::CheckManifest 1.28';
plan skip_all => 'Test::CheckManifest 1.28 required to test MANIFEST' if $@;
ok_manifest();
