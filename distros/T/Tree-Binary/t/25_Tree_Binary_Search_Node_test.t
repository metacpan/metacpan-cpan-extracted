use strict;
use warnings;

use Test::More tests => 9;
use Test::Exception;

BEGIN {
    use_ok('Tree::Binary::Search::Node');
}

# NOTE:
# this tests the things that wont get tested by Tree::Binary::Search

can_ok("Tree::Binary::Search::Node", 'new');

my $btree = Tree::Binary::Search::Node->new("Key" => "Value");

isa_ok($btree, 'Tree::Binary::Search::Node');
isa_ok($btree, 'Tree::Binary');

throws_ok {
    Tree::Binary::Search::Node->new();
} qr/Insufficient Arguments/, '... this should die';

throws_ok {
    Tree::Binary::Search::Node->new("Key");
} qr/Insufficient Arguments/, '... this should die';

can_ok($btree, 'clone');
my $clone = $btree->clone();

is($clone->getNodeKey(), $btree->getNodeKey(), '... the keys are the same');

can_ok($btree, 'makeRoot');
$btree->makeRoot();