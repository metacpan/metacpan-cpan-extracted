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

foreach my $check (0, 1) {
  foreach my $n (sort {$a <=> $b} keys %test) {
    my $split = shift @{$test{$n}};
    my $s = Text::Parts->new(file => "t/data/$n.txt", check_line_start => $check);
    my @split = $s->split(num => $split);
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

  foreach my $n (sort {$a <=> $b} keys %test) {
    my $split = shift @{$test{$n}};
    my $s = Text::Parts->new(file => "t/data/$n.txt", check_line_start => $check);
    my @split = $s->split(num => $split);
    my @data;
    for (my $i = 0; $i < @split; $i++) {
      my $f = $split[$i];
      $data[$i] ||= [];
      ok ! $f->eof, 'not eof';
      while (<$f>) {
        chomp;
        push @{$data[$i]}, $_,
      }
      ok $f->eof, 'eof';
    }
    is_deeply \@data, $test{$n}, "$n.txt";
    unshift @{$test{$n}}, $split;
  }
}

for my $max_num (1, 2, 3){
  my $n = 1;
  my $split = shift @{$test{$n}};
  my $s = Text::Parts->new(file => "t/data/$n.txt", check_line_start => 0);
  my @split = $s->split(num => $split, max_num => $max_num);
  is scalar @split, $max_num, "splitted to $max_num files";
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
  is_deeply \@data, [@{$test{$n}}[0 .. ($max_num - 1)]], "$n.txt";
  unshift @{$test{$n}}, $split;
}

# my $s = Text::Parts->new();
# $s->file("t/data/1.txt");
# my @split = $s->split(num => 4);
# my $fh = $split[0];
# my @content = <$fh>;
# is $content[0], "1\n";
# is $content[1], "2\n";
# local $/;
# $fh = $split[1];
# my $c = <$fh>;
# is $c, "2\n3\n";

done_testing;
