#!perl -T
use strict;
use warnings;

BEGIN {
  unless ($ENV{'AUTHOR_TESTING'}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use Test::More;

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval { use Test::Pod $min_tp };
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

all_pod_files_ok();
