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

my $filenames = ['lib/WordList.pm','lib/WordList/Test/Dynamic/OneTwo_Each.pm','lib/WordList/Test/Dynamic/OneTwo_EachParam.pm','lib/WordList/Test/Dynamic/OneTwo_FirstNextReset.pm','lib/WordList/Test/OneTwo.pm','lib/WordListRole/EachFromFirstNextReset.pm','lib/WordListRole/FirstNextResetFromEach.pm','lib/WordListRole/WordList.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
