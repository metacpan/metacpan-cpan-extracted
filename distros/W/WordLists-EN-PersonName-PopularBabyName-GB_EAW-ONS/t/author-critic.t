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

my $filenames = ['lib/WordList/EN/PersonName/PopularBabyName/GB_EAW/ONS/2000/Boy.pm','lib/WordList/EN/PersonName/PopularBabyName/GB_EAW/ONS/2000/Girl.pm','lib/WordList/EN/PersonName/PopularBabyName/GB_EAW/ONS/2010/Boy.pm','lib/WordList/EN/PersonName/PopularBabyName/GB_EAW/ONS/2010/Girl.pm','lib/WordList/EN/PersonName/PopularBabyName/GB_EAW/ONS/2018/Boy.pm','lib/WordList/EN/PersonName/PopularBabyName/GB_EAW/ONS/2018/Girl.pm','lib/WordLists/EN/PersonName/PopularBabyName/GB_EAW/ONS.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
