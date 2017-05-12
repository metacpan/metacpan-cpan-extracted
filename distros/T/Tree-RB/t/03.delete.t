use Test::More tests => 13;
use strict;
use warnings;

use Tree::RB;

diag( "Testing deletion in Tree::RB $Tree::RB::VERSION" );

my $tree = Tree::RB->new;

$tree->put('England' => 'London');

my $size = $tree->size;

$tree->delete('England');

ok($size - $tree->size == 1, 'size goes down by one on removing a node');

my ($val, $node) = $tree->lookup('England');

ok(! defined $node, 'lookup deleted node');
ok(! defined $val,  q[lookup deleted node's value]);

$tree->put('France' => 'Paris');
$tree->put('England' => 'London');
$tree->put('Hungary' => 'Budapest');
$tree->put('Ireland' => 'Dublin');
$tree->put('Egypt' => 'Cairo');

#               |
#          <B:France>
#       /--------------\
#       |              |
#  <B:England>    <B:Hungary>
#     /------\   /-------\
#     |      |   |       |
# <R:Egypt> <*> <*> <R:Ireland>
#   /---\              /---\
#   |   |              |   |
#  <*> <*>            <*> <*>

is($tree->delete('Hungary')->key, 'Hungary', 'delete intermediate node');
$tree->put('Hungary' => 'Budapest');

is($tree->delete('England')->key, 'England', 'delete intermediate node');
$tree->put('England' => 'London');

$tree->delete('Egypt');
is($tree->min->key,  'England', q[new min after deleting current min]);
is($tree->max->key,  'Ireland', q[max not changed after deleting current min]);

#              |
#         <B:France>
#      /-------------\
#      |             |
# <B:England>   <B:Hungary>
#    /---\     /-------\
#    |   |     |       |
#   <*> <*>   <*> <R:Ireland>
#                    /---\
#                    |   |
#                   <*> <*>

$tree->delete('Ireland');
is($tree->max->key,  'Hungary', q[new max after deleting current max]);
is($tree->min->key,  'England', q[min not changed after deleting current max]);

#            |
#       <B:France>
#      /-----------\
#      |           |
# <B:England> <B:Hungary>
#    /---\       /---\
#    |   |       |   |
#   <*> <*>     <*> <*>

is($tree->delete('France')->key, 'France', 'delete node with two kids');
is($tree->root->key,  'Hungary', q[new root]);
is($tree->max->key,  'Hungary', q[max not changed]);
is($tree->min->key,  'England', q[min not changed]);
