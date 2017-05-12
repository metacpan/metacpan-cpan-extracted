#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 22;

BEGIN { 
    use_ok('Tree::Parser') 
}

{
    my $tree_string = <<TREE_STRING;
1 First Child
1.1 First Grandchild
1.2 Second Grandchild
1.2.1 First Child of the Second Grandchild
1.3 Third Grandchild
2 Second Child
TREE_STRING
    chomp $tree_string;
    
    my $tp = Tree::Parser->new($tree_string);
    isa_ok($tp, "Tree::Parser");
    
    $tp->useDotSeperatedLevelFilters();
    
    my $tree = $tp->parse();
    isa_ok($tree, "Tree::Simple");
    
    my $output = scalar $tp->deparse();
    is($output, $tree_string, '... round trip successful');
}

{
    my $tree_string = <<TREE_STRING;
a First Child
a.a First Grandchild
a.b Second Grandchild
a.b.a First Child of the Second Grandchild
a.c Third Grandchild
b Second Child
TREE_STRING
    chomp $tree_string;
    
    my $tp = Tree::Parser->new($tree_string);
    isa_ok($tp, "Tree::Parser");
    
    $tp->useDotSeperatedLevelFilters('a' .. 'z');
    
    my $tree = $tp->parse();
    isa_ok($tree, "Tree::Simple");
    
    my $output = scalar $tp->deparse();
    
    is($output, $tree_string, '... round trip successful');
}

{
    my $tree_string = <<TREE_STRING;
1.0
    1.1
    1.2
        1.2.1
2.0
    2.1
3.0
    3.1
        3.1.1
TREE_STRING
    chomp $tree_string;
    
    my $tp = Tree::Parser->new($tree_string);
    isa_ok($tp, "Tree::Parser");
    
    $tp->useTabIndentedFilters();
    
    my $tree = $tp->parse();
    isa_ok($tree, "Tree::Simple");
    
    my $output = scalar $tp->deparse();
    is($output, $tree_string, '... round trip successful');
}

{
    my $tree_string = <<TREE_STRING;
1.0
  1.1
  1.2
  1.3
2.0
  2.1
    2.1.1
  2.2
3.0
TREE_STRING
    chomp $tree_string;
    
    my $tp = Tree::Parser->new($tree_string);
    isa_ok($tp, "Tree::Parser");
    
    $tp->useTabIndentedFilters();
    
    my $tree = $tp->parse();
    isa_ok($tree, "Tree::Simple");
    
    my $output = scalar $tp->deparse();
    is($output, $tree_string, '... round trip successful');
}

# testing the new parens filters
{
    my $tp = Tree::Parser->new("(1.0 (1.1 1.2 1.3) 2.0 (2.1 (2.1.1) 2.2) 3.0 (3.1))");
    isa_ok($tp, "Tree::Parser");
    
    $tp->useNestedParensFilters();     
    
    my $tree = $tp->parse();
    isa_ok($tree, "Tree::Simple");
    
    my @accumulation;
    $tree->traverse(sub {
        my ($tree) = @_;
        push @accumulation, $tree->getNodeValue();
    });
    
    is_deeply(
        [ @accumulation ], 
        [ qw/1.0 1.1 1.2 1.3 2.0 2.1 2.1.1 2.2 3.0 3.1/ ]
        , '... parsed correctly');
}

{
    my $tp = Tree::Parser->new('(root ("tree 1" "tree 2" ("tree 2 1")))');
    isa_ok($tp, "Tree::Parser");
    
    $tp->useNestedParensFilters();     
    
    my $tree = $tp->parse();
    isa_ok($tree, "Tree::Simple");
    
    my @accumulation;
    $tree->traverse(sub {
        my ($tree) = @_;
        push @accumulation, $tree->getNodeValue();
    });
    
    is_deeply(
        [ @accumulation ], 
        [ "root", "tree 1", "tree 2", "tree 2 1" ]
        , '... parsed correctly');
}

{
    my $tp = Tree::Parser->new('(root (1 2 (0)))');
    isa_ok($tp, "Tree::Parser");
    
    $tp->useNestedParensFilters();     
    
    my $tree = $tp->parse();
    isa_ok($tree, "Tree::Simple");
    
    my @accumulation;
    $tree->traverse(sub {
        my ($tree) = @_;
        push @accumulation, $tree->getNodeValue();
    });
    
    is_deeply(
        [ @accumulation ], 
        [ "root", "1", "2", "0" ]
        , '... parsed correctly');
}



