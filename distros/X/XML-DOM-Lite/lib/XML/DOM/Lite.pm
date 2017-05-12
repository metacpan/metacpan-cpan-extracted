package XML::DOM::Lite;

our $VERSION = '0.15';
use warnings;
use strict;

use XML::DOM::Lite::Constants qw(:all);
use XML::DOM::Lite::Parser;
use XML::DOM::Lite::Document;
use XML::DOM::Lite::Node;
use XML::DOM::Lite::NodeList;
use XML::DOM::Lite::NodeIterator;
use XML::DOM::Lite::Serializer;
use XML::DOM::Lite::XPath;
use XML::DOM::Lite::XSLT;

require Exporter;
our @ISA = qw(Exporter);

use constant Parser       => 'XML::DOM::Lite::Parser';
use constant Document     => 'XML::DOM::Lite::Document';
use constant Node         => 'XML::DOM::Lite::Node';
use constant NodeList     => 'XML::DOM::Lite::NodeList';
use constant NodeIterator => 'XML::DOM::Lite::NodeIterator';
use constant Serializer   => 'XML::DOM::Lite::Serializer';
use constant XPath        => 'XML::DOM::Lite::XPath';
use constant XSLT         => 'XML::DOM::Lite::XSLT';

our @EXPORT_OK = (
    @XML::DOM::Lite::Constants::EXPORT_OK,
    qw(Parser Document Node NodeList NodeIterator NodeFilter Serializer XPath XSLT)
);

our %EXPORT_TAGS = ( constants => \@XML::DOM::Lite::Constants::EXPORT_OK );

1;
__END__

=head1 NAME

XML::DOM::Lite - Lite Pure Perl XML DOM Parser Kit 

=head1 SYNOPSIS

 # Parser
 use XML::DOM::Lite qw(Parser :constants);
  
 $parser = Parser->new( %options );
 $doc = Parser->parse($xmlstr);
 $doc = Parser->parseFile('/path/to/file.xml');
  
 # strip whitespace (can be about 30% faster)
 $doc = Parser->parse($xml, whitespace => 'strip');
  
  
 # All Nodes
 $copy     = $node->cloneNode($deep);
 $nodeType = $node->nodeType;
 $parent   = $node->parentNode;
 $name     = $node->nodeName;
 $xmlstr   = $node->xml;
 $owner    = $node->ownerDocument;
 
 # Element Nodes
 $first = $node->firstChild;
 $last  = $node->lastChild;
 $tag   = $node->tagName;
 $prev  = $node->nextSibling;
 $next  = $node->previousSibling;
 
 $node->setAttribute("foo", $bar);
 $foo = $node->getAttribute("foo");
 foreach my $attr (@{$node->attributes}) {  # attributes as nodelist 
    # ... do stuff
 }
 $node->attributes->{foo} = "bar";          # or as hashref (overload)
  
 $liveNodeList = $node->getElementsByTagName("child"); # deep
 
 $node->insertBefore($newchild, $refchild);
 $node->replaceChild($newchild, $refchild);
 
 
 # Text Nodes
 $nodeValue = $node->nodeValue;
 $node->nodeValue("new text value");
 
 # Processing Instruction Nodes
 # CDATA Nodes
 # Comments
 $data = $node->nodeValue;
 
 # NodeList
 $item = $nodeList->item(42);
 $index = $nodeList->nodeIndex($node);
 $nlist->insertNode($newNode, $index);
 $removed = $nlist->removeNode($node);
 $length = $nlist->length; # OR scalar(@$nodeList)
  
  
 # NodeIterator and NodeFilter
 use XML::DOM::Lite qw(NodeIterator :constants);
 
 $niter = NodeIterator->new($rootnode, SHOW_ELEMENT, {
     acceptNode => sub {
         my $n = shift;
         if ($n->tagName eq 'wantme') {
             return FILTER_ACCEPT;
         } elsif ($n->tagName eq 'skipme') {
             return FILTER_SKIP;
         } else {
             return FILTER_REJECT;
         }
     }        
 );
 while (my $n = $niter->nextNode) {
     # do stuff
 }
  
 # XSLT
 use XML::DOM::Lite qw(Parser XSLT);
 $parser = Parser->new( whitespace => 'strip' );
 $xsldoc = $parser->parse($xsl); 
 $xmldoc = $parser->parse($xml); 
 $output = XSLT->process($xmldoc, $xsldoc);
  
  
 # XPath
 use XML::DOM::Lite qw(XPath);
 $result = XPath->evaluate('/path/to/*[@attr="value"]', $contextNode);
  
  
 # Document
 $rootnode = $doc->documentElement;
 $nodeWithId = $doc->getElementById("my_node_id");
 $textnode = $doc->createTextNode("some text string");
 $element = $doc->createElement("myTagName");
 $docfrag = $doc->createDocumentFragment();
 $xmlstr = $doc->xml;
 $nlist = $doc->selectNodes('/xpath/expression');
 $node  = $doc->selectSingleNode('/xpath/expression');
   
  
 # Serializer
 use XML::DOM::Lite qw(Serializer);
  
 $serializer = Serializer->new;
 $xmlout = $serializer->serializeToString($node);

=head1 INTRODUCTION

Why Yet Another XML Parser?

The first reason is portability. XML::DOM::Lite has only one external dependency: L<Scalar::Util>
without which your Perl installation is probably not sane anyway (if pressed, this dependency could
even be removed). I wanted a DOM standard XML parser kit complete with XSLT, XPath, NodeIterator,
Serializer etc. without needing Expat - and it had to be fast enough for serious use. An added
benefit is that you can freeze and thaw your entire DOM tree using Storable - it's all just Perl.

The second reason is that the DOM standard was not made for Perl and lacks certain
perlisms, and if you, like me, prefer a perlesque way of doing
things, then the full DOM API can get a bit clunky...

Most of the time when dealing with XML DOM trees, I find myself doing
a lot of traversal - and when doing so, I usually want my DOM tree to
be a HASH ref with ARRAY refs of HASH refs (etc.), so node lists are
blessed array refs - so you can say :

 foreach (@{$node->childNodes}) {
     if ($_->nodeType == ELEMENT_NODE) {
         # do stuff
     }
 }

... or ...

 @cdata = map {
     $_->nodeValue if $_->nodeType == TEXT_NODE
 }, @{$node->childNodes};

... or for attributes :

Node lists can also behave as hashrefs using overload, so that we can:
 foreach (keys %{$node->attributes}) {
     # do something
 }

Furthermore, maybe sometimes I want the value of an attribute to,
temporarily, be something other than a string, so...

 $node->setAttribute("sessionStash", $session->stash);

Sometimes, I may want to Storable::freeze or YAML::Dump or
DBM::Deep::put my DOM tree (or some part of it) without any XS bits
getting in the way.

Other times, I may just not have Expat handy, and I want something
that can munge a bit of XML into a usable data structure and still
perform reasonably well.

And/Or any combination of the above.

=head1 DESCRIPTION

XML::DOM::Lite is designed to be a reasonably fast, highly portable,
XML parser kit written in pure perl, implementing the DOM standard
quite closely. To keep performance up and footprint down.

The standard pattern for using the XML::DOM::Lite parser kit is to
 use XML::DOM::Lite qw(Parser :constants);

Available exports are : I<Parser>, I<Node>, I<NodeList>,
I<NodeIterator>, I<NodeFilter>, I<XPath>, I<Document>, I<XSLT> and the
constants.

This is mostly for convenience, so that you can save your key-strokes
for the fun stuff. Alternatively, to avoid polluting your namespace,
you can simply :
 use XML::DOM::Lite::Parser;
 use XML::DOM::Lite::Constants qw(:all);
 # ... etc

=head2 Parser Options

So far the only options which are supported involve white space stripping
and normalization. The whitespace option value can be 'strip' or 'normalize'.

The 'strip' option removes whitespace at the beginning and end of XML tag.
Thus, whitespace between tags is completely eliminated and whitespace at the
beginning and end of text nodes is removed. If you are using inline tags, this
will result in the removal of whitespace between text.

E.g the sequence "Sequence of <b>bold</b> and <i>italic</i> words" will be changed to
'Sequence ofboldanditalcwords'.

The 'normalize' option replaces all multiple tab, new line space characters
with a single space character.

=head1 PERFORMANCE

Performance has been drastically improved as of version 0.4. We're seeing benchmark
time improvements from 16 seconds to 3.6 seconds for 7500 nodes on a 2.8 GHz Celeron.
This is due to a complete overhaul of the parser using the "shallow parsing"
techniques and regular expressions documented on L<http://www.cs.sfu.ca/~cameron/REX.html>

=head1 BUGS

Better error handling.

=head1 ACKNOWLEDGEMENTS

Thanks to:
Robert Frank,
Robert D. Cameron,
Google - for implementing the XPath and XSLT JavaScript libraries which I shamelessly stole

=head1 AUTHOR

Copyright (C) 2005 Richard Hundt <richard NO SPAM AT protea-systems.com>

=head1 LICENCE

This library is free software and may be used under the same terms as
Perl itself.

=cut

