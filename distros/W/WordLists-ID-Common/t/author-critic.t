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

my $filenames = ['lib/WordList/ID/Common/Wikipedia/Top300.pm','lib/WordList/ID/Common/Wikipedia/Top500.pm','lib/WordList/ID/Common/Wikipedia1000.pm','lib/WordList/ID/Common/Wikipedia2500.pm','lib/WordList/ID/Common/Wikipedia5000.pm','lib/WordLists/ID/Common.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
