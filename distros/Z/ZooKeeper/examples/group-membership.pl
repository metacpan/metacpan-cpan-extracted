#!/usr/bin/env perl
use strict; use warnings;
BEGIN { eval "use blib" }
use ZooKeeper;
use AnyEvent;

my $name = $ARGV[0] || sprintf("member-%d", int(rand 1000));

my $group = '/example-group';
my $zk    = ZooKeeper->new(hosts => 'localhost:2181');
$zk->create($group) unless $zk->exists($group);

join_group($name);

# make sure SIGINT cleanly destroys zookeeper connection
# otherwise zookeeper will wait for the connection timeout
$SIG{INT} = sub { exit 0 };
AnyEvent->condvar->recv;


sub join_group {
    my ($name) = @_;
    $zk->create("$group/$name", ephemeral => 1);
    $zk->get_children($group, watcher => \&group_watcher);
}

sub group_watcher {
    my @members = $zk->get_children($group, watcher => \&group_watcher);
    print "Group members: @members\n";
}
