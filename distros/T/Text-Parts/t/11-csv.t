#!perl

use Test::More;
use strict;
use Test::Requires qw/Text::CSV_XS/;
use warnings;
use Data::Dumper;
BEGIN {
    use_ok( 'Text::Parts' ) || print "Bail out!";
}

my $csv_eol = $^O =~ m{MSWin} ? "\012" : "\015\012";
foreach my $check (0 , 1) {
  my $csv = Text::CSV_XS->new({'binary'=> 1, eol => $csv_eol});
  my $s = Text::Parts->new(file => "t/data/test.csv", parser => $csv, eol => $csv_eol, check_line_start => $check);
  my @split = $s->split(num => 3);
  my @data;
  my $n = 0;
  for (my $i = 0; $i < @split; $i++) {
    my $f = $split[$i];
    ok ! $f->eof, 'not eof';
    $data[$i] ||= [];
    while (my $cols = $f->getline_parser) {
      push @{$data[$i]}, $cols;
    }
    ok $f->eof, 'eof';
  }

  is_deeply(\@data,
            [
             [
              [1,2,3],
              ["aaaaaaaaaaaaa","bbbbbbbbb", "c${csv_eol}ccccccccccccccccccccc"],
              ["eeeeeeeee","fffffffffff", "ggggggggg"],
             ],
             [
              ["hhhhhh", "iiiiiiiiiiiiiiiiiiiii","${csv_eol}jjjjjjjjjjjjjj"],
             ],
             [
              ["llllllllllllllllllllllllllll","mmmmm","n"],
             ]
            ]);
}
done_testing;
