#!perl -T

use strict;
use warnings;

use lib 't/lib';
use VPIT::TestHelpers;
use Thread::Cleanup::TestThreads;

use Test::More 'no_plan';

use Thread::Cleanup;

my %called : shared;
my $destr  : shared;
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

 my $gd = do {
  lock $destr;
  (defined $destr && $destr =~ /\[$tid\]/) ? 1 : undef;
 };
 is $gd, undef, "thread $tid destructor fires before global destruction";

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

 my $immortal = VPIT::TestHelpers::Guard->new(sub {
  # It seems we can't lock aggregates during global destruction, so we
  # resort to using a string instead.
  lock $destr;
  $destr .= "[$tid]";
 });
 $immortal->{self} = $immortal;

 {
  lock %nums;
  $nums{$tid} = $y;
 }
 is $x, $y, "\$x in thread $tid";
 local $x = -$tid;
}


my @threads = map {
 local $x = $_;
 spawn(\&cb, $_);
} 0 .. 4;

my @tids = map $_->tid, @threads;

$_->join for @threads;

is $x, -1, '$x in the main thread';

for (@tids) {
 is $ran{$_},    1, "thread $_ was run once";
 is $called{$_}, 1, "thread $_ destructor was called once";
}
