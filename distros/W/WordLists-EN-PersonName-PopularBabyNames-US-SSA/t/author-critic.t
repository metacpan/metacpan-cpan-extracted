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

my $filenames = ['lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/1900/FemaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/1900/MaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/1910/FemaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/1910/MaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/1920/FemaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/1920/MaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/1930/FemaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/1930/MaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/1940/FemaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/1940/MaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/1950/FemaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/1950/MaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/1960/FemaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/1960/MaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/1970/FemaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/1970/MaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/1980/FemaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/1980/MaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/1990/FemaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/1990/MaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/2000/FemaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/2000/MaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/2010/FemaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/2010/MaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/2017/FemaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/2017/MaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/2018/FemaleTop1000.pm','lib/WordList/EN/PersonName/PopularBabyNames/US/SSA/2018/MaleTop1000.pm','lib/WordLists/EN/PersonName/PopularBabyNames/US/SSA.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
