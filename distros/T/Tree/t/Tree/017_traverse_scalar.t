use strict;
use warnings;

use Test::More tests => 35;

my $CLASS = 'Tree';
use_ok( $CLASS )
    or Test::More->builder->BAILOUT( "Cannot load $CLASS" );

my @list;
my @nodes;
my $c;

sub convert {
    my $c = shift;
    my @l;
    while ( my $n = $c->() ) {
        push @l, $n;
    }
    return @l;
}

push @nodes, $CLASS->new('A');

@list = convert( $c = $nodes[0]->traverse );
is_deeply( \@list, [$nodes[0]], "A preorder traversal of a single-node tree is itself" );

@list = convert( $c = $nodes[0]->traverse( $nodes[0]->PRE_ORDER ) );
is_deeply( \@list, [$nodes[0]], "A preorder traversal of a single-node tree is itself" );

@list = convert( $c = $nodes[0]->traverse( $nodes[0]->POST_ORDER ));
is_deeply( \@list, [$nodes[0]], "A postorder traversal of a single-node tree is itself" );

@list = convert( $c = $nodes[0]->traverse( $nodes[0]->LEVEL_ORDER ));
is_deeply( \@list, [$nodes[0]], "A levelorder traversal of a single-node tree is itself" );

is( $nodes[0]->traverse( 'floober' ), undef, "traverse(): An illegal traversal order is an error" );
is( $nodes[0]->last_error, "traverse(): 'floober' is an illegal traversal order", "... and the error is good" );

push @nodes, $CLASS->new('B');
$nodes[0]->add_child( $nodes[-1] );

@list = convert( $c = $nodes[0]->traverse );
is_deeply( \@list, [ @nodes[0,1] ], "A preorder traversal of this tree is A-B" );

@list = convert( $c = $nodes[0]->traverse( $nodes[0]->PRE_ORDER ) );
is_deeply( \@list, [ @nodes[0,1] ], "A preorder traversal of this tree is A-B" );

@list = convert( $c = $nodes[0]->traverse( $nodes[0]->POST_ORDER ));
is_deeply( \@list, [ @nodes[1,0] ], "A postorder traversal of this tree is B-A" );

print scalar @list, $/;

@list = convert( $c = $nodes[0]->traverse( $nodes[0]->LEVEL_ORDER ));
is_deeply( \@list, [ @nodes[0,1] ], "A levelorder traversal of this tree is A-B" );

push @nodes, $CLASS->new('C');
$nodes[0]->add_child( $nodes[-1] );

@list = convert( $c = $nodes[0]->traverse );
is_deeply( \@list, [ @nodes[0,1,2] ], "A preorder traversal of this tree is A-B-C" );

@list = convert( $c = $nodes[0]->traverse( $nodes[0]->PRE_ORDER ) );
is_deeply( \@list, [ @nodes[0,1,2] ], "A preorder traversal of this tree is A-B-C" );

@list = convert( $c = $nodes[0]->traverse( $nodes[0]->POST_ORDER ));
is_deeply( \@list, [ @nodes[1,2,0] ], "A postorder traversal of this tree is B-C-A" );

@list = convert( $c = $nodes[0]->traverse( $nodes[0]->LEVEL_ORDER ));
is_deeply( \@list, [ @nodes[0,1,2] ], "A levelorder traversal of this tree is A-B-C" );

push @nodes, $CLASS->new('D');
$nodes[1]->add_child( $nodes[-1] );

@list = convert( $c = $nodes[0]->traverse );
is_deeply( \@list, [ @nodes[0,1,3,2] ], "A preorder traversal of this tree is A-B-D-C" );

@list = convert( $c = $nodes[0]->traverse( $nodes[0]->PRE_ORDER ) );
is_deeply( \@list, [ @nodes[0,1,3,2] ], "A preorder traversal of this tree is A-B-D-C" );

@list = convert( $c = $nodes[0]->traverse( $nodes[0]->POST_ORDER ));
is_deeply( \@list, [ @nodes[3,1,2,0] ], "A postorder traversal of this tree is D-B-C-A" );

@list = convert( $c = $nodes[0]->traverse( $nodes[0]->LEVEL_ORDER ));
is_deeply( \@list, [ @nodes[0,1,2,3] ], "A levelorder traversal of this tree is A-B-C-D" );

push @nodes, $CLASS->new('E');
$nodes[1]->add_child( $nodes[-1] );

@list = convert( $c = $nodes[0]->traverse );
is_deeply( \@list, [ @nodes[0,1,3,4,2] ], "A preorder traversal of this tree is A-B-D-E-C" );

@list = convert( $c = $nodes[0]->traverse( $nodes[0]->PRE_ORDER ) );
is_deeply( \@list, [ @nodes[0,1,3,4,2] ], "A preorder traversal of this tree is A-B-D-E-C" );

@list = convert( $c = $nodes[0]->traverse( $nodes[0]->POST_ORDER ));
is_deeply( \@list, [ @nodes[3,4,1,2,0] ], "A postorder traversal of this tree is D-E-B-C-A" );

@list = convert( $c = $nodes[0]->traverse( $nodes[0]->LEVEL_ORDER ));
is_deeply( \@list, [ @nodes[0,1,2,3,4] ], "A levelorder traversal of this tree is A-B-C-D" );

push @nodes, $CLASS->new('F');
$nodes[1]->add_child( $nodes[-1] );

@list = convert( $c = $nodes[0]->traverse );
is_deeply( \@list, [ @nodes[0,1,3,4,5,2] ], "A preorder traversal of this tree is A-B-D-E-F-C" );

@list = convert( $c = $nodes[0]->traverse( $nodes[0]->PRE_ORDER ) );
is_deeply( \@list, [ @nodes[0,1,3,4,5,2] ], "A preorder traversal of this tree is A-B-D-E-F-C" );

@list = convert( $c = $nodes[0]->traverse( $nodes[0]->POST_ORDER ));
is_deeply( \@list, [ @nodes[3,4,5,1,2,0] ], "A postorder traversal of this tree is A-B-D-E-F-C" );

@list = convert( $c = $nodes[0]->traverse( $nodes[0]->LEVEL_ORDER ));
is_deeply( \@list, [ @nodes[0,1,2,3,4,5] ], "A levelorder traversal of this tree is A-B-D-E-F-C" );

push @nodes, $CLASS->new('G');
$nodes[4]->add_child( $nodes[-1] );

@list = convert( $c = $nodes[0]->traverse );
is_deeply( \@list, [ @nodes[0,1,3,4,6,5,2] ], "A preorder traversal of this tree is A-B-D-E-G-F-C" );

@list = convert( $c = $nodes[0]->traverse( $nodes[0]->PRE_ORDER ) );
is_deeply( \@list, [ @nodes[0,1,3,4,6,5,2] ], "A preorder traversal of this tree is A-B-D-E-G-F-C" );

@list = convert( $c = $nodes[0]->traverse( $nodes[0]->POST_ORDER ));
is_deeply( \@list, [ @nodes[3,6,4,5,1,2,0] ], "A postorder traversal of this tree is D-G-E-F-B-C-A" );

@list = convert( $c = $nodes[0]->traverse( $nodes[0]->LEVEL_ORDER ));
is_deeply( \@list, [ @nodes[0,1,2,3,4,5,6] ], "A levelorder traversal of this tree is A-B-C-D-E-F-G" );

push @nodes, $CLASS->new('H');
$nodes[2]->add_child( $nodes[-1] );

@list = convert( $c = $nodes[0]->traverse );
is_deeply( \@list, [ @nodes[0,1,3,4,6,5,2,7] ], "A preorder traversal of this tree is A-B-D-E-G-F-C-H" );

@list = convert( $c = $nodes[0]->traverse( $nodes[0]->PRE_ORDER ) );
is_deeply( \@list, [ @nodes[0,1,3,4,6,5,2,7] ], "A preorder traversal of this tree is A-B-D-E-G-F-C-H" );

@list = convert( $c = $nodes[0]->traverse( $nodes[0]->POST_ORDER ));
is_deeply( \@list, [ @nodes[3,6,4,5,1,7,2,0] ], "A postorder traversal of this tree is D-G-E-F-B-H-C-A" );

@list = convert( $c = $nodes[0]->traverse( $nodes[0]->LEVEL_ORDER ));
is_deeply( \@list, [ @nodes[0,1,2,3,4,5,7,6] ], "A levelorder traversal of this tree is A-B-C-D-E-F-H-G" );
