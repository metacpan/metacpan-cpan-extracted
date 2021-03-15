#!perl

use strict;
use warnings;

use Test::More;
BEGIN {
  $] >= 5.008 or plan skip_all => "Test::CheckManifest requires perl 5.8";
  plan skip_all => 'Set AUTHOR_TESTING environmental variable to test this.' unless $ENV{AUTHOR_TESTING};
}
use Test::CheckManifest;

ok_manifest();
