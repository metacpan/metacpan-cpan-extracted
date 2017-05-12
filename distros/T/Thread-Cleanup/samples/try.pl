#!perl

use strict;
use warnings;

use blib;

use Thread::Cleanup;

use threads;

$|++;
local $\ = "\n";

Thread::Cleanup::register {
 my $tid = threads->tid;
 print "finished thread $tid";
};

sub worker {
 my $tid = threads->tid;
 print "running thread $tid";
 sleep 1;
}

print "begin";

my @tids;

my @t = map {
 my $thr = threads->create(\&worker);
 my $tid = $thr->tid;
 push @tids, $tid;
 print "spawned thread $tid";
 $thr;
} 1 .. 3;

$t[0]->join;
print "joined thread $tids[0]";

$t[1]->detach;
print "detached thread $tids[1]";

sleep 2;

print "end";

END {
 print "END\n";
}
