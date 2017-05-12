use strict;
use warnings;

use Test::More tests => 40;

BEGIN {
    use_ok('Tree::Binary::Search');
    use_ok('Tree::Binary::Visitor::InOrderTraversal');
}

# NOTE:
# this test will check that the nodes are deleted from the
# tree, and the tree behaves as expected. It test the three
# cases as described in :
# http://www.msu.edu/~pfaffben/avl/libavl.html/Deleting-from-a-BST.html
# which should be reasonably sufficient.

# sub show_tree {
#     my ($btree) = @_;
#     my $visitor = Tree::Binary::Visitor::InOrderTraversal->new();
#     $visitor->setNodeFilter(sub {
#         my ($t) = @_;
#         diag(("  |" x $t->getDepth()) . "--" . $t->getNodeValue());
#     });
#     $btree->accept($visitor);
# }

sub check_tree {
    my ($btree, @expected_results) = @_;
    my $visitor = Tree::Binary::Visitor::InOrderTraversal->new();
    $btree->accept($visitor);
    is_deeply(
            [ $visitor->getResults() ],
            [ @expected_results ],
            '... tree is as expected');
}

{
    my $btree = Tree::Binary::Search->new();
    isa_ok($btree, 'Tree::Binary::Search');

    $btree->useNumericComparison();

    $btree->insert(5 => 5);
    $btree->insert(2 => 2);
    $btree->insert(1 => 1);
    $btree->insert(3 => 3);
    $btree->insert(4 => 4);
    $btree->insert(9 => 9);
    $btree->insert(8 => 8);
    $btree->insert(6 => 6);
    $btree->insert(7 => 7);

    check_tree($btree => (1, 2, 3, 4, 5, 6, 7, 8, 9));
    #show_tree($btree);

    ok($btree->delete(8), '... the node was successfully deleted');
    check_tree($btree => (1, 2, 3, 4, 5, 6, 7, 9));
    #show_tree($btree);

    ok($btree->delete(2), '... the node was successfully deleted');
    check_tree($btree => (1, 3, 4, 5, 6, 7, 9));
    #show_tree($btree);

    ok($btree->delete(5), '... the node was successfully deleted');
    check_tree($btree => (1, 3, 4, 6, 7, 9));
    #show_tree($btree);

    ok($btree->delete(6), '... the node was successfully deleted');
    check_tree($btree => (1, 3, 4, 7, 9));
    #show_tree($btree);

    ok($btree->delete(3), '... the node was successfully deleted');
    check_tree($btree => (1, 4, 7, 9));
    #show_tree($btree);

    ok($btree->delete(7), '... the node was successfully deleted');
    check_tree($btree => (1, 4, 9));
    #show_tree($btree);

    ok($btree->delete(4), '... the node was successfully deleted');
    check_tree($btree => (1, 9));
    #show_tree($btree);

    ok($btree->delete(9), '... the node was successfully deleted');
    check_tree($btree => (1));
    #show_tree($btree);

    ok($btree->delete(1), '... the node was successfully deleted');
    ok($btree->isEmpty(), '... our tree is now empty');
}

{
    my $btree = Tree::Binary::Search->new();
    isa_ok($btree, 'Tree::Binary::Search');

    $btree->useNumericComparison();

    $btree->insert(44 => 44);
    $btree->insert(17 => 17);
    $btree->insert(32 => 32);
    $btree->insert(28 => 28);
    $btree->insert(29 => 29);
    $btree->insert(88 => 88);
    $btree->insert(65 => 65);
    $btree->insert(54 => 54);
    $btree->insert(82 => 82);
    $btree->insert(76 => 76);
    $btree->insert(80 => 80);
    $btree->insert(78 => 78);
    $btree->insert(97 => 97);

    check_tree($btree => (17, 28, 29, 32, 44, 54, 65, 76, 78, 80, 82, 88, 97));
    #show_tree($btree);

    ok($btree->delete(32), '... the node was successfully deleted');
    check_tree($btree => (17, 28, 29, 44, 54, 65, 76, 78, 80, 82, 88, 97));
    #show_tree($btree);

    ok($btree->delete(65), '... the node was successfully deleted');
    check_tree($btree => (17, 28, 29, 44, 54, 76, 78, 80, 82, 88, 97));
    #show_tree($btree);

    ok($btree->delete(76), '... the node was successfully deleted');
    check_tree($btree => (17, 28, 29, 44, 54, 78, 80, 82, 88, 97));
    #show_tree($btree);

}

{
    my $btree = Tree::Binary::Search->new();
    isa_ok($btree, 'Tree::Binary::Search');

    $btree->useStringComparison();

    $btree->insert('UT' => 'UT');
    $btree->insert('NV' => 'NV');
    $btree->insert('VA' => 'VA');
    $btree->insert('TX' => 'TX');
    $btree->insert('NY' => 'NY');
    $btree->insert('AK' => 'AK');
    $btree->insert('AZ' => 'AZ');
    $btree->insert('AR' => 'AR');
    $btree->insert('MI' => 'MI');
    $btree->insert('CA' => 'CA');

    check_tree($btree => qw(AK AR AZ CA MI NV NY TX UT VA));
    #show_tree($btree);

    ok($btree->delete('NV'), '... the node was successfully deleted');
    check_tree($btree => qw(AK AR AZ CA MI NY TX UT VA));
    #show_tree($btree);

    ok($btree->delete('AK'), '... the node was successfully deleted');
    check_tree($btree => qw(AR AZ CA MI NY TX UT VA));
    #show_tree($btree);

    ok($btree->delete('AZ'), '... the node was successfully deleted');
    check_tree($btree => qw(AR CA MI NY TX UT VA));
    #show_tree($btree);

    ok($btree->delete('NY'), '... the node was successfully deleted');
    check_tree($btree => qw(AR CA MI TX UT VA));
    #show_tree($btree);
}

