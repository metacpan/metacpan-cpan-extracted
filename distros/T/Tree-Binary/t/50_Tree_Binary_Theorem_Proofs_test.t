use strict;
use warnings;

use Tree::Binary::Search;
use Tree::Binary::VisitorFactory;

use Test::More tests => 140;

## ----------------------------------------------------------------------------
## Theorem Proving and Unit tests
## ----------------------------------------------------------------------------
# This test is an attempt at trying to use Theorems to build useful unit tests
# with.
#
# For more on this topic, see the following Perl Monks node:
#   http://www.perlmonks.org/index.pl?node_id=385774
#
# BTW, these theorems are not mine, but instead they come from the book:
#   'ML for the Working Programmer by L. C. Paulson'
# specifically chapter 6 and the subsection the section 6.5 entitled
# 'Structural induction on trees'.
## ----------------------------------------------------------------------------

# NOTE:
# it makes sense to do this more than once,
# so we loop a couple of times to test. I got
# this idea from reading about the QuickCheck
# testing tool for Haskell.
#   http://www.cs.chalmers.se/~rjmh/QuickCheck/

foreach (1 .. 20) {
    # create a random binary tree
    my $num_nodes = int rand() * 100;
    $num_nodes++ if $num_nodes == 0;
    my $tree = rand_tree($num_nodes);

    ## ----------------------------------------------
    ## preorder(mirror(mirror(t))) = preorder(t)
    ## ----------------------------------------------
    # The mirror of a mirror of a tree is equal to
    # the original tree.
    ## ----------------------------------------------

    is_deeply(
        [ preorder(mirror(mirror($tree))) ],
        [ preorder($tree) ]
        , '... mirror(mirror(t)) = t');

    ## ----------------------------------------------
    ## size(mirror(t)) = size(t)
    ## ----------------------------------------------
    # The size of a mirror of a tree is equal to the
    # size of the original tree.
    ## ----------------------------------------------

    cmp_ok(size(mirror($tree)), '==', size($tree), '... size(mirror(t)) = size(t)');

    ## ----------------------------------------------
    ## postorder(mirror(t)) = reverse(preorder(t))
    ## ----------------------------------------------
    # The portorder of a mirror of a tree is equal to
    # the reverse of the preorder of the tree.
    ## ----------------------------------------------

    is_deeply(
        [ postorder(mirror($tree)) ],
        [ reverse(preorder($tree)) ]
        , '... postorder(mirror(t)) = reverse(preorder(t))');

    ## ----------------------------------------------
    ## inorder(mirror(t)) = reverse(inorder(t))
    ## ----------------------------------------------
    # The inorder of a mirror-ed tree is equal to the
    # reverse of the inorder of the tree.
    ## ----------------------------------------------

    is_deeply(
        [ inorder(mirror($tree)) ],
        [ reverse(inorder($tree)) ]
        , '... inorder(mirror(t)) = reverse(inorder(t))');

    ## ----------------------------------------------
    ## reverse(inorder(mirror(t))) = inorder(t)
    ## ----------------------------------------------
    # The reverse of the inorder of the mirror of the
    # tree is equal to the inorder of the tree.
    ## ----------------------------------------------

    is_deeply(
        [ reverse(inorder(mirror($tree))) ],
        [ inorder($tree) ]
        , '... reverse(inorder(mirror(t))) = inorder(t)');

    ## ----------------------------------------------
    ## size(t) <= 2 ** height(t) - 1
    ## ----------------------------------------------
    # The size of a tree is less than or equal to
    # 2 to the power of the the height of the tree
    # minus 1.
    ## ----------------------------------------------

    cmp_ok(size($tree), '<=', ((2 ** height($tree)) - 1), '... size(t) <= 2 ** height(t) - 1');

    ## ----------------------------------------------
    ## length(preorder(t)) = size(t)
    ## ----------------------------------------------
    # The length of the preorder is the same as the
    # size of the tree
    ## ----------------------------------------------

    cmp_ok(scalar(preorder($tree)), '==', size($tree), '... length(preorder(t)) = size(t)');

}

## ----------------------------------------------------------------------------
## convience functions for proofs
## ----------------------------------------------------------------------------

sub rand_tree {
    my ($num_nodes) = @_;
    my $rand_ceil = $num_nodes * 2;

    my $btree = Tree::Binary::Search->new();
    $btree->useNumericComparison();

    for (0 .. $num_nodes) {
        my $num = ((rand() * $rand_ceil) % $rand_ceil);
        while ($btree->exists($num)) {
            $num = ((rand() * $rand_ceil) % $rand_ceil);
        }
        $btree->insert($num => $num);
    }

    return $btree->getTree();
}

sub mirror {
    my ($tree) = @_;
    return $tree->clone()->mirror();
}

sub size {
    my ($tree) = @_;
    return $tree->size();
}

sub height {
    my ($tree) = @_;
    return $tree->height();
}

sub postorder {
    my ($tree) = @_;
    my $visitor = Tree::Binary::VisitorFactory->get('PostOrderTraversal');
    $tree->accept($visitor);
    my @results = $visitor->getResults();
    return @results;
}

sub inorder {
    my ($tree) = @_;
    my $visitor = Tree::Binary::VisitorFactory->get('InOrderTraversal');
    $tree->accept($visitor);
    my @results = $visitor->getResults();
    return @results;
}

sub preorder {
    my ($tree) = @_;
    my $visitor = Tree::Binary::VisitorFactory->get('PreOrderTraversal');
    $tree->accept($visitor);
    my @results = $visitor->getResults();
    return @results;
}

## ----------------------------------------------------------------------------