#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 22;

BEGIN { 
    use_ok('Tree::Parser') 
}

use Tree::Simple;
use Array::Iterator;

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

my $tree = Tree::Simple->new(Tree::Simple->ROOT)
            ->addChildren(
                Tree::Simple->new("1.0")
                            ->addChildren(
                            Tree::Simple->new("1.1"),
                            Tree::Simple->new("1.2"),
                            Tree::Simple->new("1.3")
                            ),
                Tree::Simple->new("2.0")
                            ->addChildren(
                            Tree::Simple->new("2.1")
                                        ->addChildren(
                                        Tree::Simple->new("2.1.1"),
                                        ),
                            Tree::Simple->new("2.2")                                        
                            ),
                Tree::Simple->new("3.0")
            );	

isa_ok($tree, "Tree::Simple");
 
# tree as input 
{                       
    my $tp = Tree::Parser->new($tree);
    
    isa_ok($tp, "Tree::Parser");
    
    $tp->useSpaceIndentedFilters(2);
    
    my @deparsed_string = $tp->deparse();
    
    is((join "\n" => @deparsed_string), $tree_string, '... deparse worked');
}

# using setInput to set a string
{
    my $tp = Tree::Parser->new();
    isa_ok($tp, "Tree::Parser");
    
    $tp->setInput($tree_string);
    
    $tp->useSpaceIndentedFilters(2);   
    
    $tp->parse();
    
    my $tree = $tp->getTree();

    isa_ok($tree, "Tree::Simple");
    
    my @accumulation;
    $tree->traverse(sub {
        my ($tree) = @_;
        push @accumulation, $tree->getNodeValue();
    });
    
    is_deeply(
        [ @accumulation ], 
        [ qw/1.0 1.1 1.2 1.3 2.0 2.1 2.1.1 2.2 3.0/ ]
        , '... parsed correctly');
}

# using setInput to set an array of lines
{
    my $tp = Tree::Parser->new();
    isa_ok($tp, "Tree::Parser");
    
    $tp->setInput([ split /\n/ => $tree_string ]);
    
    $tp->useSpaceIndentedFilters(2);   
    
    my $tree = $tp->parse();

    isa_ok($tree, "Tree::Simple");
    
    my @accumulation;
    $tree->traverse(sub {
        my ($tree) = @_;
        push @accumulation, $tree->getNodeValue();
    });
    
    is_deeply(
        [ @accumulation ], 
        [ qw/1.0 1.1 1.2 1.3 2.0 2.1 2.1.1 2.2 3.0/ ]
        , '... parsed correctly');
}

# using new to set an Array::Iterator
{
    my $tp = Tree::Parser->new(Array::Iterator->new( split /\n/ => $tree_string ));
    isa_ok($tp, "Tree::Parser");
    
    $tp->useSpaceIndentedFilters(2);  
    
    my $tree = $tp->parse();

    isa_ok($tree, "Tree::Simple");
    
    my @accumulation;
    $tree->traverse(sub {
        my ($tree) = @_;
        push @accumulation, $tree->getNodeValue();
    });
    
    is_deeply(
        [ @accumulation ], 
        [ qw/1.0 1.1 1.2 1.3 2.0 2.1 2.1.1 2.2 3.0/ ]
        , '... parsed correctly');
}

# using new to set a file
{
    my $tp = Tree::Parser->new("t/sample.tree");
    isa_ok($tp, "Tree::Parser");
    
    $tp->useSpaceIndentedFilters(1);   
    
    my $tree = $tp->parse();

    isa_ok($tree, "Tree::Simple");
    
    my @accumulation;
    $tree->traverse(sub {
        my ($tree) = @_;
        push @accumulation, $tree->getNodeValue();
    });
    
    is_deeply(
        [ @accumulation ], 
        [ qw/1.0 1.1 1.1.1 1.1.2 1.2 1.2.1 1.2.2 2.0 2.1 2.2 3.0 3.1 3.1.1 3.2 3.3 3.3.1/ ]
        , '... parsed correctly');

}

{
    my $tp = Tree::Parser->new("t/sample_tree.txt");
    isa_ok($tp, "Tree::Parser");
    
    $tp->useSpaceIndentedFilters(1);   
    
    my $tree = $tp->parse();

    isa_ok($tree, "Tree::Simple");
    
    my @accumulation;
    $tree->traverse(sub {
        my ($tree) = @_;
        push @accumulation, $tree->getNodeValue();
    });
    
    is_deeply(
        [ @accumulation ], 
        [ qw/1.0 1.1 1.1.1 1.1.2 1.2 1.2.1 1.2.2 2.0 2.1 2.2 3.0 3.1 3.1.1 3.2 3.3 3.3.1/ ]
        , '... parsed correctly');

}

# using new to set a Path::Class object, if available
SKIP: {
    eval { require Path::Class };
    skip q(Install Path::Class to run this test), 3 if $@;

    my $tp = Tree::Parser->new(Path::Class::File->new('t/sample.tree'));
    isa_ok($tp, 'Tree::Parser');

    $tp->useSpaceIndentedFilters(1);
    my $tree = $tp->parse;
    isa_ok($tree, 'Tree::Simple');

    my @accumulation;
    $tree->traverse(sub {
        my ($tree) = @_;
        push @accumulation, $tree->getNodeValue();
    });
    
    is_deeply(
        [ @accumulation ], 
        [ qw/1.0 1.1 1.1.1 1.1.2 1.2 1.2.1 1.2.2 2.0 2.1 2.2 3.0 3.1 3.1.1 3.2 3.3 3.3.1/ ]
        , '... parsed correctly');
}
