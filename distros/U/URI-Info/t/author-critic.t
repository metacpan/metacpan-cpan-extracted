#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.006

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/URI/Info.pm','lib/URI/Info/Plugin/Generic.pm','lib/URI/Info/Plugin/SearchQuery/google.pm','lib/URI/Info/Plugin/SearchQuery/thepiratebay.pm','lib/URI/Info/Plugin/SearchQuery/tokopedia.pm','lib/URI/Info/PluginBase.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
