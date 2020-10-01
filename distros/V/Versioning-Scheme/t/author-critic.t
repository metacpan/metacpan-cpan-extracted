#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.005

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/Role/Versioning/Scheme.pm','lib/Versioning/Scheme.pm','lib/Versioning/Scheme/Dotted.pm','lib/Versioning/Scheme/Monotonic.pm','lib/Versioning/Scheme/Perl.pm','lib/Versioning/Scheme/Semantic.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
