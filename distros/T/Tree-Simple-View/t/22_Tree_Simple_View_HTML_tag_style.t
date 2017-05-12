#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 32;
use Test::Exception;

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
    my $tree_view = Tree::Simple::View::HTML->new( $tree, (tag_style => 'nonesuch' ));
    throws_ok {
        $tree_view->expandAll();
    } "Tree::Simple::View::CompilationFailed", '... invalid tag_style';

}

{
    my $tree_view = Tree::Simple::View::HTML->new($tree, (list_type => "ordered", tag_style => 'xhtml'));
    isa_ok($tree_view, 'Tree::Simple::View::HTML');
    
    my $output = $tree_view->expandAll();
    ok($output, '... make sure we got some output');
    
    my $expected = <<EXPECTED;
<ol>
<li>1</li>
<ol>
<li>1.1</li>
<li>1.2</li>
<ol>
<li>1.2.1</li>
<li>1.2.2</li>
</ol>
<li>1.3</li>
</ol>
<li>2</li>
<ol>
<li>2.1</li>
<li>2.2</li>
</ol>
<li>3</li>
<ol>
<li>3.1</li>
<li>3.2</li>
<li>3.3</li>
</ol>
<li>4</li>
<ol>
<li>4.1</li>
</ol></ol>
EXPECTED
    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::HTML->new($tree, (list_type => "ordered", tag_style => 'xhtml'));
    isa_ok($tree_view, 'Tree::Simple::View::HTML');
    
    $tree_view->includeTrunk(1);
    
    my $output = $tree_view->expandAll();
    ok($output, '... make sure we got some output');
    
    my $expected = <<EXPECTED;
<ol>
<li>root</li>
<ol>
<li>1</li>
<ol>
<li>1.1</li>
<li>1.2</li>
<ol>
<li>1.2.1</li>
<li>1.2.2</li>
</ol>
<li>1.3</li>
</ol>
<li>2</li>
<ol>
<li>2.1</li>
<li>2.2</li>
</ol>
<li>3</li>
<ol>
<li>3.1</li>
<li>3.2</li>
<li>3.3</li>
</ol>
<li>4</li>
<ol>
<li>4.1</li>
</ol></ol></ol>
EXPECTED
    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::HTML->new($tree, (list_type => "ordered", tag_style => 'xhtml'));
    isa_ok($tree_view, 'Tree::Simple::View::HTML');
    
    my $output = $tree_view->expandPath(3);
    ok($output, '... make sure we got some output');
    
    my $expected = <<EXPECTED;
<ol>
<li>1</li>
<li>2</li>
<li>3</li>
<ol>
<li>3.1</li>
<li>3.2</li>
<li>3.3</li>
</ol>
<li>4</li>
</ol>
EXPECTED
    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::HTML->new($tree, (list_type => "ordered", tag_style =>'xhtml'));
    isa_ok($tree_view, 'Tree::Simple::View::HTML');
    
    $tree_view->includeTrunk(1);
    
    my $output = $tree_view->expandPath(qw(root 3));
    ok($output, '... make sure we got some output');
    
    my $expected = <<EXPECTED;
<ol>
<li>root</li>
<ol>
<li>1</li>
<li>2</li>
<li>3</li>
<ol>
<li>3.1</li>
<li>3.2</li>
<li>3.3</li>
</ol>
<li>4</li>
</ol>
</ol>
EXPECTED
    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::HTML->new($tree, 
                                tag_style => 'xhtml',
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
<ul style='list-style: circle;'>
<li style='font-weight: bold;'>1 Level</li>
<ul style='list-style: circle;'>
<li style='font-family: sans-serif;'>1.1 Level</li>
<li style='font-weight: bold;'>1.2 Level</li>
<ul style='list-style: circle;'>
<li style='font-family: sans-serif;'>1.2.1 Level</li>
<li style='font-family: sans-serif;'>1.2.2 Level</li>
</ul>
<li style='font-family: sans-serif;'>1.3 Level</li>
</ul>
<li style='font-weight: bold;'>2 Level</li>
<ul style='list-style: circle;'>
<li style='font-family: sans-serif;'>2.1 Level</li>
<li style='font-family: sans-serif;'>2.2 Level</li>
</ul>
<li style='font-weight: bold;'>3 Level</li>
<ul style='list-style: circle;'>
<li style='font-family: sans-serif;'>3.1 Level</li>
<li style='font-family: sans-serif;'>3.2 Level</li>
<li style='font-family: sans-serif;'>3.3 Level</li>
</ul>
<li style='font-weight: bold;'>4 Level</li>
<ul style='list-style: circle;'>
<li style='font-family: sans-serif;'>4.1 Level</li>
</ul></ul>
EXPECTED
    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::HTML->new($tree, 
                                tag_style => 'xhtml',
                                list_css => "list-style: circle",
                                list_item_css => "font-family: sans-serif;",
                                expanded_item_css => "font-weight: bold;",
                                node_formatter => sub { $_[0]->getNodeValue() . " Level" }                                
                                );
    isa_ok($tree_view, 'Tree::Simple::View::HTML');
    
    my $output = $tree_view->expandPath(2);
    ok($output, '... make sure we got some output');
    
    my $expected = <<EXPECTED;
<ul style='list-style: circle;'>
<li style='font-family: sans-serif;'>1 Level</li>
<li style='font-weight: bold;'>2 Level</li>
<ul style='list-style: circle;'>
<li style='font-family: sans-serif;'>2.1 Level</li>
<li style='font-family: sans-serif;'>2.2 Level</li>
</ul>
<li style='font-family: sans-serif;'>3 Level</li>
<li style='font-family: sans-serif;'>4 Level</li>
</ul>
EXPECTED
    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}


{
    my $tree_view = Tree::Simple::View::HTML->new($tree, 
                                tag_style => 'xhtml',
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
<ol class='listClass'>
<li class='expandedItemClass'>1 Level</li>
<ol class='listClass'>
<li class='listItemClass'>1.1 Level</li>
<li class='expandedItemClass'>1.2 Level</li>
<ol class='listClass'>
<li class='listItemClass'>1.2.1 Level</li>
<li class='listItemClass'>1.2.2 Level</li>
</ol>
<li class='listItemClass'>1.3 Level</li>
</ol>
<li class='expandedItemClass'>2 Level</li>
<ol class='listClass'>
<li class='listItemClass'>2.1 Level</li>
<li class='listItemClass'>2.2 Level</li>
</ol>
<li class='expandedItemClass'>3 Level</li>
<ol class='listClass'>
<li class='listItemClass'>3.1 Level</li>
<li class='listItemClass'>3.2 Level</li>
<li class='listItemClass'>3.3 Level</li>
</ol>
<li class='expandedItemClass'>4 Level</li>
<ol class='listClass'>
<li class='listItemClass'>4.1 Level</li>
</ol></ol>
EXPECTED
    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::HTML->new($tree, 
                                tag_style => 'xhtml',
                                list_css_class => "listClass",
                                list_item_css_class => "listItemClass",
                                expanded_item_css_class => "expandedItemClass",
                                node_formatter => sub { $_[0]->getNodeValue() . " Level" }                                
                                );
    isa_ok($tree_view, 'Tree::Simple::View::HTML');
    
    my $output = $tree_view->expandPath(2);
    ok($output, '... make sure we got some output');
    
    my $expected = <<EXPECTED;
<ul class='listClass'>
<li class='listItemClass'>1 Level</li>
<li class='expandedItemClass'>2 Level</li>
<ul class='listClass'>
<li class='listItemClass'>2.1 Level</li>
<li class='listItemClass'>2.2 Level</li>
</ul>
<li class='listItemClass'>3 Level</li>
<li class='listItemClass'>4 Level</li>
</ul>
EXPECTED
    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}

{
    my $tree_view = Tree::Simple::View::HTML->new($tree, 
                                tag_style => 'xhtml',
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
<ul class='listClass'>
<li class='listItemClass'>1 Level</li>
<li class='expandedItemClass'>2 Level</li>
<ul class='listClass'>
<li class='listItemClass'>2.1 Level</li>
<li class='listItemClass'>2.2 Level</li>
</ul>
<li class='listItemClass'>3 Level</li>
<li class='listItemClass'>4 Level</li>
</ul>
EXPECTED
    chomp $expected;
    
    is($output, $expected, '... got what we expected');
}
