#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

BEGIN { 
    use_ok('Tree::Parser') 
}

# 1
#   2
#     3
# 4
my $tree = Tree::Simple->new(Tree::Simple->ROOT)
            ->addChildren(
                Tree::Simple->new("1")
                            ->addChild(
                                Tree::Simple->new("2")
                                    ->addChild(
                                        Tree::Simple->new("3")
                                    ),
                            ),
                Tree::Simple->new("4")
            );	

isa_ok($tree, "Tree::Simple");
 
{                       
    my $tp = Tree::Parser->new($tree);
    isa_ok($tp, "Tree::Parser");
    
    $tp->useNestedParensFilters();
    
    my $deparsed_string = join "", $tp->deparse();
    
    is($deparsed_string, '(1 (2 (3)) 4)', 'tree deparsed correctly');
}