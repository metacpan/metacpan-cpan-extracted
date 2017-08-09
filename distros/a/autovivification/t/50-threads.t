#!perl

use strict;
use warnings;

use lib 't/lib';
use VPIT::TestHelpers (
 threads => [ 'autovivification' => 'autovivification::A_THREADSAFE()' ],
);

use Test::Leaner;

my $threads = 10;
my $runs    = 2;

{
 no autovivification;

 sub try {
  my $tid = threads->tid();

  for my $run (1 .. $runs) {
   {
    my $x;
    my $y = $x->{foo};
    is $x, undef, "fetch does not autovivify at thread $tid run $run";
   }
   {
    my $x;
    my $y = exists $x->{foo};
    is $x, undef, "exists does not autovivify at thread $tid run $run";
   }
   {
    my $x;
    my $y = delete $x->{foo};
    is $x, undef, "delete does not autovivify at thread $tid run $run";
   }

SKIP:
   {
    skip 'Hints aren\'t propagated into eval STRING below perl 5.10' => 3 * 2
                                                           unless "$]" >= 5.010;
    {
     my $x;
     eval 'my $y = $x->{foo}';
     is $@, '',    "fetch in eval does not croak at thread $tid run $run";
     is $x, undef, "fetch in eval does not autovivify at thread $tid run $run";
    }
    {
     my $x;
     eval 'my $y = exists $x->{foo}';
     is $@, '',    "exists in eval does not croak at thread $tid run $run";
     is $x, undef, "exists in eval does not autovivify at thread $tid run $run";
    }
    {
     my $x;
     eval 'my $y = delete $x->{foo}';
     is $@, '',    "delete in eval does not croak at thread $tid run $run";
     is $x, undef, "delete in eval does not autovivify at thread $tid run $run";
    }
   }
  }
 }
}

my @threads = map spawn(\&try), 1 .. $threads;

$_->join for @threads;

pass 'done';

done_testing;
