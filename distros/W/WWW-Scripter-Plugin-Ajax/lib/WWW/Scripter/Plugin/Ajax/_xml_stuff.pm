# Interface for XML::DOM::Lite, version 0.15
package WWW::Scripter::Plugin::Ajax;
use XML::DOM::Lite;
use HTML::DOM::Interface ':all'; # for the constants

  %WWW::Scripter::Plugin::Ajax::_xml_interf = (
  	'XML::DOM::Lite::Document' => 'Document',
  	'XML::DOM::Lite::Node' => 'Node',
  	'XML::DOM::Lite::NodeList' => 'NodeList',
  	 Document => {
		_isa => 'Node',
		_hash => 0,
		_array => 0,
  		doctype => OBJ | READONLY,
  		implementation => OBJ | READONLY,
  		documentElement => OBJ | READONLY,
  		createElement => METHOD | OBJ,
  		createDocumentFragment => METHOD | OBJ,
  		createTextNode => METHOD | OBJ,
  		createComment => METHOD | OBJ,
  		createCDATASection => METHOD | OBJ,
  		createProcessingInstruction => METHOD | OBJ,
  		createAttribute => METHOD | OBJ,
  		createEntityReference => METHOD | OBJ,
  		getElementsByTagName => METHOD | OBJ,
  	 },
  	 Node => {
		_hash => 0,
		_array => 0,
  		_constants => [qw[
  			XML::DOM::Lite::Node::ELEMENT_NODE
  			XML::DOM::Lite::Node::ATTRIBUTE_NODE
  			XML::DOM::Lite::Node::TEXT_NODE
  			XML::DOM::Lite::Node::CDATA_SECTION_NODE
  			XML::DOM::Lite::Node::ENTITY_REFERENCE_NODE
  			XML::DOM::Lite::Node::ENTITY_NODE
  			XML::DOM::Lite::Node::PROCESSING_INSTRUCTION_NODE
  			XML::DOM::Lite::Node::COMMENT_NODE
  			XML::DOM::Lite::Node::DOCUMENT_NODE
  			XML::DOM::Lite::Node::DOCUMENT_TYPE_NODE
  			XML::DOM::Lite::Node::DOCUMENT_FRAGMENT_NODE
  			XML::DOM::Lite::Node::NOTATION_NODE
  		]],
  		nodeName => STR | READONLY,
  		nodeValue => STR,
  		nodeType => NUM | READONLY,
  		parentNode => OBJ | READONLY,
  		childNodes => OBJ | READONLY,
  		firstChild => OBJ | READONLY,
  		lastChild => OBJ | READONLY,
  		previousSibling => OBJ | READONLY,
  		nextSibling => OBJ | READONLY,
  		attributes => OBJ | READONLY,
  		ownerDocument => OBJ | READONLY,
  		insertBefore => METHOD | OBJ,
  		replaceChild => METHOD | OBJ,
  		removeChild => METHOD | OBJ,
  		appendChild => METHOD | OBJ,
  		hasChildNodes => METHOD | BOOL,
  		cloneNode => METHOD | OBJ,
  		textContent => STR, # temporary band-aid; implemented by
  		                    # this module, not by XDL
  	 },
  	 NodeList => {
		_hash => 1,
		_array => 1,
  		item => METHOD | OBJ,
  		length => NUM | READONLY,
  	 },
  );

can XML'DOM'Lite'Node:: textContent or eval '
  use XML::DOM::Lite "TEXT_NODE";
  sub XML::DOM::Lite::Node::textContent {
   if(@_ == 1) { # serialise
    my @nodes = shift;
    my $out;
    while(@nodes) {
     my $node = shift @nodes;
     if($node->nodeType == TEXT_NODE) {
      $out .= $node->nodeValue;
     }
     else {
      unshift @nodes, @{ $node->childNodes };
     }
    }
    $out;
   }
   else { # assignment
    my $node = shift;
    $node->removeChild($_) for @{[@{ $node->childNodes }]};
    $node->appendChild($node->ownerDocument->createTextNode(shift));
   }
  } 
';

for my $i(\%WWW::Scripter::Plugin::Ajax::_xml_interf){
	for(grep /::/, keys %$i) {
		my $i = $$i{$$i{$_}};
		for my $k(grep !/^_/,keys%$i){
			delete $$i{$k} unless $_->can($k);
		}
	}	
}
__
