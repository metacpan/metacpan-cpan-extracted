#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 46;

BEGIN { 
    use_ok('Tree::Simple::View::HTML');
}

use Tree::Simple;
my $tree = Tree::Simple->new(Tree::Simple->ROOT)
                       ->addChildren(
                            Tree::Simple->new("1")
                                        ->addChildren(
                                            Tree::Simple->new("1.1"),
                                            Tree::Simple->new("1.2")
                                                        ->addChildren(
                                                            Tree::Simple->new("1.2.1"),
                                                            Tree::Simple->new("1.2.2")
                                                        ),
                                            Tree::Simple->new("1.3")                                                                                                
                                        ),
                            Tree::Simple->new("2")
                                        ->addChildren(
                                            Tree::Simple->new("2.1"),
                                            Tree::Simple->new("2.2")
                                        ),                            
                            Tree::Simple->new("3")
                                        ->addChildren(
                                            Tree::Simple->new("3.1"),
                                            Tree::Simple->new("3.2"),
                                            Tree::Simple->new("3.3")                                                                                                
                                        ),                            
                            Tree::Simple->new("4")                                                        
                                        ->addChildren(
                                            Tree::Simple->new("4.1")
                                        )                            
                       );
isa_ok($tree, 'Tree::Simple');

can_ok("Tree::Simple::View::HTML", 'new');
can_ok("Tree::Simple::View::HTML", 'expandAll');

{
    my $tree_view = Tree::Simple::View::HTML->new($tree);
    isa_ok($tree_view, 'Tree::Simple::View::HTML');
    
    my $output = $tree_view->expandAll();
    ok($output, '... make sure we got some output');
    
    my $expected = <<EXPECTED;
<UL>
<LI>1</LI>
<UL>
<LI>1.1</LI>
<LI>1.2</LI>
<UL>
<LI>1.2.1</LI>
<LI>1.2.2</LI>
</UL>
<LI>1.3</LI>
</UL>
<LI>2</LI>
<UL>
<LI>2.1</LI>
<LI>2.2</LI>
</UL>
<LI>3</LI>
<UL>
<LI>3.1</LI>
<LI>3.2</LI>
<LI>3.3</LI>
</UL>
<LI>4</LI>
<UL>
<LI>4.1</LI>
</UL></UL>
EXPECTED
    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::HTML->new($tree);
    isa_ok($tree_view, 'Tree::Simple::View::HTML');

    $tree_view->includeTrunk(1);
    
    my $output = $tree_view->expandAll();
    ok($output, '... make sure we got some output');
    
    my $expected = <<EXPECTED;
<UL>
<LI>root</LI>
<UL>
<LI>1</LI>
<UL>
<LI>1.1</LI>
<LI>1.2</LI>
<UL>
<LI>1.2.1</LI>
<LI>1.2.2</LI>
</UL>
<LI>1.3</LI>
</UL>
<LI>2</LI>
<UL>
<LI>2.1</LI>
<LI>2.2</LI>
</UL>
<LI>3</LI>
<UL>
<LI>3.1</LI>
<LI>3.2</LI>
<LI>3.3</LI>
</UL>
<LI>4</LI>
<UL>
<LI>4.1</LI>
</UL></UL></UL>
EXPECTED
    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::HTML->new($tree);
    isa_ok($tree_view, 'Tree::Simple::View::HTML');
    
    my $output = $tree_view->expandPath(qw(1 1.2));
    ok($output, '... make sure we got some output');
    
    my $expected = <<EXPECTED;
<UL>
<LI>1</LI>
<UL>
<LI>1.1</LI>
<LI>1.2</LI>
<UL>
<LI>1.2.1</LI>
<LI>1.2.2</LI>
</UL>
<LI>1.3</LI>
</UL>
<LI>2</LI>
<LI>3</LI>
<LI>4</LI>
</UL>
EXPECTED
    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::HTML->new($tree);
    isa_ok($tree_view, 'Tree::Simple::View::HTML');
    
    $tree_view->includeTrunk(1);
    
    my $output = $tree_view->expandPath(qw(root 1 1.2));
    ok($output, '... make sure we got some output');
    
    my $expected = <<EXPECTED;
<UL>
<LI>root</LI>
<UL>
<LI>1</LI>
<UL>
<LI>1.1</LI>
<LI>1.2</LI>
<UL>
<LI>1.2.1</LI>
<LI>1.2.2</LI>
</UL>
<LI>1.3</LI>
</UL>
<LI>2</LI>
<LI>3</LI>
<LI>4</LI>
</UL>
</UL>
EXPECTED
    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::HTML->new($tree);
    isa_ok($tree_view, 'Tree::Simple::View::HTML');
    
    my $output = $tree_view->expandPath();
    ok($output, '... make sure we got some output');
    
    my $expected = <<EXPECTED;
<UL>
<LI>1</LI>
<LI>2</LI>
<LI>3</LI>
<LI>4</LI>
</UL>
EXPECTED
    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}


{
    my $tree_view = Tree::Simple::View::HTML->new($tree, (list_type => "ordered"));
    isa_ok($tree_view, 'Tree::Simple::View::HTML');
    
    my $output = $tree_view->expandAll();
    ok($output, '... make sure we got some output');
    
    my $expected = <<EXPECTED;
<OL>
<LI>1</LI>
<OL>
<LI>1.1</LI>
<LI>1.2</LI>
<OL>
<LI>1.2.1</LI>
<LI>1.2.2</LI>
</OL>
<LI>1.3</LI>
</OL>
<LI>2</LI>
<OL>
<LI>2.1</LI>
<LI>2.2</LI>
</OL>
<LI>3</LI>
<OL>
<LI>3.1</LI>
<LI>3.2</LI>
<LI>3.3</LI>
</OL>
<LI>4</LI>
<OL>
<LI>4.1</LI>
</OL></OL>
EXPECTED
    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::HTML->new($tree, (list_type => "ordered"));
    isa_ok($tree_view, 'Tree::Simple::View::HTML');
    
    $tree_view->includeTrunk(1);
    
    my $output = $tree_view->expandAll();
    ok($output, '... make sure we got some output');
    
    my $expected = <<EXPECTED;
<OL>
<LI>root</LI>
<OL>
<LI>1</LI>
<OL>
<LI>1.1</LI>
<LI>1.2</LI>
<OL>
<LI>1.2.1</LI>
<LI>1.2.2</LI>
</OL>
<LI>1.3</LI>
</OL>
<LI>2</LI>
<OL>
<LI>2.1</LI>
<LI>2.2</LI>
</OL>
<LI>3</LI>
<OL>
<LI>3.1</LI>
<LI>3.2</LI>
<LI>3.3</LI>
</OL>
<LI>4</LI>
<OL>
<LI>4.1</LI>
</OL></OL></OL>
EXPECTED
    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::HTML->new($tree, (list_type => "ordered"));
    isa_ok($tree_view, 'Tree::Simple::View::HTML');
    
    my $output = $tree_view->expandPath(3);
    ok($output, '... make sure we got some output');
    
    my $expected = <<EXPECTED;
<OL>
<LI>1</LI>
<LI>2</LI>
<LI>3</LI>
<OL>
<LI>3.1</LI>
<LI>3.2</LI>
<LI>3.3</LI>
</OL>
<LI>4</LI>
</OL>
EXPECTED
    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::HTML->new($tree, (list_type => "ordered"));
    isa_ok($tree_view, 'Tree::Simple::View::HTML');
    
    $tree_view->includeTrunk(1);
    
    my $output = $tree_view->expandPath(qw(root 3));
    ok($output, '... make sure we got some output');
    
    my $expected = <<EXPECTED;
<OL>
<LI>root</LI>
<OL>
<LI>1</LI>
<LI>2</LI>
<LI>3</LI>
<OL>
<LI>3.1</LI>
<LI>3.2</LI>
<LI>3.3</LI>
</OL>
<LI>4</LI>
</OL>
</OL>
EXPECTED
    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::HTML->new($tree, 
                                list_type => "unordered",
                                list_css => "list-style: circle;",
                                list_item_css => "font-family: sans-serif;",
                                expanded_item_css => "font-weight: bold;",
                                node_formatter => sub { $_[0]->getNodeValue() . " Level" }                                 
                                );
    isa_ok($tree_view, 'Tree::Simple::View::HTML');
    
    my $output = $tree_view->expandAll();
    ok($output, '... make sure we got some output');
    
    my $expected = <<EXPECTED;
<UL STYLE='list-style: circle;'>
<LI STYLE='font-weight: bold;'>1 Level</LI>
<UL STYLE='list-style: circle;'>
<LI STYLE='font-family: sans-serif;'>1.1 Level</LI>
<LI STYLE='font-weight: bold;'>1.2 Level</LI>
<UL STYLE='list-style: circle;'>
<LI STYLE='font-family: sans-serif;'>1.2.1 Level</LI>
<LI STYLE='font-family: sans-serif;'>1.2.2 Level</LI>
</UL>
<LI STYLE='font-family: sans-serif;'>1.3 Level</LI>
</UL>
<LI STYLE='font-weight: bold;'>2 Level</LI>
<UL STYLE='list-style: circle;'>
<LI STYLE='font-family: sans-serif;'>2.1 Level</LI>
<LI STYLE='font-family: sans-serif;'>2.2 Level</LI>
</UL>
<LI STYLE='font-weight: bold;'>3 Level</LI>
<UL STYLE='list-style: circle;'>
<LI STYLE='font-family: sans-serif;'>3.1 Level</LI>
<LI STYLE='font-family: sans-serif;'>3.2 Level</LI>
<LI STYLE='font-family: sans-serif;'>3.3 Level</LI>
</UL>
<LI STYLE='font-weight: bold;'>4 Level</LI>
<UL STYLE='list-style: circle;'>
<LI STYLE='font-family: sans-serif;'>4.1 Level</LI>
</UL></UL>
EXPECTED
    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::HTML->new($tree, 
                                list_css => "list-style: circle",
                                list_item_css => "font-family: sans-serif;",
                                expanded_item_css => "font-weight: bold;",
                                node_formatter => sub { $_[0]->getNodeValue() . " Level" }                                
                                );
    isa_ok($tree_view, 'Tree::Simple::View::HTML');
    
    my $output = $tree_view->expandPath(2);
    ok($output, '... make sure we got some output');
    
    my $expected = <<EXPECTED;
<UL STYLE='list-style: circle;'>
<LI STYLE='font-family: sans-serif;'>1 Level</LI>
<LI STYLE='font-weight: bold;'>2 Level</LI>
<UL STYLE='list-style: circle;'>
<LI STYLE='font-family: sans-serif;'>2.1 Level</LI>
<LI STYLE='font-family: sans-serif;'>2.2 Level</LI>
</UL>
<LI STYLE='font-family: sans-serif;'>3 Level</LI>
<LI STYLE='font-family: sans-serif;'>4 Level</LI>
</UL>
EXPECTED
    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}


{
    my $tree_view = Tree::Simple::View::HTML->new($tree, 
                                list_type => "ordered",
                                list_css_class => "listClass",
                                list_item_css_class => "listItemClass",
                                expanded_item_css_class => "expandedItemClass",
                                node_formatter => sub { $_[0]->getNodeValue() . " Level" }                                 
                                );
    isa_ok($tree_view, 'Tree::Simple::View::HTML');
    
    my $output = $tree_view->expandAll();
    ok($output, '... make sure we got some output');
    
    my $expected = <<EXPECTED;
<OL CLASS='listClass'>
<LI CLASS='expandedItemClass'>1 Level</LI>
<OL CLASS='listClass'>
<LI CLASS='listItemClass'>1.1 Level</LI>
<LI CLASS='expandedItemClass'>1.2 Level</LI>
<OL CLASS='listClass'>
<LI CLASS='listItemClass'>1.2.1 Level</LI>
<LI CLASS='listItemClass'>1.2.2 Level</LI>
</OL>
<LI CLASS='listItemClass'>1.3 Level</LI>
</OL>
<LI CLASS='expandedItemClass'>2 Level</LI>
<OL CLASS='listClass'>
<LI CLASS='listItemClass'>2.1 Level</LI>
<LI CLASS='listItemClass'>2.2 Level</LI>
</OL>
<LI CLASS='expandedItemClass'>3 Level</LI>
<OL CLASS='listClass'>
<LI CLASS='listItemClass'>3.1 Level</LI>
<LI CLASS='listItemClass'>3.2 Level</LI>
<LI CLASS='listItemClass'>3.3 Level</LI>
</OL>
<LI CLASS='expandedItemClass'>4 Level</LI>
<OL CLASS='listClass'>
<LI CLASS='listItemClass'>4.1 Level</LI>
</OL></OL>
EXPECTED
    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::HTML->new($tree, 
                                list_css_class => "listClass",
                                list_item_css_class => "listItemClass",
                                expanded_item_css_class => "expandedItemClass",
                                node_formatter => sub { $_[0]->getNodeValue() . " Level" }                                
                                );
    isa_ok($tree_view, 'Tree::Simple::View::HTML');
    
    my $output = $tree_view->expandPath(2);
    ok($output, '... make sure we got some output');
    
    my $expected = <<EXPECTED;
<UL CLASS='listClass'>
<LI CLASS='listItemClass'>1 Level</LI>
<LI CLASS='expandedItemClass'>2 Level</LI>
<UL CLASS='listClass'>
<LI CLASS='listItemClass'>2.1 Level</LI>
<LI CLASS='listItemClass'>2.2 Level</LI>
</UL>
<LI CLASS='listItemClass'>3 Level</LI>
<LI CLASS='listItemClass'>4 Level</LI>
</UL>
EXPECTED
    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::HTML->new($tree, 
                                list_css_class => "listClass",
                                list_item_css_class => "listItemClass",
                                expanded_item_css_class => "expandedItemClass",
                                node_formatter => sub { $_[0]->getNodeValue() . " Level" }                                
                                );
    isa_ok($tree_view, 'Tree::Simple::View::HTML');
    
    # test that perls string-to-number conversion will
    # cause the '0002' below to become the number 2
    $tree_view->setPathComparisonFunction(sub { $_[0] == $_[1]->getNodeValue() });
    
    my $output = $tree_view->expandPath("0002");
    ok($output, '... make sure we got some output');
    
    my $expected = <<EXPECTED;
<UL CLASS='listClass'>
<LI CLASS='listItemClass'>1 Level</LI>
<LI CLASS='expandedItemClass'>2 Level</LI>
<UL CLASS='listClass'>
<LI CLASS='listItemClass'>2.1 Level</LI>
<LI CLASS='listItemClass'>2.2 Level</LI>
</UL>
<LI CLASS='listItemClass'>3 Level</LI>
<LI CLASS='listItemClass'>4 Level</LI>
</UL>
EXPECTED
    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}

