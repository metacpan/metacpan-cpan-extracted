#!perl

use strict;
use warnings;

use Test::More 0.98;
use Tree::Create::Callback::ChildrenPerLevel qw(create_tree_using_callback);
use Tree::Dump;
use Tree::Object::Hash;

my $tree;
{
    my $i = 0;
    $tree = create_tree_using_callback(
        sub {
            my ($parent, $level, $seniority) = @_;
            (Tree::Object::Hash->new(id => $i++));
        },
        [3, 2, 3],
    );
}

my $exp_tree = do {
    my $root = Tree::Object::Hash->new(id=>0);
    my $c1   = Tree::Object::Hash->new(id=>1); $c1->parent($root);
    my $c2   = Tree::Object::Hash->new(id=>2); $c2->parent($root);
    my $c3   = Tree::Object::Hash->new(id=>3); $c3->parent($root);
    $root->children([$c1, $c2, $c3]);

    my $gc11 = Tree::Object::Hash->new(id=>4); $gc11->parent($c1);
    $c1->children([$gc11]);

    my $gc31 = Tree::Object::Hash->new(id=>5); $gc31->parent($c3);
    $c3->children([$gc31]);

    my $ggc111 = Tree::Object::Hash->new(id=>6); $ggc111->parent($gc11);
    my $ggc112 = Tree::Object::Hash->new(id=>7); $ggc112->parent($gc11);
    $gc11->children([$ggc111, $ggc112]);

    my $ggc311 = Tree::Object::Hash->new(id=>8); $ggc311->parent($gc31);
    $gc31->children([$ggc311]);

    $root;
};

is_deeply($tree, $exp_tree) or do {
    diag "tree:\n", td($tree), "\n";
    diag "expected tree:\n", td($exp_tree);
};

# XXX test _args
# XXX test _constructor

done_testing;
