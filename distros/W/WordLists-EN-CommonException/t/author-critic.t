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

my $filenames = ['lib/WordList/EN/CommonException/EdPlace/Year1.pm','lib/WordList/EN/CommonException/EdPlace/Year2.pm','lib/WordList/EN/CommonException/MonsterPhonics/Year1.pm','lib/WordList/EN/CommonException/MonsterPhonics/Year2.pm','lib/WordList/EN/CommonException/OxfordOwl/Year5_6.pm','lib/WordList/EN/CommonException/RaundsParkInfantSchool/Year1.pm','lib/WordList/EN/CommonException/RaundsParkInfantSchool/Year2.pm','lib/WordList/EN/CommonException/Twinkl/Year1.pm','lib/WordList/EN/CommonException/Twinkl/Year2.pm','lib/WordList/EN/CommonException/Twinkl/Year3_4.pm','lib/WordLists/EN/CommonException.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
