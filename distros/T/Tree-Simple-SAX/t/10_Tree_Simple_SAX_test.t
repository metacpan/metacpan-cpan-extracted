#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

BEGIN { 
    use_ok('Tree::Simple::SAX');
    use_ok('Tree::Simple::SAX::Handler'); 
    use_ok('XML::SAX::ParserFactory');       
}

# check the example in SYNOPSIS
my $output;
eval {  
    my $handler = Tree::Simple::SAX::Handler->new(Tree::Simple->new());
    my $p = XML::SAX::ParserFactory->parser(Handler => $handler);
    $p->parse_string('<xml><string>Hello <world/>!</string></xml>');   
    my $root = $handler->getRootTree();
    
    $root->traverse(sub {
        my $t = shift;
        my $node = $t->getNodeValue();
        $output .= (("    " x $t->getDepth()) . "(" . (join ", " => map { "$_ => '" . $node->{$_} . "'" } sort keys %{$node}) . ")\n");
    });   
};
is($output, 
q{(tag_type => 'xml')
    (tag_type => 'string')
        (content => 'Hello ', tag_type => 'CDATA')
        (tag_type => 'world')
        (content => '!', tag_type => 'CDATA')
}, 
'... got the right string');