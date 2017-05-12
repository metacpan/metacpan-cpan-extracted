#!/usr/bin/env perl
use strict; use warnings;
BEGIN {
    eval "use blib";
    $SIG{INT} = sub { exit 0 };
}
use AnyEvent;
use List::MoreUtils qw(before);
use Try::Tiny;
use ZooKeeper;
use ZooKeeper::Constants qw(ZNODEEXISTS);

my $lock = $ARGV[0] // '/_zookeeper_example_lock';
my $zk   = ZooKeeper->new(hosts => 'localhost:2181');

try { $zk->create($lock) } catch { $_->throw unless $_ == ZNODEEXISTS };
my $guid = $zk->create("$lock/guid-lock-",
    ephemeral  => 1,
    sequential => 1,
);

my @guids = sort map {"$lock/$_"} $zk->get_children($lock);
while (my $predecessor = get_predecessor($zk, $guid)) {
    my $cv = AE::cv;
    $zk->exists($predecessor, watcher => sub { $cv->send }) or last;
    $cv->recv;
}

print "Acquired lock\n";
sleep 1;
print "Releasing lock\n";


sub get_predecessor {
    my ($zk, $me)  = @_;
    my @nodes = sort map {"$lock/$_"} $zk->get_children($lock);

    my @predecessors = before {$_ eq $me} @nodes;
    return $predecessors[-1];
}
