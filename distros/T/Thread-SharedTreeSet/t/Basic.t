#!/usr/bin/perl -w
use strict;
use lib '..';
use threads;
use Thread::SharedTreeSet;
use Test::More qw(no_plan);

use_ok( 'Thread::SharedTreeSet' );

my $h = Thread::SharedTreeSet->new();

my $x = threads->create( 'a', $h->{'id'} );
my $y = threads->create( 'b', $h->{'id'} );

wait_for_threads();

sub a {
    my $hid = shift;
    my $h = Thread::SharedTreeSet->new( id => $hid );
    $h->set( 'a', { test => 'blah' } );
    $h->ilock('a');
    sleep(2);
    $h->iunlock('a');
    return 1;
}

sub b {
    my $hid = shift;
    my $h = Thread::SharedTreeSet->new( id => $hid );
    sleep(1);
    $h->ilock('a');
    my $data = $h->get('a');
    $h->iunlock('a');
    if( $data->{'test'} eq 'blah' ) { return 1; }
    return 0;
}

sub wait_for_threads {
    while( 1 ) {
        my @joinable = threads->list(0);#joinable
        my @running = threads->list(1);#running
        
        for my $thr ( @joinable ) { 
            my $result = $thr->join();
            is( $result, 1, 'Thread ok' );
        }
        last if( !@running );
        sleep(1);
    }
}

