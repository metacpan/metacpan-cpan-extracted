# -*- perl -*-
use strict;
use warnings;
use Test::More;

plan skip_all => 'done_testing requires Test::More 0.88'
    if Test::More->VERSION < 0.88;
plan skip_all => 'No RELEASE_TESTING'
    unless -d '.git' || $ENV{RELEASE_TESTING};

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
    if $@;

for (all_modules()) {
  pod_coverage_ok($_) unless /XXX/;
}

done_testing();
