#!perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 100;

use Text::Same;
use Text::Same::TextUI;

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
  for my $draw_match_flag (0, 1) {
    my $options = $test_data;
    $options->{side_by_side} = $draw_match_flag;
    my $dir = $test_data->{dir};
    my $file1 = "t/data/$dir/file1";
    my $file2 = "t/data/$dir/file2";

    my $matchmap = compare $options, $file1, $file2;

    my @matches = $matchmap->matches;

    for my $match (@matches) {
      my $match_out = draw_match($options, $match);
      ok(length $match_out > 0);
    }

    my @source1_non_matches = $matchmap->source1_non_matches;
    my @source2_non_matches = $matchmap->source2_non_matches;

    for my $non_match (@source1_non_matches) {
      my $non_match_1_out = draw_non_match($options, $matchmap->source1,
                                           $non_match);
      ok(length $non_match_1_out > 0);
    }
    for my $non_match (@source2_non_matches) {
      my $non_match_2_out = draw_non_match($options, $matchmap->source2,
                                           $non_match);
      ok(length $non_match_2_out > 0);
    }

    $count++;
  }
}

print "$count\n";
