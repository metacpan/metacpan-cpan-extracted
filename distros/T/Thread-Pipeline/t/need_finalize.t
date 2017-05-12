#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use utf8;

use Test::More;

use Thread::Pipeline;

my $p = Thread::Pipeline->new([
        revert => { sub => \&revert },
        concat => { sub => \&concat, need_finalize => 1, },
    ]);

$p->enqueue([1,2,3]);
$p->enqueue([4,5]);
$p->enqueue([6]);
$p->enqueue([7,8,9]);

$p->no_more_data();

my @r = $p->get_results();

is( scalar @r, 1, 'result size' );

my $r = shift @r;

ok( $r ~~ [3,2,1,5,4,6,9,8,7], 'result' );


done_testing();


sub revert {
    my ($in) = @_;
    return [ reverse @$in ];
}

sub concat {
    my ($in) = @_;
    state @a;
    
    if ( defined $in ) {
        push @a, @$in;
        return;
    }
    else {
        return \@a;
    }
}
