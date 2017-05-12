#!perl

use 5.010;
use strict;
use warnings;

use Tree::Create::Size qw(create_tree);
use Test::More 0.98;
use Tree::Object::Hash;

# sanity test

subtest 'with height + num_children' => sub {
    my $i = 0;
    my $tree = create_tree(
        height => 3,
        num_children => 2,
        class => 'Tree::Object::Hash',
        code_create_node => sub {
            my ($class, $level, $parent) = @_;
            $class->new(id => $i++);
        },
    );

    is($i, 15, "number of nodes created");
};

subtest 'with num_nodes_per_level' => sub {
    my $i = 0;
    my $tree = create_tree(
        num_nodes_per_level => [100, 3000, 5000, 8000, 3000, 1000, 300],
        class => 'Tree::Object::Hash',
        code_create_node => sub {
            my ($class, $level, $parent) = @_;
            $class->new(id => $i++);
        },
    );

    is($i, 20401, "number of nodes created");
};

done_testing;
