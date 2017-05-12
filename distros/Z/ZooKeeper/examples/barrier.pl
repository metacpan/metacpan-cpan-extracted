#!/usr/bin/env perl
use strict; use warnings;
BEGIN { eval "use blib" }
use ZooKeeper;
use ZooKeeper::Constants qw(:errors);
use Sys::Hostname;
use Try::Tiny;
use AE;

my $barrier   = '/example-barrier';
my $process   = hostname() . "-$$";
my $threshold = 2;
my $zk = ZooKeeper->new(hosts => 'localhost:2181');

$SIG{INT} = sub { exit 0 };
try { $zk->create($barrier) } catch { $_->throw unless $_ == ZNODEEXISTS };
enter_barrier($zk, barrier => $barrier, process => $process, threshold => $threshold, double => 1);
try { $zk->delete($barrier) } catch { $_->throw unless $_ == ZNONODE };

sub enter_barrier {
    my ($zk, %args) = @_;
    my ($bar, $proc, $thresh, $double) = @args{qw(barrier process threshold double)};
    $zk->create("$bar/$proc", ephemeral => 1);
    if ((my @children = $zk->get_children($bar)) > $thresh) {
        try {
            $zk->create("$bar/ready", ephemeral => 1);
        } catch {
            $_->throw unless $_ == ZNODEEXISTS;
        };
    } else {
        my $cv = AE::cv;
        $cv->recv if not $zk->exists("$bar/ready", watcher => sub { $cv->send });
    }
    warn "Process $proc is running\n";
    if ($double) {
        exit_barrier($zk, barrier => $bar, process => $proc);
    } else {
        for my $child ($zk->get_children($bar)) {
            try { $zk->delete("$bar/$child") } catch { $_->throw unless $_ == ZNODEEXISTS };
        }
    }
}

sub exit_barrier {
    my ($zk, %args) = @_;
    my ($bar, $proc) = @args{qw(barrier process)};
    try { $zk->delete("$bar/ready") } catch { $_->throw unless $_ == ZNONODE };
    if (my ($first, @rest) = sort $zk->get_children($bar)) {
        if ($first eq $proc) {
            while (@rest) {
                my $cv = AE::cv;
                $cv->recv if $zk->exists("$bar/$rest[-1]", watcher => sub { $cv->send });
                (undef, @rest) = sort $zk->get_children($bar);
            }
            $zk->delete("$bar/$proc");
        } else {
            my $cv = AE::cv;
            $zk->delete("$bar/$proc") if $zk->exists("$bar/$proc");
            $cv->recv if $zk->exists("$bar/$first", watcher => sub { $cv->send });
        }
    }
}
