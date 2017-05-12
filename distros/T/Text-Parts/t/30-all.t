#!perl

use Test::More;
use strict;
use warnings;
BEGIN {
    use_ok( 'Text::Parts' ) || print "Bail out!";
}

my %test = (
              1 => [4,
                    [1, 2],
                    [3, 4],
                    [5, 6],
                    [7, 8],
                   ],
              2 => [4,
                    [1111, 2],
                    ['', 4444, 5333],
                    ['', 7888],
                    [8000],
                   ],
              3 => [4,
                    ['aaaaaaaaaaaaaaaaaaaa'],
                    [2222],
                    [3333],
                    [4444],
                   ],
              4 => [3,
                    [1111, 'bbbbbbbbbbbbbbbbbbbb'],
                    [3333],
                    [4444],
                   ],
             );
my %test2 = %test;
foreach my $n (sort {$a <=> $b} keys %test) {
  my $s = Text::Parts->new(file => "t/data/$n.txt", check_line_start => 0);
  my @split = $s->split(num => $test{$n}[0]);
  ok @split > 0;
  for (my $i = 0; $i < @split; $i++) {
    my $f = $split[$i];
    ok ! $f->eof, 'not eof';
    is $f->all, join "\n", @{$test{$n}[$i + 1]};
    ok $f->eof, 'eof';
  }
}

%test = %test2;
foreach my $n (sort {$a <=> $b} keys %test) {
  my $split = shift @{$test{$n}};
  my $s = Text::Parts->new(file => "t/data/$n.txt", check_line_start => 0);
  my @split = $s->split(num => $split);
  ok @split > 0;
  for (my $i = 0; $i < @split; $i++) {
    my $f = $split[$i];
    ok ! $f->eof, 'not eof';
    my $buf;
    ok ! $f->all(\$buf), 'all and scalar ref returns nothing';
    is $buf , join "\n", @{$test{$n}[$i]};
    ok $f->eof, 'eof';
  }
}

done_testing;
