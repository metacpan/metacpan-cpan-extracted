#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use utf8;

use Test::More;

use threads;
use Thread::Pipeline;

my @data = ( 5, [4, 5], {a => 3} );

my $p = Thread::Pipeline->new([
        double => { sub => sub { return $_[0], $_[0] } },
    ]);

$p->enqueue($_)  for @data;
$p->no_more_data();

my @r = $p->get_results();


is( scalar @r, 2 * scalar @data, 'result size' );


done_testing();


