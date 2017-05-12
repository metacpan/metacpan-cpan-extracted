#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use utf8;

use Test::More;

use threads;
use Thread::Pipeline;

my $p = Thread::Pipeline->new([
        tid => { sub => \&add_tid, num_threads => 2 },
        count => { sub => \&count, need_finalize => 1, },
    ]);

$p->enqueue([1,2,3]);
$p->enqueue([4,5]);
$p->enqueue([6]);
$p->enqueue([7,8,9]);

$p->no_more_data();

my @r = $p->get_results();

is( scalar @r, 1, 'result size' );

my $r = shift @r;

is( scalar keys %$r, 2, 'threads count' );


done_testing();

sub add_tid {
    my ($in) = @_;
    my $tid = threads->tid();

    sleep 1;
    return [ $tid => $in ];
}

sub count {
    my ($in) = @_;
    state %a;
    
    if ( defined $in ) {
        $a{ $in->[0] } ++;
        return;
    }
    else {
        return \%a;
    }
}
