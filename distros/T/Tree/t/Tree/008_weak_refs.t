use strict;
use warnings;

use Test::More;

eval "use Test::Memory::Cycle 1.02";
plan skip_all => "Test::Memory::Cycle required for testing memory leaks" if $@;

plan tests => 43;

my $CLASS = 'Tree';
use_ok( $CLASS )
    or Test::More->builder->BAILOUT( "Cannot load $CLASS" );

{ #diag "parental connections are weak";

    my $tree2 = $CLASS->new();
    ok($tree2->is_root(), '... tree2 is a ROOT');

    {
        my $tree1 = $CLASS->new("1");
        $tree1->add_child($tree2);
        ok(!$tree2->is_root(), '... now tree2 is not a ROOT');

        weakened_memory_cycle_exists($tree2, '... there is a weakened cycle in tree2');
    }

    weakened_memory_cycle_ok($tree2, '... tree2 is no longer connected to tree1');
    ok($tree2->is_root(), '... now tree2 is a ROOT again');
    ok(!$tree2->parent(), '... now tree2s parent is no longer defined');
}

{ #diag "expand the problem to check child connections";

    my $tree2 = $CLASS->new("2");
    ok($tree2->is_root(), '... tree2 is a ROOT');
    ok($tree2->is_leaf(), '... tree2 is a Leaf');
    my $tree3 = $CLASS->new("3");
    ok($tree3->is_root(), '... tree3 is a ROOT');
    ok($tree3->is_leaf(), '... tree3 is a Leaf');

    {
        my $tree1 = $CLASS->new("1");
        $tree1->add_child($tree2);
        ok(!$tree2->is_root(), '... now tree2 is not a ROOT');
        $tree2->add_child($tree3);
        ok(!$tree2->is_leaf(), '... now tree2 is not a Leaf');
        ok(!$tree3->is_root(), '... tree3 is no longer a ROOT');
        ok($tree3->is_leaf(), '... but tree3 is still a Leaf');

        weakened_memory_cycle_exists($tree1, '... there is a cycle in tree1');
        weakened_memory_cycle_exists($tree2, '... there is a cycle in tree2');
        weakened_memory_cycle_exists($tree3, '... there is a cycle in tree3');
    }

    weakened_memory_cycle_exists($tree2, '... calling DESTORY on tree1 broke the connection with tree2');
    ok($tree2->is_root(), '... now tree2 is a ROOT again');
    ok(!$tree2->is_leaf(), '... now tree2 is a not a leaf again');
    ok(!$tree2->parent(), '... now tree2s parent is no longer defined');
    cmp_ok($tree2->children(), '==', 1, '... now tree2 has one child');
    weakened_memory_cycle_exists($tree3, '... calling DESTORY on tree1 did not break the connection betwee tree2 and tree3');
    ok(!$tree3->is_root(), '... now tree3 is not a ROOT');
    ok($tree3->is_leaf(), '... now tree3 is still a leaf');
    ok(defined($tree3->parent()), '... now tree3s parent is still defined');
    is($tree3->parent(), $tree2, '... now tree3s parent is still tree2');
}

{ #diag "child connections are strong";
    my $tree1 = $CLASS->new("1");
    my $tree2_string;

    {
        my $tree2 = $CLASS->new("2");
        $tree1->add_child($tree2);
        $tree2_string = $tree2 . "";

        weakened_memory_cycle_exists($tree1, '... tree1 is connected to tree2');
        weakened_memory_cycle_exists($tree2, '... tree2 is connected to tree1');
    }

    weakened_memory_cycle_exists($tree1, '... tree2 is still connected to tree1 because child connections are strong');
    is($tree1->children(0) . "", $tree2_string, '... tree2 is still connected to tree1');
    is($tree1->children(0)->parent(), $tree1, '... tree2s parent is tree1');
    cmp_ok($tree1->children(), '==', 1, '... tree1 has a child count of 1');
}


{ #diag "expand upon this issue";
    my $tree1 = $CLASS->new("1");
    my $tree2_string;
    my $tree3 = $CLASS->new("3");

    {
        my $tree2 = $CLASS->new("2");
        $tree1->add_child($tree2);
        $tree2_string = $tree2 . "";
        $tree2->add_child($tree3);

        weakened_memory_cycle_exists($tree1, '... tree1 is connected to tree2');
        weakened_memory_cycle_exists($tree2, '... tree2 is connected to tree1');
        weakened_memory_cycle_exists($tree3, '... tree3 is connected to tree2');
    }

    weakened_memory_cycle_exists($tree1, '... tree2 is still connected to tree1 because child connections are strong');
    is($tree1->children(0) . "", $tree2_string, '... tree2 is still connected to tree1');
    is($tree1->children(0)->parent(), $tree1, '... tree2s parent is tree1');
    cmp_ok($tree1->children(), '==', 1, '... tree1 has a child count of 1');
    cmp_ok($tree1->children(0)->children(), '==', 1, '... tree2 is still connected to tree3');
    is($tree1->children(0)->children(0), $tree3, '... tree2 is still connected to tree3');
}
