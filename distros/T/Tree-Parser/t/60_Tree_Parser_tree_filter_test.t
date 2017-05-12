#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

BEGIN { 
    use_ok('Tree::Parser') 
}

my $tree_string = <<TREE_STRING;
a 1.0
b 	1.1
c 	1.2
d 		1.2.1
e 2.0
f 	2.1
g 3.0
h 	3.1
i 		3.1.1
TREE_STRING

chomp $tree_string;
	
can_ok("Tree::Parser", 'new');    
    
{    
    my $tp = Tree::Parser->new($tree_string);
    isa_ok($tp, "Tree::Parser");
    
    $tp->setParseFilter(sub {
            my ($line_iterator) = @_;
            my $line = $line_iterator->next();
            my ($UID, $tabs, $node) = $line =~ /(.)\s(\t*)(.*)/;
            my $depth = length $tabs;
            my $tree = Tree::Simple->new($node);
            $tree->setUID($UID);
            return ($depth, $tree);
        });
    
    my $tree = $tp->parse();
    isa_ok($tree, "Tree::Simple");
    
    my @accumulation;
    $tree->traverse(sub {
        my ($tree) = @_;
        push @accumulation, [ $tree->getUID(), $tree->getNodeValue() ];
    });
    
    is_deeply(
            [ @accumulation ], 
            [ ['a', '1.0'],   ['b', '1.1'], ['c', '1.2'],
              ['d', '1.2.1'], ['e', '2.0'], ['f', '2.1'],
              ['g', '3.0'],   ['h', '3.1'], ['i', '3.1.1'] ], 
            '... parse test failed');
}


