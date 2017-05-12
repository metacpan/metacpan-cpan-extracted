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
        check_type => { sub => \&check_type },
    ]);

$p->enqueue($_)  for @data;
$p->no_more_data();

my @r = $p->get_results();


is( scalar @r, scalar @data, 'result size' );

for my $i ( 0 .. $#data ) {
    my $e = ref $data[$i];
    is( $r[$i], $e, "$e transfer through queue" );
}

done_testing();



sub check_type {
    my ($in) = @_;
    return ref $in;
}

