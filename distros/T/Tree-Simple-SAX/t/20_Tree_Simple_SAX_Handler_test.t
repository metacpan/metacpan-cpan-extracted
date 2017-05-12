#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 13;

BEGIN {
    use_ok('Tree::Simple::SAX::Handler');
    use_ok('Tree::Simple');    
    use_ok('XML::SAX::ParserFactory');
}

{
    my $handler = Tree::Simple::SAX::Handler->new();
    isa_ok($handler, 'Tree::Simple::SAX::Handler');
    
    my $p = XML::SAX::ParserFactory->parser(Handler => $handler);
    $p->parse_string('<xml />');
    
    my $root = $handler->getRootTree();
    isa_ok($root, 'Tree::Simple');
    
    cmp_ok($root->getChildCount(), '==', 1, '... got the right number of children');
    
    my $xml_tree = $root->getChild(0);
    isa_ok($xml_tree, 'Tree::Simple');
    
    is_deeply(
        { tag_type => 'xml' },
        $xml_tree->getNodeValue(),
        '... got the right parsed tree');
}    

{
    my $xml_string = q|
    <root>
        <one>
            <one_one/>
            <one_two>
                <one_two_one/>
                <one_two_two>testing <one>1</one>, <two>2</two>, <three>3</three>, and here we go</one_two_two>
            </one_two>
        </one>
        <two/>
    </root>
    |;

    my $handler = Tree::Simple::SAX::Handler->new();
    isa_ok($handler, 'Tree::Simple::SAX::Handler');
    
    my $p = XML::SAX::ParserFactory->parser(Handler => $handler);
    $p->parse_string($xml_string);
    
    my $root = $handler->getRootTree();
    isa_ok($root, 'Tree::Simple');
    
    cmp_ok($root->getChildCount(), '==', 1, '... got the right number of children');
    
    my $xml_tree = $root->getChild(0);
    isa_ok($xml_tree, 'Tree::Simple');
    
    is_deeply(
        { tag_type => 'root' },
        $xml_tree->getNodeValue(),
        '... got the right parsed tree');
        
#     $root->traverse(sub {
#         my $t = shift;
#         my $node = $t->getNodeValue();
#         print(("\t" x $t->getDepth()) . "(" . (join ", " => map { "$_ => '" . $node->{$_} . "'" } keys %{$node}) . ")\n");
#     }); 

}   
       

