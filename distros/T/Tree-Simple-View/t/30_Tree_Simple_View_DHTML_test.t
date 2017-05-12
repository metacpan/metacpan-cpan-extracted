#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 55;

BEGIN { 
    use_ok('Tree::Simple::View::DHTML');
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

can_ok("Tree::Simple::View::DHTML", 'new');
can_ok("Tree::Simple::View::DHTML", 'expandAll');


{
    my $tree_view = Tree::Simple::View::DHTML->new($tree);
    isa_ok($tree_view, 'Tree::Simple::View::DHTML');
    
    my $output = $tree_view->expandAll();
    ok($output, '... make sure we got some output');

    my ($view_id) = ($tree_view =~ /\((.*?)\)$/);
    my $expected = <<EXPECTED;
<UL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_1")'>1</A></LI>
<UL ID='${view_id}_1'>
<LI>1.1</LI>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_2")'>1.2</A></LI>
<UL ID='${view_id}_2'>
<LI>1.2.1</LI>
<LI>1.2.2</LI>
</UL>
<LI>1.3</LI>
</UL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_3")'>2</A></LI>
<UL ID='${view_id}_3'>
<LI>2.1</LI>
<LI>2.2</LI>
</UL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_4")'>3</A></LI>
<UL ID='${view_id}_4'>
<LI>3.1</LI>
<LI>3.2</LI>
<LI>3.3</LI>
</UL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_5")'>4</A></LI>
<UL ID='${view_id}_5'>
<LI>4.1</LI>
</UL></UL>
EXPECTED

    chomp $expected;
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::DHTML->new($tree);
    isa_ok($tree_view, 'Tree::Simple::View::DHTML');

    $tree_view->includeTrunk(1);
    
    my $output = $tree_view->expandAll();
    ok($output, '... make sure we got some output');

    my ($view_id) = ($tree_view =~ /\((.*?)\)$/);
    my $expected = <<EXPECTED;
<UL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_1")'>root</A></LI>
<UL ID='${view_id}_1'>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_2")'>1</A></LI>
<UL ID='${view_id}_2'>
<LI>1.1</LI>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_3")'>1.2</A></LI>
<UL ID='${view_id}_3'>
<LI>1.2.1</LI>
<LI>1.2.2</LI>
</UL>
<LI>1.3</LI>
</UL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_4")'>2</A></LI>
<UL ID='${view_id}_4'>
<LI>2.1</LI>
<LI>2.2</LI>
</UL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_5")'>3</A></LI>
<UL ID='${view_id}_5'>
<LI>3.1</LI>
<LI>3.2</LI>
<LI>3.3</LI>
</UL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_6")'>4</A></LI>
<UL ID='${view_id}_6'>
<LI>4.1</LI>
</UL></UL></UL>
EXPECTED

    chomp $expected;
    is($output, $expected, '... got what we expected');
}


{
    my $tree_view = Tree::Simple::View::DHTML->new($tree);
    isa_ok($tree_view, 'Tree::Simple::View::DHTML');
    
    my $output = $tree_view->expandPath(qw(1 1.2));
    ok($output, '... make sure we got some output');

    my ($view_id) = ($tree_view =~ /\((.*?)\)$/);
    my $expected = <<EXPECTED;
<UL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_1")'>1</A></LI>
<UL ID='${view_id}_1' STYLE='display: block;'>
<LI>1.1</LI>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_2")'>1.2</A></LI>
<UL ID='${view_id}_2' STYLE='display: block;'>
<LI>1.2.1</LI>
<LI>1.2.2</LI>
</UL>
<LI>1.3</LI>
</UL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_3")'>2</A></LI>
<UL ID='${view_id}_3' STYLE='display: none;'>
<LI>2.1</LI>
<LI>2.2</LI>
</UL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_4")'>3</A></LI>
<UL ID='${view_id}_4' STYLE='display: none;'>
<LI>3.1</LI>
<LI>3.2</LI>
<LI>3.3</LI>
</UL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_5")'>4</A></LI>
<UL ID='${view_id}_5' STYLE='display: none;'>
<LI>4.1</LI>
</UL></UL>
EXPECTED

    chomp $expected;
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::DHTML->new($tree);
    isa_ok($tree_view, 'Tree::Simple::View::DHTML');
    
    $tree_view->includeTrunk(1);
    
    my $output = $tree_view->expandPath(qw(root 1 1.2));
    ok($output, '... make sure we got some output');

    my ($view_id) = ($tree_view =~ /\((.*?)\)$/);
    my $expected = <<EXPECTED;
<UL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_1")'>root</A></LI>
<UL ID='${view_id}_1' STYLE='display: block;'>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_2")'>1</A></LI>
<UL ID='${view_id}_2' STYLE='display: block;'>
<LI>1.1</LI>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_3")'>1.2</A></LI>
<UL ID='${view_id}_3' STYLE='display: block;'>
<LI>1.2.1</LI>
<LI>1.2.2</LI>
</UL>
<LI>1.3</LI>
</UL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_4")'>2</A></LI>
<UL ID='${view_id}_4' STYLE='display: none;'>
<LI>2.1</LI>
<LI>2.2</LI>
</UL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_5")'>3</A></LI>
<UL ID='${view_id}_5' STYLE='display: none;'>
<LI>3.1</LI>
<LI>3.2</LI>
<LI>3.3</LI>
</UL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_6")'>4</A></LI>
<UL ID='${view_id}_6' STYLE='display: none;'>
<LI>4.1</LI>
</UL></UL></UL>
EXPECTED

    chomp $expected;
    is($output, $expected, '... got what we expected');
}


{
    my $tree_view = Tree::Simple::View::DHTML->new($tree);
    isa_ok($tree_view, 'Tree::Simple::View::DHTML');
    
    my $output = $tree_view->expandPath();
    ok($output, '... make sure we got some output');

    my ($view_id) = ($tree_view =~ /\((.*?)\)$/);
    my $expected = <<EXPECTED;
<UL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_1")'>1</A></LI>
<UL ID='${view_id}_1' STYLE='display: none;'>
<LI>1.1</LI>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_2")'>1.2</A></LI>
<UL ID='${view_id}_2' STYLE='display: none;'>
<LI>1.2.1</LI>
<LI>1.2.2</LI>
</UL>
<LI>1.3</LI>
</UL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_3")'>2</A></LI>
<UL ID='${view_id}_3' STYLE='display: none;'>
<LI>2.1</LI>
<LI>2.2</LI>
</UL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_4")'>3</A></LI>
<UL ID='${view_id}_4' STYLE='display: none;'>
<LI>3.1</LI>
<LI>3.2</LI>
<LI>3.3</LI>
</UL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_5")'>4</A></LI>
<UL ID='${view_id}_5' STYLE='display: none;'>
<LI>4.1</LI>
</UL></UL>
EXPECTED

    chomp $expected;
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::DHTML->new($tree, (list_type => "ordered"));
    isa_ok($tree_view, 'Tree::Simple::View::DHTML');
    
    my $output = $tree_view->expandAll();
    ok($output, '... make sure we got some output');
    
    my ($view_id) = ($tree_view =~ /\((.*?)\)$/);
    my $expected = <<EXPECTED;
<OL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_1")'>1</A></LI>
<OL ID='${view_id}_1'>
<LI>1.1</LI>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_2")'>1.2</A></LI>
<OL ID='${view_id}_2'>
<LI>1.2.1</LI>
<LI>1.2.2</LI>
</OL>
<LI>1.3</LI>
</OL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_3")'>2</A></LI>
<OL ID='${view_id}_3'>
<LI>2.1</LI>
<LI>2.2</LI>
</OL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_4")'>3</A></LI>
<OL ID='${view_id}_4'>
<LI>3.1</LI>
<LI>3.2</LI>
<LI>3.3</LI>
</OL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_5")'>4</A></LI>
<OL ID='${view_id}_5'>
<LI>4.1</LI>
</OL></OL>
EXPECTED

    chomp $expected;
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::DHTML->new($tree, (list_type => "ordered"));
    isa_ok($tree_view, 'Tree::Simple::View::DHTML');
    
    $tree_view->includeTrunk(1);
    
    my $output = $tree_view->expandAll();
    ok($output, '... make sure we got some output');
    
    my ($view_id) = ($tree_view =~ /\((.*?)\)$/);
    my $expected = <<EXPECTED;
<OL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_1")'>root</A></LI>
<OL ID='${view_id}_1'>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_2")'>1</A></LI>
<OL ID='${view_id}_2'>
<LI>1.1</LI>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_3")'>1.2</A></LI>
<OL ID='${view_id}_3'>
<LI>1.2.1</LI>
<LI>1.2.2</LI>
</OL>
<LI>1.3</LI>
</OL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_4")'>2</A></LI>
<OL ID='${view_id}_4'>
<LI>2.1</LI>
<LI>2.2</LI>
</OL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_5")'>3</A></LI>
<OL ID='${view_id}_5'>
<LI>3.1</LI>
<LI>3.2</LI>
<LI>3.3</LI>
</OL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_6")'>4</A></LI>
<OL ID='${view_id}_6'>
<LI>4.1</LI>
</OL></OL></OL>
EXPECTED

    chomp $expected;
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::DHTML->new($tree, (list_type => "ordered"));
    isa_ok($tree_view, 'Tree::Simple::View::DHTML');
    
    my $output = $tree_view->expandPath(2);
    ok($output, '... make sure we got some output');
    
    my ($view_id) = ($tree_view =~ /\((.*?)\)$/);
    my $expected = <<EXPECTED;
<OL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_1")'>1</A></LI>
<OL STYLE='display: none;' ID='${view_id}_1'>
<LI>1.1</LI>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_2")'>1.2</A></LI>
<OL STYLE='display: none;' ID='${view_id}_2'>
<LI>1.2.1</LI>
<LI>1.2.2</LI>
</OL>
<LI>1.3</LI>
</OL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_3")'>2</A></LI>
<OL STYLE='display: block;' ID='${view_id}_3'>
<LI>2.1</LI>
<LI>2.2</LI>
</OL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_4")'>3</A></LI>
<OL STYLE='display: none;' ID='${view_id}_4'>
<LI>3.1</LI>
<LI>3.2</LI>
<LI>3.3</LI>
</OL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_5")'>4</A></LI>
<OL STYLE='display: none;' ID='${view_id}_5'>
<LI>4.1</LI>
</OL></OL>
EXPECTED

    chomp $expected;
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::DHTML->new($tree, (list_type => "ordered"));
    isa_ok($tree_view, 'Tree::Simple::View::DHTML');
    
    $tree_view->includeTrunk(1);
    
    my $output = $tree_view->expandPath(qw(root 2));
    ok($output, '... make sure we got some output');
    
    my ($view_id) = ($tree_view =~ /\((.*?)\)$/);
    my $expected = <<EXPECTED;
<OL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_1")'>root</A></LI>
<OL STYLE='display: block;' ID='${view_id}_1'>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_2")'>1</A></LI>
<OL STYLE='display: none;' ID='${view_id}_2'>
<LI>1.1</LI>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_3")'>1.2</A></LI>
<OL STYLE='display: none;' ID='${view_id}_3'>
<LI>1.2.1</LI>
<LI>1.2.2</LI>
</OL>
<LI>1.3</LI>
</OL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_4")'>2</A></LI>
<OL STYLE='display: block;' ID='${view_id}_4'>
<LI>2.1</LI>
<LI>2.2</LI>
</OL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_5")'>3</A></LI>
<OL STYLE='display: none;' ID='${view_id}_5'>
<LI>3.1</LI>
<LI>3.2</LI>
<LI>3.3</LI>
</OL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_6")'>4</A></LI>
<OL STYLE='display: none;' ID='${view_id}_6'>
<LI>4.1</LI>
</OL></OL></OL>
EXPECTED

    chomp $expected;
    is($output, $expected, '... got what we expected');
}


{
    my $tree_view = Tree::Simple::View::DHTML->new($tree, 
                                list_css => "list-style: circle;",
                                list_item_css => "font-family: sans-serif;",
                                expanded_item_css => "font-weight: bold;",
                                link_css => "text-decoration: none;",
                                node_formatter => sub { $_[0]->getNodeValue() . " Level" } 
                                );
    isa_ok($tree_view, 'Tree::Simple::View::DHTML');
    
    my $output = $tree_view->expandAll();
    ok($output, '... make sure we got some output');
    
    my ($view_id) = ($tree_view =~ /\((.*?)\)$/);    
    my $expected = <<EXPECTED;
<UL STYLE='list-style: circle;'>
<LI STYLE='font-weight: bold;'><A STYLE='text-decoration: none;' HREF='javascript:void(0);' onClick='toggleList("${view_id}_1")'>1 Level</A></LI>
<UL STYLE='list-style: circle;' ID='${view_id}_1'>
<LI STYLE='font-family: sans-serif;'>1.1 Level</LI>
<LI STYLE='font-weight: bold;'><A STYLE='text-decoration: none;' HREF='javascript:void(0);' onClick='toggleList("${view_id}_2")'>1.2 Level</A></LI>
<UL STYLE='list-style: circle;' ID='${view_id}_2'>
<LI STYLE='font-family: sans-serif;'>1.2.1 Level</LI>
<LI STYLE='font-family: sans-serif;'>1.2.2 Level</LI>
</UL>
<LI STYLE='font-family: sans-serif;'>1.3 Level</LI>
</UL>
<LI STYLE='font-weight: bold;'><A STYLE='text-decoration: none;' HREF='javascript:void(0);' onClick='toggleList("${view_id}_3")'>2 Level</A></LI>
<UL STYLE='list-style: circle;' ID='${view_id}_3'>
<LI STYLE='font-family: sans-serif;'>2.1 Level</LI>
<LI STYLE='font-family: sans-serif;'>2.2 Level</LI>
</UL>
<LI STYLE='font-weight: bold;'><A STYLE='text-decoration: none;' HREF='javascript:void(0);' onClick='toggleList("${view_id}_4")'>3 Level</A></LI>
<UL STYLE='list-style: circle;' ID='${view_id}_4'>
<LI STYLE='font-family: sans-serif;'>3.1 Level</LI>
<LI STYLE='font-family: sans-serif;'>3.2 Level</LI>
<LI STYLE='font-family: sans-serif;'>3.3 Level</LI>
</UL>
<LI STYLE='font-weight: bold;'><A STYLE='text-decoration: none;' HREF='javascript:void(0);' onClick='toggleList("${view_id}_5")'>4 Level</A></LI>
<UL STYLE='list-style: circle;' ID='${view_id}_5'>
<LI STYLE='font-family: sans-serif;'>4.1 Level</LI>
</UL></UL>
EXPECTED

    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::DHTML->new($tree, 
                                list_css => "list-style: circle",
                                list_item_css => "font-family: sans-serif;",
                                expanded_item_css => "font-weight: bold;",
                                link_css => "text-decoration: none;",
                                node_formatter => sub { $_[0]->getNodeValue() . " Level" } 
                                );
    isa_ok($tree_view, 'Tree::Simple::View::DHTML');
    
    my $output = $tree_view->expandPath(qw(1 1.2));
    ok($output, '... make sure we got some output');
    
    my ($view_id) = ($tree_view =~ /\((.*?)\)$/);    
    my $expected = <<EXPECTED;
<UL STYLE='list-style: circle;'>
<LI STYLE='font-weight: bold;'><A STYLE='text-decoration: none;' HREF='javascript:void(0);' onClick='toggleList("${view_id}_1")'>1 Level</A></LI>
<UL STYLE='list-style: circle; display: block;' ID='${view_id}_1'>
<LI STYLE='font-family: sans-serif;'>1.1 Level</LI>
<LI STYLE='font-weight: bold;'><A STYLE='text-decoration: none;' HREF='javascript:void(0);' onClick='toggleList("${view_id}_2")'>1.2 Level</A></LI>
<UL STYLE='list-style: circle; display: block;' ID='${view_id}_2'>
<LI STYLE='font-family: sans-serif;'>1.2.1 Level</LI>
<LI STYLE='font-family: sans-serif;'>1.2.2 Level</LI>
</UL>
<LI STYLE='font-family: sans-serif;'>1.3 Level</LI>
</UL>
<LI STYLE='font-weight: bold;'><A STYLE='text-decoration: none;' HREF='javascript:void(0);' onClick='toggleList("${view_id}_3")'>2 Level</A></LI>
<UL STYLE='list-style: circle; display: none;' ID='${view_id}_3'>
<LI STYLE='font-family: sans-serif;'>2.1 Level</LI>
<LI STYLE='font-family: sans-serif;'>2.2 Level</LI>
</UL>
<LI STYLE='font-weight: bold;'><A STYLE='text-decoration: none;' HREF='javascript:void(0);' onClick='toggleList("${view_id}_4")'>3 Level</A></LI>
<UL STYLE='list-style: circle; display: none;' ID='${view_id}_4'>
<LI STYLE='font-family: sans-serif;'>3.1 Level</LI>
<LI STYLE='font-family: sans-serif;'>3.2 Level</LI>
<LI STYLE='font-family: sans-serif;'>3.3 Level</LI>
</UL>
<LI STYLE='font-weight: bold;'><A STYLE='text-decoration: none;' HREF='javascript:void(0);' onClick='toggleList("${view_id}_5")'>4 Level</A></LI>
<UL STYLE='list-style: circle; display: none;' ID='${view_id}_5'>
<LI STYLE='font-family: sans-serif;'>4.1 Level</LI>
</UL></UL>
EXPECTED

    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::DHTML->new($tree, 
                                list_css_class => "listClass",
                                list_item_css_class => "listItemClass",
                                expanded_item_css_class => "expandedItemClass",
                                link_css_class => "linkClass",
                                node_formatter => sub { $_[0]->getNodeValue() . " Level" } 
                                );
    isa_ok($tree_view, 'Tree::Simple::View::DHTML');
    
    my $output = $tree_view->expandAll();
    ok($output, '... make sure we got some output');
    
    my ($view_id) = ($tree_view =~ /\((.*?)\)$/);    
    my $expected = <<EXPECTED;
<UL CLASS='listClass'>
<LI CLASS='expandedItemClass'><A CLASS='linkClass' HREF='javascript:void(0);' onClick='toggleList("${view_id}_1")'>1 Level</A></LI>
<UL CLASS='listClass' ID='${view_id}_1'>
<LI CLASS='listItemClass'>1.1 Level</LI>
<LI CLASS='expandedItemClass'><A CLASS='linkClass' HREF='javascript:void(0);' onClick='toggleList("${view_id}_2")'>1.2 Level</A></LI>
<UL CLASS='listClass' ID='${view_id}_2'>
<LI CLASS='listItemClass'>1.2.1 Level</LI>
<LI CLASS='listItemClass'>1.2.2 Level</LI>
</UL>
<LI CLASS='listItemClass'>1.3 Level</LI>
</UL>
<LI CLASS='expandedItemClass'><A CLASS='linkClass' HREF='javascript:void(0);' onClick='toggleList("${view_id}_3")'>2 Level</A></LI>
<UL CLASS='listClass' ID='${view_id}_3'>
<LI CLASS='listItemClass'>2.1 Level</LI>
<LI CLASS='listItemClass'>2.2 Level</LI>
</UL>
<LI CLASS='expandedItemClass'><A CLASS='linkClass' HREF='javascript:void(0);' onClick='toggleList("${view_id}_4")'>3 Level</A></LI>
<UL CLASS='listClass' ID='${view_id}_4'>
<LI CLASS='listItemClass'>3.1 Level</LI>
<LI CLASS='listItemClass'>3.2 Level</LI>
<LI CLASS='listItemClass'>3.3 Level</LI>
</UL>
<LI CLASS='expandedItemClass'><A CLASS='linkClass' HREF='javascript:void(0);' onClick='toggleList("${view_id}_5")'>4 Level</A></LI>
<UL CLASS='listClass' ID='${view_id}_5'>
<LI CLASS='listItemClass'>4.1 Level</LI>
</UL></UL>
EXPECTED

    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::DHTML->new($tree, 
                                list_css_class => "listClass",
                                list_item_css_class => "listItemClass",
                                expanded_item_css_class => "expandedItemClass",
                                link_css_class => "linkClass",
                                node_formatter => sub { $_[0]->getNodeValue() . " Level" } 
                                );
    isa_ok($tree_view, 'Tree::Simple::View::DHTML');
    
    my $output = $tree_view->expandPath(qw(1 1.2));
    ok($output, '... make sure we got some output');
    
    my ($view_id) = ($tree_view =~ /\((.*?)\)$/);    
    my $expected = <<EXPECTED;
<UL CLASS='listClass'>
<LI CLASS='expandedItemClass'><A CLASS='linkClass' HREF='javascript:void(0);' onClick='toggleList("${view_id}_1")'>1 Level</A></LI>
<UL CLASS='listClass' STYLE='display: block;' ID='${view_id}_1'>
<LI CLASS='listItemClass'>1.1 Level</LI>
<LI CLASS='expandedItemClass'><A CLASS='linkClass' HREF='javascript:void(0);' onClick='toggleList("${view_id}_2")'>1.2 Level</A></LI>
<UL CLASS='listClass' STYLE='display: block;' ID='${view_id}_2'>
<LI CLASS='listItemClass'>1.2.1 Level</LI>
<LI CLASS='listItemClass'>1.2.2 Level</LI>
</UL>
<LI CLASS='listItemClass'>1.3 Level</LI>
</UL>
<LI CLASS='expandedItemClass'><A CLASS='linkClass' HREF='javascript:void(0);' onClick='toggleList("${view_id}_3")'>2 Level</A></LI>
<UL CLASS='listClass' STYLE='display: none;' ID='${view_id}_3'>
<LI CLASS='listItemClass'>2.1 Level</LI>
<LI CLASS='listItemClass'>2.2 Level</LI>
</UL>
<LI CLASS='expandedItemClass'><A CLASS='linkClass' HREF='javascript:void(0);' onClick='toggleList("${view_id}_4")'>3 Level</A></LI>
<UL CLASS='listClass' STYLE='display: none;' ID='${view_id}_4'>
<LI CLASS='listItemClass'>3.1 Level</LI>
<LI CLASS='listItemClass'>3.2 Level</LI>
<LI CLASS='listItemClass'>3.3 Level</LI>
</UL>
<LI CLASS='expandedItemClass'><A CLASS='linkClass' HREF='javascript:void(0);' onClick='toggleList("${view_id}_5")'>4 Level</A></LI>
<UL CLASS='listClass' STYLE='display: none;' ID='${view_id}_5'>
<LI CLASS='listItemClass'>4.1 Level</LI>
</UL></UL>
EXPECTED

    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}


{

    my $tree = Tree::Simple->new(Tree::Simple->ROOT)
                       ->addChildren(
                            Tree::Simple->new("1")->addChild(Tree::Simple->new("1.1")),
                            Tree::Simple->new("2")
                       );
                       
    my $tree_id = $tree->getChild(0)->getUID();

    my $tree_view = Tree::Simple::View::DHTML->new($tree, (use_tree_uids => 1));
    isa_ok($tree_view, 'Tree::Simple::View::DHTML');
    
    my $output = $tree_view->expandAll();
    ok($output, '... make sure we got some output');

    my ($view_id) = ($tree_view =~ /\((.*?)\)$/);
    my $expected = <<EXPECTED;
<UL>
<LI><A HREF='javascript:void(0);' onClick='toggleList("$tree_id")'>1</A></LI>
<UL ID='$tree_id'>
<LI>1.1</LI>
</UL>
<LI>2</LI>
</UL>
EXPECTED

    chomp $expected;
    is($output, $expected, '... got what we expected');
                       
}

{
    my $tree_view = Tree::Simple::View::DHTML->new($tree, 
                                list_css_class => "listClass",
                                list_item_css_class => "listItemClass",
                                expanded_item_css_class => "expandedItemClass",
                                link_css_class => "linkClass",
                                node_formatter => sub { $_[0]->getNodeValue() . " Level" } 
                                );
    isa_ok($tree_view, 'Tree::Simple::View::DHTML');
    
    # test that perls string-to-number conversion will
    # cause the values below to become the correct numbers 
    $tree_view->setPathComparisonFunction(sub { $_[0] == $_[1]->getNodeValue() });    
    
    my $output = $tree_view->expandPath(qw(0001 0001.2));
    ok($output, '... make sure we got some output');
    
    my ($view_id) = ($tree_view =~ /\((.*?)\)$/);    
    my $expected = <<EXPECTED;
<UL CLASS='listClass'>
<LI CLASS='expandedItemClass'><A CLASS='linkClass' HREF='javascript:void(0);' onClick='toggleList("${view_id}_1")'>1 Level</A></LI>
<UL CLASS='listClass' STYLE='display: block;' ID='${view_id}_1'>
<LI CLASS='listItemClass'>1.1 Level</LI>
<LI CLASS='expandedItemClass'><A CLASS='linkClass' HREF='javascript:void(0);' onClick='toggleList("${view_id}_2")'>1.2 Level</A></LI>
<UL CLASS='listClass' STYLE='display: block;' ID='${view_id}_2'>
<LI CLASS='listItemClass'>1.2.1 Level</LI>
<LI CLASS='listItemClass'>1.2.2 Level</LI>
</UL>
<LI CLASS='listItemClass'>1.3 Level</LI>
</UL>
<LI CLASS='expandedItemClass'><A CLASS='linkClass' HREF='javascript:void(0);' onClick='toggleList("${view_id}_3")'>2 Level</A></LI>
<UL CLASS='listClass' STYLE='display: none;' ID='${view_id}_3'>
<LI CLASS='listItemClass'>2.1 Level</LI>
<LI CLASS='listItemClass'>2.2 Level</LI>
</UL>
<LI CLASS='expandedItemClass'><A CLASS='linkClass' HREF='javascript:void(0);' onClick='toggleList("${view_id}_4")'>3 Level</A></LI>
<UL CLASS='listClass' STYLE='display: none;' ID='${view_id}_4'>
<LI CLASS='listItemClass'>3.1 Level</LI>
<LI CLASS='listItemClass'>3.2 Level</LI>
<LI CLASS='listItemClass'>3.3 Level</LI>
</UL>
<LI CLASS='expandedItemClass'><A CLASS='linkClass' HREF='javascript:void(0);' onClick='toggleList("${view_id}_5")'>4 Level</A></LI>
<UL CLASS='listClass' STYLE='display: none;' ID='${view_id}_5'>
<LI CLASS='listItemClass'>4.1 Level</LI>
</UL></UL>
EXPECTED

    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}

# I need to do this so it's easier to test 
# the new radio and check button formatters
my $UIDS = 1;
$tree->traverse(sub { $_[0]->setUID($UIDS++) }); 

{     
    my $tree_view = Tree::Simple::View::DHTML->new($tree,
                                        radio_button => 'tree_radio_button'
                                        );
    isa_ok($tree_view, 'Tree::Simple::View::DHTML');
    
    my $output = $tree_view->expandAll();
    ok($output, '... make sure we got some output');

    my ($view_id) = ($tree_view =~ /\((.*?)\)$/);
    my $expected = <<EXPECTED;
<UL>
<LI><INPUT TYPE='radio' NAME='tree_radio_button' VALUE='1'><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_1")'>1</A></LI>
<UL ID='${view_id}_1'>
<LI><INPUT TYPE='radio' NAME='tree_radio_button' VALUE='2'>1.1</LI>
<LI><INPUT TYPE='radio' NAME='tree_radio_button' VALUE='3'><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_2")'>1.2</A></LI>
<UL ID='${view_id}_2'>
<LI><INPUT TYPE='radio' NAME='tree_radio_button' VALUE='4'>1.2.1</LI>
<LI><INPUT TYPE='radio' NAME='tree_radio_button' VALUE='5'>1.2.2</LI>
</UL>
<LI><INPUT TYPE='radio' NAME='tree_radio_button' VALUE='6'>1.3</LI>
</UL>
<LI><INPUT TYPE='radio' NAME='tree_radio_button' VALUE='7'><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_3")'>2</A></LI>
<UL ID='${view_id}_3'>
<LI><INPUT TYPE='radio' NAME='tree_radio_button' VALUE='8'>2.1</LI>
<LI><INPUT TYPE='radio' NAME='tree_radio_button' VALUE='9'>2.2</LI>
</UL>
<LI><INPUT TYPE='radio' NAME='tree_radio_button' VALUE='10'><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_4")'>3</A></LI>
<UL ID='${view_id}_4'>
<LI><INPUT TYPE='radio' NAME='tree_radio_button' VALUE='11'>3.1</LI>
<LI><INPUT TYPE='radio' NAME='tree_radio_button' VALUE='12'>3.2</LI>
<LI><INPUT TYPE='radio' NAME='tree_radio_button' VALUE='13'>3.3</LI>
</UL>
<LI><INPUT TYPE='radio' NAME='tree_radio_button' VALUE='14'><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_5")'>4</A></LI>
<UL ID='${view_id}_5'>
<LI><INPUT TYPE='radio' NAME='tree_radio_button' VALUE='15'>4.1</LI>
</UL></UL>
EXPECTED

    chomp $expected;
    is($output, $expected, '... got what we expected');
}

{     
    my $tree_view = Tree::Simple::View::DHTML->new($tree,
                                        checkbox => 'tree_check_button'
                                        );
    isa_ok($tree_view, 'Tree::Simple::View::DHTML');
    
    my $output = $tree_view->expandAll();
    ok($output, '... make sure we got some output');

    my ($view_id) = ($tree_view =~ /\((.*?)\)$/);
    my $expected = <<EXPECTED;
<UL>
<LI><INPUT TYPE='checkbox' NAME='tree_check_button' VALUE='1'><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_1")'>1</A></LI>
<UL ID='${view_id}_1'>
<LI><INPUT TYPE='checkbox' NAME='tree_check_button' VALUE='2'>1.1</LI>
<LI><INPUT TYPE='checkbox' NAME='tree_check_button' VALUE='3'><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_2")'>1.2</A></LI>
<UL ID='${view_id}_2'>
<LI><INPUT TYPE='checkbox' NAME='tree_check_button' VALUE='4'>1.2.1</LI>
<LI><INPUT TYPE='checkbox' NAME='tree_check_button' VALUE='5'>1.2.2</LI>
</UL>
<LI><INPUT TYPE='checkbox' NAME='tree_check_button' VALUE='6'>1.3</LI>
</UL>
<LI><INPUT TYPE='checkbox' NAME='tree_check_button' VALUE='7'><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_3")'>2</A></LI>
<UL ID='${view_id}_3'>
<LI><INPUT TYPE='checkbox' NAME='tree_check_button' VALUE='8'>2.1</LI>
<LI><INPUT TYPE='checkbox' NAME='tree_check_button' VALUE='9'>2.2</LI>
</UL>
<LI><INPUT TYPE='checkbox' NAME='tree_check_button' VALUE='10'><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_4")'>3</A></LI>
<UL ID='${view_id}_4'>
<LI><INPUT TYPE='checkbox' NAME='tree_check_button' VALUE='11'>3.1</LI>
<LI><INPUT TYPE='checkbox' NAME='tree_check_button' VALUE='12'>3.2</LI>
<LI><INPUT TYPE='checkbox' NAME='tree_check_button' VALUE='13'>3.3</LI>
</UL>
<LI><INPUT TYPE='checkbox' NAME='tree_check_button' VALUE='14'><A HREF='javascript:void(0);' onClick='toggleList("${view_id}_5")'>4</A></LI>
<UL ID='${view_id}_5'>
<LI><INPUT TYPE='checkbox' NAME='tree_check_button' VALUE='15'>4.1</LI>
</UL></UL>
EXPECTED

    chomp $expected;
    is($output, $expected, '... got what we expected');
}

