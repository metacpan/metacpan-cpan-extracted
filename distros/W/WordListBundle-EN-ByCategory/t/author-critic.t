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

my $filenames = ['lib/WordList/EN/ByCategory/Animal.pm','lib/WordList/EN/ByCategory/Bird.pm','lib/WordList/EN/ByCategory/Flower.pm','lib/WordList/EN/ByCategory/Food.pm','lib/WordList/EN/ByCategory/Fruit.pm','lib/WordList/EN/ByCategory/Insect.pm','lib/WordList/EN/ByCategory/MusicalInstrument.pm','lib/WordList/EN/ByCategory/Vegetable.pm','lib/WordList/EN/ByCategory/WaterAnimal.pm','lib/WordListBundle/EN/ByCategory.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
