#!perl
use 5.008;

use strict;
use warnings;
use utf8;

use lib qw(../lib/);

use Text::Guess::Language::Words;
use Data::Dumper;

my $words = Text::Guess::Language::Words->words();

my $sim = {};

for my $word (keys %{$words}) {
  for (my $i=0;$i<(scalar(@{$words->{$word}})-1);$i++) {
    for (my $j=$i+1;$j<(scalar(@{$words->{$word}}));$j++) {
      $sim->{$words->{$word}->[$i]}->{$words->{$word}->[$j]}++;
      $sim->{$words->{$word}->[$j]}->{$words->{$word}->[$i]}++;
    }
  }
}

#print Dumper($sim);

for my $lang (sort keys %{$sim}) {
  my @similars = sort { $sim->{$lang}->{$b} <=> $sim->{$lang}->{$a} }
                 grep { $sim->{$lang}->{$_} > 100 }
                 keys %{$sim->{$lang}};
  if (@similars) {
    print $lang,"\n";
    for my $similar (@similars) {
      print '  ',$similar,': ',$sim->{$lang}->{$similar},"\n";
    }
  }
}
