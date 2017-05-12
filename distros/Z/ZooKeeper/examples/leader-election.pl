#!/usr/bin/env perl
use strict; use warnings;
BEGIN { eval "use blib" }
use ZooKeeper;
use ZooKeeper::Constants;
use AnyEvent;
use List::MoreUtils qw(before);

my $root = '/example-election';
my $zk   = ZooKeeper->new(hosts => 'localhost:2181');

$zk->create($root) unless $zk->exists($root);
join_group();

# make sure SIGINT cleanly destroys zookeeper connection
# otherwise zookeeper will wait for the connection timeout
$SIG{INT} = sub { exit 0 };
AnyEvent->condvar->recv;


sub node_from_path {
    my ($path) = @_;
    return substr $path, length($root) + 1;
}

sub watch_predecessor {
    my ($me, $pred, $leader, $event) = @_;
    my ($type, $path) = @{$event}{qw(type path)};

    if ($type == ZOO_DELETED_EVENT and node_from_path($path) eq $leader) {
        print "I am the leader!\n";
        if (not $zk->exists("$root/$pred", watcher => sub { watch_predecessor($me, $pred, $leader, shift) })) {
            elect_leader($me);
        }
    }
}

sub predecessor {
    my ($me, @members) = @_;
    my @before = before { $_ eq $me } @members;
    return $before[-1];
}

sub elect_leader {
    my ($me) = @_;
    my @members = map {$_->[0]} sort {$a->[1] <=> $b->[1]} map {[$_, substr($_, 2)]} $zk->get_children($root);
    my $leader  = $members[0];
    print "I am $me";

    if ($me eq $leader) {
        print " and I am the leader!\n";
    } else {
        my $pred = predecessor($me, @members);
        print " and my predecessor is $pred\n";
        if (not $zk->exists("$root/$pred", watcher => sub { watch_predecessor($me, $pred, $leader, shift) })) {
            elect_leader($me);
        }
    }
}

sub join_group {
    my $path = $zk->create("$root/n-", ephemeral => 1, sequential => 1);
    my $me   = node_from_path($path);
    elect_leader($me);
}

