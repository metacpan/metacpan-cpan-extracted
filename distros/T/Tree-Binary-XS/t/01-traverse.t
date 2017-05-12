#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 12;
BEGIN { use_ok('Tree::Binary::XS') };

#########################
use Data::RandomPerson::Names::Female;

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $tree = Tree::Binary::XS->new({ by_key => 'id' });
ok($tree);

my $f = Data::RandomPerson::Names::Female->new();

ok $tree->insert({ name => $f->get, id => 5 });
ok $tree->insert({ name => $f->get, id => 3 });
ok $tree->insert({ name => $f->get, id => 2 });
ok $tree->insert({ name => $f->get, id => 4 });
ok $tree->insert({ name => $f->get, id => 7 });
ok $tree->insert({ name => $f->get, id => 8 });
ok $tree->insert({ name => $f->get, id => 6 });
# $tree->dump();
my @keys = ();
$tree->inorder_traverse(sub { 
        my ($key, $node) = @_;
        push @keys, $key;
    });
is_deeply([3, 2, 4, 5, 7, 6, 8], \@keys, '[' . join(', ', @keys) . ']');

@keys = ();
$tree->preorder_traverse(sub { 
        my ($key, $node) = @_;
        push @keys, $key;
    });
is_deeply([5, 3, 2, 4, 7, 6, 8], \@keys, '[' . join(', ', @keys) . ']');

@keys = ();
$tree->postorder_traverse(sub { 
        my ($key, $node) = @_;
        push @keys, $key;
    });
is_deeply([3, 2, 4, 7, 6, 8, 5], \@keys, '[' . join(', ', @keys) . ']');
