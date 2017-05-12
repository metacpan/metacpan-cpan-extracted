use strict;
use warnings;

use Test::More;

eval "use Test::Memory::Cycle";
plan skip_all => "Test::Memory::Cycle required for testing memory leaks" if $@;

plan tests => 19;

use_ok('Tree::Binary');

# Destroying the root cascades
# down the subtrees and breaks
# connections
{
    my $tree1 = Tree::Binary->new("1");
    my $tree2 = Tree::Binary->new("2");
    my $tree3 = Tree::Binary->new("3");

    $tree1->setLeft($tree2);

    $tree2->setRight($tree3);

    $tree1->DESTROY();

    memory_cycle_ok($tree1, '... calling DESTORY on root cascaded down subtrees');
    memory_cycle_ok($tree2, '... calling DESTORY on root cascaded down subtrees');
    memory_cycle_ok($tree3, '... calling DESTORY on root cascaded down subtrees');
}

# destorying the middle tree will break
# connections with the parent as well as
# the children
{
    my $tree1 = Tree::Binary->new("1");
    my $tree2 = Tree::Binary->new("2");
    my $tree3 = Tree::Binary->new("3");

    $tree1->setLeft($tree2);

    $tree2->setRight($tree3);

    $tree2->DESTROY();

    memory_cycle_ok($tree1, '... calling DESTORY on middle child cascaded down subtrees and broke with parent');
    memory_cycle_ok($tree2, '... calling DESTORY on middle child cascaded down subtrees and broke with parent');
    memory_cycle_ok($tree3, '... calling DESTORY on middle child cascaded down subtrees and broke with parent');
}

# destroying the lowest child does not
# affect the parent's relationships
{
    my $tree1 = Tree::Binary->new("1");
    my $tree2 = Tree::Binary->new("2");
    my $tree3 = Tree::Binary->new("3");

    $tree1->setLeft($tree2);

    $tree2->setRight($tree3);

    $tree3->DESTROY();

    memory_cycle_ok($tree3, '... calling DESTROY properly seperated this tree');

    is($tree1->getLeft(), $tree2, '... our other relations are still intact');
    is($tree2->getParent(), $tree1, '... our other relations are still intact');
}

# calling removeChild on the parent of
# the lowest branch breaks all relations
# with the parent and the removed child
# can be reaped, but all else is fine
{
    my $tree1 = Tree::Binary->new("1");
    my $tree2 = Tree::Binary->new("2");
    my $tree3 = Tree::Binary->new("3");

    $tree1->setLeft($tree2);

    $tree2->setRight($tree3);

    $tree2->removeRight($tree3);

    memory_cycle_ok($tree3, '... calling removeChild on lowest branch breaks relations properly');

    is($tree1->getLeft(), $tree2, '... our other relations are still intact');
    is($tree2->getParent(), $tree1, '... our other relations are still intact');
}

# calling removeChild on the parent of
# the lowest branch breaks all relations
# with the parent and the removed child
# can be reaped, but all else is fine
{
    my $tree1 = Tree::Binary->new("1");
    my $tree2 = Tree::Binary->new("2");
    my $tree3 = Tree::Binary->new("3");

    $tree1->setLeft($tree2);

    $tree2->setRight($tree3);

    my $removed = $tree1->removeLeft($tree2);

    memory_cycle_ok($tree1, '... calling removeChild on the middle tree leaves the root with no relations');

    is($removed->getRight(), $tree3, '... our relations with the middle tree and lowest branch are still intact');
    is($tree3->getParent(), $removed, '... our relations with the middle tree and lowest branch are still intact');

    $removed->DESTROY();

    memory_cycle_ok($tree2,   '... calling DESTROY on the removed child breaks it relations');
    memory_cycle_ok($removed, '... calling DESTROY on the removed child breaks it relations');
    memory_cycle_ok($tree3,   '... calling DESTROY on the removed child breaks it relations');
}
