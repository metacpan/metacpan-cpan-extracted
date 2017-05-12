use Test::More tests => 27;
use strict;
use warnings;

use_ok( 'Tree::RB::Node' );

diag( "Testing Tree::RB::Node $Tree::RB::Node::VERSION" );

foreach my $m (qw[
    new
    key
    val
    color
    parent
    left
    right
    min
    max
    successor
    predecessor
  ])
{
    can_ok('Tree::RB::Node', $m);
}

my $node = Tree::RB::Node->new('England' => 'London');

#    [England: London]

isa_ok( $node, 'Tree::RB::Node' );
is($node->key, 'England', 'key retrieved after new');
is($node->val, 'London',  'value retrieved after new');

$node->key('France');

#    [France: London]

is($node->key, 'France', 'key retrieved after set');

$node->val('Paris');

#    [France: Paris]

is($node->val, 'Paris', 'value retrieved after set');

$node->color(1);
is($node->color, 1, 'color retrieved after set');

my $left_node  = Tree::RB::Node->new('England' => 'London');
$left_node->parent($node);
$node->left($left_node);

#           [France: Paris]
#           /
#    [England: London]

is($node->left, $left_node, 'left retrieved after set');

my $right_node = Tree::RB::Node->new('Hungary' => 'Budapest');
$right_node->parent($node);
$node->right($right_node);

#           [France: Paris]
#           /             \
#    [England: London]   [Hungary: Budapest]

is($node->right, $right_node, 'right retrieved after set');

my $parent_node = Tree::RB::Node->new('Ireland' => 'Dublin');
$parent_node->left($node);
$node->parent($parent_node);

#                    [Ireland: Dublin]
#                    /
#           [France: Paris]
#           /             \
#    [England: London]   [Hungary: Budapest]

is($node->parent, $parent_node, 'parent retrieved after set');

is($parent_node->min->key, 'England', 'min');

is($node->max->key, 'Hungary', 'max');
is($right_node->successor->key, 'Ireland', 'successor');
is($parent_node->predecessor->key, 'Hungary', 'predecessor');

my $egypt = Tree::RB::Node->new('Egypt' => 'Cairo');
$egypt->parent($left_node);
$left_node->right($egypt);

#                    [Ireland: Dublin]
#                    /
#           [France: Paris]
#           /             \
#    [England: London]   [Hungary: Budapest]
#                    \
#                  [Egypt: Cairo]

is($parent_node->leaf->key, 'Egypt', 'leaf');

$parent_node->strip;
is($parent_node->leaf->key, 'Ireland', 'strip');
