#!perl

use strict;
use warnings;
use experimentals;
use lib 'lib';
use Test::More tests => 4;
use YAGL;

my @edges = (
    [ 's', 'a', { weight => 560 } ],
    [ 's', 'd', { weight => 529 } ],
    [ 'a', 'b', { weight => 112 } ],
    [ 'a', 'd', { weight => 843 } ],
    [ 'b', 'c', { weight => 690 } ],
    [ 'b', 'e', { weight => 891 } ],
    [ 'd', 'e', { weight => 492 } ],
    [ 'e', 'f', { weight => 35 } ],
);

my $g = YAGL->new;
$g->add_edges(@edges);

$g->set_vertex_attribute( 's', { color => 'red' } );
$g->set_vertex_attribute( 'a', { color => 'green' } );

my $s_color = $g->get_vertex_attribute( 's', 'color' );
my $a_color = $g->get_vertex_attribute( 'a', 'color' );

ok( $s_color eq 'red', "Vertex 's' has the attribute '$s_color' as expected" );
ok( $a_color eq 'green',
    "Vertex 'a' has the attribute '$s_color' as expected" );

my $s_attrs = $g->get_vertex_attributes('s');
is_deeply(
    $s_attrs,
    { color => 'red' },
    "Vertex 's' has the expected attributes"
);

$g->delete_vertex_attributes('s');

$s_attrs = $g->get_vertex_attributes('s');
ok( !defined $s_attrs,
    "Vertex 's' has no attributes as expected post-deletion" );
