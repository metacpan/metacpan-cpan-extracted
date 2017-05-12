#!perl -T

use strict;
use warnings;

use lib 't/lib';
use Thread::Cleanup::TestThreads;

use Test::More 'no_plan';

my $num   = 3;
my $depth = 2;

use Thread::Cleanup;

diag 'This will leak some scalars' unless "$]" >= 5.011_005;

our $x = -1;

my %ran    : shared;
my %nums   : shared;
my %called : shared;

my @tids;

sub test_threads {
 my ($num, $depth) = @_;
 if ($depth <= 0) {
  @tids = ();
  return;
 }
 my @threads = map {
  local $x = $_;
  spawn(\&cb, $_, $depth);
 } 1 .. $num;
 @tids = map $_->tid, @threads;
 return @threads;
}

sub check {
 lock %ran;
 lock %called;
 for (@tids) {
  is $ran{$_},    1, "thread $_ was run once";
  is $called{$_}, 1, "thread $_ destructor was called once";
 }
}

sub cb {
 my ($y, $depth) = @_;

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

 $_->join for test_threads $num, $depth - 1;

 check;
}

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

$_->join for test_threads $num, $depth;

check;

is $x, -1, '$x in the main thread';

