#!perl -T

use strict;
use warnings;

use Test::More;
use Test::DistManifest;

unless ($ENV{RELEASE_TESTING}) {
  plan skip_all => 
    "Set the environment variable RELEASE_TESTING to enable this test.";
}

manifest_ok();
