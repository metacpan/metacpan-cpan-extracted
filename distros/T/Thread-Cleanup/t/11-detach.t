#!perl -T

use strict;
use warnings;

use lib 't/lib';
use Thread::Cleanup::TestThreads;

use Test::More 'no_plan';

use Thread::Cleanup;

my %called : shared;
my %nums   : shared;

our $x = -1;

Thread::Cleanup::register {
 my $tid = threads->tid;
 {
  lock %called;
  $called{$tid}++;
 }

 my $num = do {
  lock %nums;
  $nums{$tid};
 };

 is $x, $num, "\$x in destructor of thread $tid";
 local $x = $tid;
};

my %ran : shared;

sub cb {
 my ($y) = @_;

 my $tid = threads->tid;
 {
  lock %ran;
  $ran{$tid}++;
 }

 {
  lock %nums;
  $nums{$tid} = $y;
 }
 is $x, $y, "\$x in thread $tid";
 local $x = -$tid;

 sleep 1;
}

my @threads = map {
 local $x = $_;
 spawn(\&cb, $_);
} 0 .. 4;

my @tids = map $_->tid, @threads;

$_->detach for @threads;

sleep 2;

is $x, -1, '$x in the main thread';

for (@tids) {
 is $ran{$_},    1,     "thread $_ was run once";
 is $called{$_}, undef, "thread $_ destructor wasn't called yet";
}

END {
 is $called{$_}, 1, "thread $_ destructor was called once at END time"
                                                                      for @tids;
}
