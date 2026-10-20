#! perl -T

use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 5;
use Test::FitNesse::Slim::ListExecutor;

my $list = Test::FitNesse::Slim::ListExecutor->new;
my @observed;
my @results = $list->execute_with(sub {
  my($statement,$result) = @_;
  push @observed, [$statement->[0],$result->[0],$result->[1]];
},
  ['i','import','fitnesse.slim.test'],
  ['m','make','sut','TestSlim'],
  ['call','call','sut','returnString'],
);

is_deeply([map { $_->[0] } @observed],[qw(i m call)],
  'the callback runs once after each instruction in input order');
is_deeply([map { $_->[1] } @observed],[qw(i m call)],
  'the callback receives each matching result');
is($observed[-1][2],'string','the callback sees the completed statement result');
is(scalar(@results),3,'the callback does not change the batch response list');

@observed = ();
@results = $list->execute_with(sub { push @observed, $_[0][0] },
  ['stop','call','sut','throwStopping'],
  ['skipped','call','sut','returnString'],
);
is_deeply(\@observed,['stop'],
  'the callback runs for the stopping statement but not skipped instructions');

