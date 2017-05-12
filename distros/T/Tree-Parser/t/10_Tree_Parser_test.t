#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;

BEGIN { 
    use_ok('Tree::Parser') 
}

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
	
can_ok("Tree::Parser", 'new');    
    
my $tp = Tree::Parser->new($tree_string);

isa_ok($tp, "Tree::Parser");

can_ok($tp, 'setParseFilter');
can_ok($tp, 'setDeparseFilter');

can_ok($tp, 'parse');
can_ok($tp, 'deparse');

$tp->setParseFilter(sub {
        my ($line_iterator) = @_;
        my $line = $line_iterator->next();
        my ($tabs, $node) = $line =~ /(\t*)(.*)/;
        my $depth = length $tabs;
        return ($depth, $node);
    });
    
$tp->setDeparseFilter(sub ($) { 
        my ($tree) = @_;
        return ("\t" x $tree->getDepth()) . $tree->getNodeValue();
    });

my $tree = $tp->parse();

isa_ok($tree, "Tree::Simple");

my @accumulation;
$tree->traverse(sub {
    my ($tree) = @_;
    push @accumulation, $tree->getNodeValue();
});

ok(eq_array(
        [ @accumulation ], 
        [ qw/1.0 1.1 1.2 1.2.1 2.0 2.1 3.0 3.1 3.1.1/ ]
    ), '... parse test failed');

my $deparsed_string = $tp->deparse();

is($deparsed_string, $tree_string, '... deparse did not work');




