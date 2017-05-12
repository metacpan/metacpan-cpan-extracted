use strict;
use warnings;

use Test::More tests => 43;

BEGIN {
    use_ok('Tree::Binary');
    use_ok('Tree::Binary::Visitor::PreOrderTraversal');
    use_ok('Tree::Binary::Visitor::PostOrderTraversal');
    use_ok('Tree::Binary::Visitor::InOrderTraversal');
    use_ok('Tree::Binary::Visitor::BreadthFirstTraversal');
}

my $btree = Tree::Binary->new("/")
                        ->setLeft(
                            Tree::Binary->new("+")
                                        ->setLeft(
                                            Tree::Binary->new("2")
                                        )
                                        ->setRight(
                                            Tree::Binary->new("2")
                                        )
                        )
                        ->setRight(
                            Tree::Binary->new("*")
                                        ->setLeft(
                                            Tree::Binary->new("4")
                                        )
                                        ->setRight(
                                            Tree::Binary->new("5")
                                        )
                        );
isa_ok($btree, 'Tree::Binary');

# check the Visitors

can_ok($btree, 'accept');

{

    can_ok("Tree::Binary::Visitor::PreOrderTraversal", 'new');
    my $visitor = Tree::Binary::Visitor::PreOrderTraversal->new();
    isa_ok($visitor, 'Tree::Binary::Visitor::PreOrderTraversal');
    isa_ok($visitor, 'Tree::Binary::Visitor::Base');

    can_ok($visitor, 'visit');
    $btree->accept($visitor);

    can_ok($visitor, 'getResults');
    is_deeply(
            [ $visitor->getResults() ],
            [ qw(/ + 2 2 * 4 5) ],
            '... our PreOrder Traversal works');
}

{

    my $visitor = Tree::Binary::Visitor::PreOrderTraversal->new();
    isa_ok($visitor, 'Tree::Binary::Visitor::PreOrderTraversal');

    can_ok($visitor, 'setNodeFilter');
    $visitor->setNodeFilter(sub { "-" . $_[0]->getNodeValue() . "-" });

    $btree->accept($visitor);

    is_deeply(
            scalar $visitor->getResults(),
            [ qw(-/- -+- -2- -2- -*- -4- -5-) ],
            '... our PreOrder Traversal works');
}

{
    can_ok("Tree::Binary::Visitor::PostOrderTraversal", 'new');
    my $visitor = Tree::Binary::Visitor::PostOrderTraversal->new();
    isa_ok($visitor, 'Tree::Binary::Visitor::PostOrderTraversal');
    isa_ok($visitor, 'Tree::Binary::Visitor::Base');

    can_ok($visitor, 'visit');
    $btree->accept($visitor);

    can_ok($visitor, 'getResults');
    is_deeply(
            [ $visitor->getResults() ],
            [ qw(2 2 + 4 5 * /) ],
            '... our PostOrder Traversal works');
}

{
    my $visitor = Tree::Binary::Visitor::PostOrderTraversal->new();
    isa_ok($visitor, 'Tree::Binary::Visitor::PostOrderTraversal');

    can_ok($visitor, 'setNodeFilter');
    $visitor->setNodeFilter(sub { "-" . $_[0]->getNodeValue() . "-" });

    $btree->accept($visitor);
    is_deeply(
            scalar $visitor->getResults(),
            [ qw(-2- -2- -+- -4- -5- -*- -/-) ],
            '... our PostOrder Traversal works');
}

{
    can_ok("Tree::Binary::Visitor::InOrderTraversal", 'new');
    my $visitor = Tree::Binary::Visitor::InOrderTraversal->new();
    isa_ok($visitor, 'Tree::Binary::Visitor::InOrderTraversal');
    isa_ok($visitor, 'Tree::Binary::Visitor::Base');

    can_ok($visitor, 'visit');
    $btree->accept($visitor);

    can_ok($visitor, 'getResults');
    is_deeply(
            [ $visitor->getResults() ],
            [ qw(2 + 2 / 4 * 5) ],
            '... our InOrder Traversal works');
}

{
    my $visitor = Tree::Binary::Visitor::InOrderTraversal->new();
    isa_ok($visitor, 'Tree::Binary::Visitor::InOrderTraversal');

    can_ok($visitor, 'setNodeFilter');
    $visitor->setNodeFilter(sub { "-" . $_[0]->getNodeValue() . "-" });

    $btree->accept($visitor);
    is_deeply(
            scalar $visitor->getResults(),
            [ qw(-2- -+- -2- -/- -4- -*- -5-) ],
            '... our InOrder Traversal works');
}

{
    can_ok("Tree::Binary::Visitor::BreadthFirstTraversal", 'new');
    my $visitor = Tree::Binary::Visitor::BreadthFirstTraversal->new();
    isa_ok($visitor, 'Tree::Binary::Visitor::BreadthFirstTraversal');
    isa_ok($visitor, 'Tree::Binary::Visitor::Base');

    can_ok($visitor, 'visit');
    $btree->accept($visitor);

    can_ok($visitor, 'getResults');
    is_deeply(
            [ $visitor->getResults() ],
            [ qw(/ + * 2 2 4 5) ],
            '... our PreOrder Traversal works');
}

{
    my $visitor = Tree::Binary::Visitor::BreadthFirstTraversal->new();
    isa_ok($visitor, 'Tree::Binary::Visitor::BreadthFirstTraversal');

    can_ok($visitor, 'setNodeFilter');
    $visitor->setNodeFilter(sub { "-" . $_[0]->getNodeValue() . "-" });

    $btree->accept($visitor);
    is_deeply(
            scalar $visitor->getResults(),
            [ qw(-/- -+- -*- -2- -2- -4- -5-) ],
            '... our PreOrder Traversal works');
}
