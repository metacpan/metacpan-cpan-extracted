use strict;
use warnings;

use Test::More tests => 10;

BEGIN {
    use_ok('Tree::Binary');
    use_ok('Tree::Binary::Visitor::InOrderTraversal');
}

## ----------------------------------------------------------------------------
# NOTE:
# This specifically tests the mirror function with both a well balanced tree
# and a more chaotic one
## ----------------------------------------------------------------------------

# test it on a simple well balanaced tree
{
    my $btree = Tree::Binary->new(4)
                    ->setLeft(
                        Tree::Binary->new(2)
                            ->setLeft(
                                Tree::Binary->new(1)
                                )
                            ->setRight(
                                Tree::Binary->new(3)
                                )
                        )
                    ->setRight(
                        Tree::Binary->new(6)
                            ->setLeft(
                                Tree::Binary->new(5)
                                )
                            ->setRight(
                                Tree::Binary->new(7)
                                )
                        );
    isa_ok($btree, 'Tree::Binary');

    my $visitor = Tree::Binary::Visitor::InOrderTraversal->new();
    isa_ok($visitor, 'Tree::Binary::Visitor::InOrderTraversal');

    $btree->accept($visitor);

    is_deeply(
        [ $visitor->getResults() ],
        [ 1 .. 7 ],
        '... check that our tree starts out correctly');

    can_ok($btree, 'mirror');
    $btree->mirror();

    $btree->accept($visitor);

    is_deeply(
        [ $visitor->getResults() ],
        [ reverse(1 .. 7) ],
        '... check that our tree ends up correctly');
}

# test is on a more chaotic tree
{
    my $btree = Tree::Binary->new(4)
                    ->setLeft(
                        Tree::Binary->new(20)
                            ->setLeft(
                                Tree::Binary->new(1)
                                        ->setRight(
                                            Tree::Binary->new(10)
                                                ->setLeft(
                                                    Tree::Binary->new(5)
                                                )
                                        )
                                )
                            ->setRight(
                                Tree::Binary->new(3)
                                )
                        )
                    ->setRight(
                        Tree::Binary->new(6)
                            ->setLeft(
                                Tree::Binary->new(5)
                                    ->setRight(
                                        Tree::Binary->new(7)
                                            ->setLeft(
                                                Tree::Binary->new(90)
                                            )
                                            ->setRight(
                                                Tree::Binary->new(91)
                                            )
                                        )
                                )
                        );
    isa_ok($btree, 'Tree::Binary');

    my $visitor = Tree::Binary::Visitor::InOrderTraversal->new();
    isa_ok($visitor, 'Tree::Binary::Visitor::InOrderTraversal');

    $btree->accept($visitor);
    my @results = $visitor->getResults();

    $btree->mirror();

    $btree->accept($visitor);
    is_deeply(
        [ $visitor->getResults() ],
        [ reverse(@results) ],
        '... this should be the reverse of the original');
}
