#!perl -T

use strict;
use warnings;

use Test::More tests => 39;

use Text::Same;

my @t1 = qw{b c};
my @t2 = qw{b c b c};

my $options = {};
my $matchmap = compare $options, \@t1, \@t2;
my @matches = $matchmap->matches;

ok(scalar(@matches) == 2);

my @sorted_matches = sort {
  my $min1_cmp = $a->min1 <=> $b->min1;
  if ($min1_cmp == 0) {
    $a->min2 <=> $b->min2;
  } else {
    $min1_cmp;
  }
} @matches;

my $match1 = $sorted_matches[0];
my $match2 = $sorted_matches[1];

ok($match1->score() == 4);
ok($match2->score() == 4);

my @test_data = (
                 {
                  dir=>"test1",
                  match_count=>2,
                  unmatched1=>0,
                  unmatched2=>0,
                 },
                 {
                  dir=>"test2",
                  match_count=>3,
                  unmatched1=>0,
                  unmatched2=>0,
                 },
                 {
                  dir=>"test3",
                  match_count=>3,
                  unmatched1=>0,
                  unmatched2=>0,
                 },
                 {
                  dir=>"test4",
                  match_count=>9,
                  unmatched1=>0,
                  unmatched2=>3,
                 },
                 {
                  dir=>"test5",
                  match_count=>3,
                  unmatched1=>1,
                  unmatched2=>1,
                  ignore_space=>1,
                 },
                 {
                  dir=>"test6",
                  match_count=>3,
                  unmatched1=>1,
                  unmatched2=>1,
                  ignore_blanks=>1,
                 },
                 {
                  dir=>"test7",
                  match_count=>3,
                  unmatched1=>2,
                  unmatched2=>1,
                  ignore_case=>1,
                 },
                 {
                  dir=>"test8",
                  match_count=>5,
                  unmatched1=>1,
                  unmatched2=>1,
                 },
                 {
                   dir=>"test9",
                   match_count=>1,
                   unmatched1=>0,
                   unmatched2=>0,
                   ignore_blanks=>1,
                  },
                  {
                   dir=>"test10",
                   match_count=>1,
                   unmatched1=>0,
                   unmatched2=>2,
                  },
                 {
                  dir=>"test11",
                  match_count=>1,
                  unmatched1=>1,
                  unmatched2=>0,
                  ignore_blanks=>1,
                  ignore_case=>1,
                 },
                 {
                  dir=>"test12",
                  match_count=>1,
                  unmatched1=>0,
                  unmatched2=>0,
                  ignore_blanks=>1,
                  ignore_case=>1,
                  ignore_space=>1,
                 },
                );

my $count = 0;

for my $test_data (@test_data) {
  my $dir = $test_data->{dir};
  my $file1 = "t/data/$dir/file1";
  my $file2 = "t/data/$dir/file2";

  my $options = $test_data;
  my $matchmap = compare $options, $file1, $file2;

  ok(scalar($matchmap->matches) == $test_data->{match_count});
  ok(scalar($matchmap->source1_non_matches) == $test_data->{unmatched1});
  ok(scalar($matchmap->source2_non_matches) == $test_data->{unmatched2});

  $count++;
}
