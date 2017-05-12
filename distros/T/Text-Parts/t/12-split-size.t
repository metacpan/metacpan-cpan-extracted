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
              2 => [7,
                    [1111, 2],
                    ['', 4444, 5333],
                    ['', 7888],
                    [8000],
                   ],
              3 => [5,
                    ['aaaaaaaaaaaaaaaaaaaa'],
		    [2222],
                    [3333],
                    [4444],
                   ],
              4 => [5,
                    [1111],
		    ['bbbbbbbbbbbbbbbbbbbb'],
                    [3333],
                    [4444],
                   ],
             );

foreach my $n (sort {$a <=> $b} keys %test) {
  my $split = shift @{$test{$n}};
  my $s = Text::Parts->new(file => "t/data/$n.txt");
  my @split = $s->split(size => $split);
  my @data;
  for (my $i = 0; $i < @split; $i++) {
    my $f = $split[$i];
    ok ! $f->eof, 'not eof';
    $data[$i] ||= [];
    while (my $l = $f->getline) {
      chomp $l;
      push @{$data[$i]}, $l,
    }
    ok $f->eof, 'eof';
  }
  is_deeply \@data, $test{$n}, "$n.txt";
  unshift @{$test{$n}}, $split;
}

done_testing;
