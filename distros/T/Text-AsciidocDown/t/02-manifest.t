use strict;
use warnings;

use Test::More;

eval "use Test::CheckManifest 0.9";
plan skip_all => 'Test::CheckManifest 0.9 required for MANIFEST testing' if $@;
plan skip_all => 'MANIFEST test only for distribution maintainer'
  unless -e 'MANIFEST' && -e 'Makefile.PL';

manifest_ok();