#!perl -T

use strict;
use warnings;

use lib 't/lib';
use Thread::Cleanup::TestThreads;

use Test::More;

use Thread::Cleanup;

my @stack : shared;

sub msg { lock @stack; push @stack, join ':', @_ }

Thread::Cleanup::register {
 msg 'cleanup';
 die 'cleanup';
 msg 'not reached 1';
};

{
 local $SIG{__DIE__} = sub { msg 'sig', @_ };
 no warnings 'threads';
 my $thr = spawn(sub {
  msg 'spawn';
  die 'thread';
  msg 'not reached 2';
 });
 if ($thr) {
  plan tests    => 5 + 1;
 } else {
  plan skip_all => 'Could not spawn the testing thread';
 }
 $thr->join;
}

msg 'done';

{
 lock @stack;
 is   shift(@stack), 'spawn';
 like shift(@stack), qr/sig:thread at \Q$0\E line \d+/;
 is   shift(@stack), 'cleanup';
 like shift(@stack), qr/sig:cleanup at \Q$0\E line \d+/;
 is   shift(@stack), 'done';
 is_deeply \@stack,  [ ], 'nothing more';
}
