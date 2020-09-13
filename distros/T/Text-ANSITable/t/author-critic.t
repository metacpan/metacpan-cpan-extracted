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

my $filenames = ['lib/ColorTheme/Text/ANSITable/Standard/Gradation.pm','lib/ColorTheme/Text/ANSITable/Standard/GradationWhiteBG.pm','lib/ColorTheme/Text/ANSITable/Standard/NoGradation.pm','lib/ColorTheme/Text/ANSITable/Standard/NoGradationWhiteBG.pm','lib/Text/ANSITable.pm','lib/Text/ANSITable/StyleSet/AltRow.pm','script/ansitable-list-border-styles','script/ansitable-list-color-themes','script/ansitable-list-style-sets'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
