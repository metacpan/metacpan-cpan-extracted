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

my $filenames = ['lib/WordList/ID/ByCategory/Animal.pm','lib/WordList/ID/ByCategory/Bird.pm','lib/WordList/ID/ByCategory/Flower.pm','lib/WordList/ID/ByCategory/Food.pm','lib/WordList/ID/ByCategory/Fruit.pm','lib/WordList/ID/ByCategory/Insect.pm','lib/WordList/ID/ByCategory/MusicalInstrument.pm','lib/WordList/ID/ByCategory/Vegetable.pm','lib/WordList/ID/ByCategory/WaterAnimal.pm','lib/WordListBundle/ID/ByCategory.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
