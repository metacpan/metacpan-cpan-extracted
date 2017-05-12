#!perl

use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More 0.98;
use TN0;
use TN;
use Tree::FromStruct qw(build_tree_from_struct);


my $tree = build_tree_from_struct({
    _class => 'TN0', id => 'root', _children => [
        {id=>'a', _class => 'TN'},
        {id=>'b', _children => [
            {id => 'c'},
            {id => 'd'},
        ]},
    ]});

my $exp_tree = do {
    my $root = TN0->new(id=>'root', children=>[]);
    my $a = TN ->new(id=>'a', parent=>$root, children=>[]);
    my $b = TN0->new(id=>'b', parent=>$root, children=>[]);
    my $c = TN0->new(id=>'c', parent=>$b, children=>[]);
    my $d = TN0->new(id=>'d', parent=>$b, children=>[]);
    $root->children($a, $b);
    $b->children($c, $d);
    $root;
};

is_deeply($tree, $exp_tree) or do {
    diag "tree: ", explain $tree;
    diag "expected tree: ", explain $exp_tree;
};

# XXX test _args
# XXX test _constructor

done_testing;
