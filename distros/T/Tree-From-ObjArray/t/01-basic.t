#!perl

use strict;
use warnings;
use Test::More 0.98;

use FindBin '$Bin';
use lib "$Bin/lib";

use TN0;
use TN;
use Tree::From::ObjArray qw(build_tree_from_obj_array);

my $tree = build_tree_from_obj_array([
    TN0->new(id=>'root'), [
        TN->new(id=>'a'),
        TN->new(id=>'b'), [
            TN->new(id=>'c'),
            TN->new(id=>'d'),
        ],
    ],
]);

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

done_testing;
