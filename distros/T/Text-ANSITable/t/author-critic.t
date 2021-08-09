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

my $filenames = ['lib/BorderStyle/Text/ANSITable/OldCompat/Default/bold.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/brick.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/bricko.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/csingle.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/double.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/none_ascii.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/none_boxchar.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/none_utf8.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/single_ascii.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/single_boxchar.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/single_utf8.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/singleh_ascii.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/singleh_boxchar.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/singleh_utf8.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/singlei_ascii.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/singlei_boxchar.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/singlei_utf8.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/singleo_ascii.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/singleo_boxchar.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/singleo_utf8.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/singlev_ascii.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/singlev_boxchar.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/singlev_utf8.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/space_ascii.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/space_boxchar.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/space_utf8.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/spacei_ascii.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/spacei_boxchar.pm','lib/BorderStyle/Text/ANSITable/OldCompat/Default/spacei_utf8.pm','lib/ColorTheme/Text/ANSITable/OldCompat/Default/default_gradation.pm','lib/ColorTheme/Text/ANSITable/OldCompat/Default/default_gradation_whitebg.pm','lib/ColorTheme/Text/ANSITable/OldCompat/Default/default_nogradation.pm','lib/ColorTheme/Text/ANSITable/OldCompat/Default/default_nogradation_whitebg.pm','lib/ColorTheme/Text/ANSITable/OldCompat/Default/no_color.pm','lib/ColorTheme/Text/ANSITable/Standard/Gradation.pm','lib/ColorTheme/Text/ANSITable/Standard/GradationWhiteBG.pm','lib/ColorTheme/Text/ANSITable/Standard/NoGradation.pm','lib/ColorTheme/Text/ANSITable/Standard/NoGradationWhiteBG.pm','lib/Text/ANSITable.pm','lib/Text/ANSITable/StyleSet/AltRow.pm','script/ansitable-list-border-styles','script/ansitable-list-color-themes','script/ansitable-list-style-sets'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
