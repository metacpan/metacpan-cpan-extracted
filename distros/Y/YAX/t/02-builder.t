use strict;
use warnings;

use Test::More tests => 22;

use YAX::Builder;

my $node = YAX::Builder->node([ 'foo', { 'life' => 42 }, "foo content" ]);
ok( $node );
isa_ok( $node, 'YAX::Element' );
is( $node->name, 'foo' );
is( $node->type, 1 );
is( $node->{life}, 42 );
is( $node->[0], 'foo content' );

$node = YAX::Builder->node([ 'bar', 'bar content' ]);
ok( $node );
isa_ok( $node, 'YAX::Element' );
is( $node->name, 'bar' );
is( $node->[0], 'bar content' );
$node->{sublime} = 69;
is( $node->attributes->{sublime}, 69 );
is( keys %$node, 1 );

$node = YAX::Builder->node([ 'baz', $node ]);
ok( $node );
is( $node->name, 'baz' );
is( $node->[0]->name, 'bar' );

$node = YAX::Builder->node(
    [ toast =>
        [ cheese => { type => 'cheddar' }, 'yummy', $node ],
    ]
);
ok( $node );
is( $node->name, 'toast' );
is( $node->[0]->name, 'cheese' );
is( $node->[0]{type}, 'cheddar' );
is( $node->[0]->type, 1 );
is( $node->[0][0]->data, 'yummy' );
is( $node->[0][1]->name, 'baz' );

