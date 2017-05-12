package XML::XSH2::XPathToXML;
###
#
# Name: XML::XSH2::XPathToXML
# Version: 0.05
# Description: Parses a list of XPath/value pairs and returns an XML::LibXML note-tree.
# Original author: Kurt George Gjerde
# Extended by Petr Pajas
# Copyright: InterMedia, University of Bergen (2002)
# Licence: Same as Perl
#
###

### POD at bottom.


###

use XML::LibXML;
use strict;
no warnings qw(uninitialized);

use vars qw($VERSION);
$VERSION = '0.05';

my $PACKAGE = __PACKAGE__;

our ($QUOT,$NAMECHAR,$FIRSTNAMECHAR,$NAME,$STEP,$LAST_STEP,$FILTER,$PREDICATE,$AXIS);

# regexps to parse XPath steps

$NAMECHAR = '[-_.[:alnum:]]';
$FIRSTNAMECHAR = '[-_.[:alpha:]]';
$NAME = "(?:${FIRSTNAMECHAR}${NAMECHAR}*(?::${FIRSTNAMECHAR}${NAMECHAR}+)*)";

$QUOT = q{(?:'[^']*'|"[^"]*")};
$PREDICATE = qr/
  (?:
     (?> [^][()"']* )   # non-parens without backtracking
     |
     '[^']*' | "[^"]*"  # quotes
     |
     \[
       (??{$PREDICATE}) # matching square brackets
     \]
     |
     \(
       (??{$PREDICATE}) # matching round brackets
     \)
   )*
/x;

$FILTER = qr/(?:\[$PREDICATE\])/;

$AXIS=qr{(?:(?:following-sibling|following|preceding|preceding-sibling|parent|ancestor|ancestor-or-self|descendant|self|descendant-or-self|child|namespace)::)?};
$STEP = qr{(?:(?:^|/)${AXIS}${NAME}${FILTER}*)};
$LAST_STEP = qr{(?:(?:^|/)(?:\@${NAME}|${AXIS}(?:${NAME}|comment[(][)]|text[(][)]|processing-instruction[(](?:\s*"${NAME}"\s*|\s*'${NAME}'\s*)[)]))${FILTER}*)};

### NEW
#
sub new {
  my ($class, %args) = @_;
  my $self = \%args;
  bless $self, $class;

  $self->{version} ||= '1.0';
  $self->{debug} ||= 0;
  $self->{maxAutoSiblings} = 256 if not defined $self->{maxAutoSiblings};

  $self->init();

  return $self;
}


### CLOSE
#
sub close {
  my $self = shift;
  undef $self->{tree};
  undef $self->{node};
  undef $self->{doc};
}


### INIT
#
sub init {
  my $self = shift;
  unless ($self->{doc}) {
    if (ref($self->{node})) {
      $self->{doc} = $self->{node}->ownerDocument;
    } else {
      $self->{doc} = XML::LibXML::Document->createDocument( $self->{version}, $self->{encoding} );
      $self->{doc}->setDocumentElement( $self->{doc}->createElement('root') );
    }
  }
  $self->{node} ||= $self->{doc};
  $self->{tree} = {};
}


### RESET
#
sub setContextNode {
  my ($self,$node) = @_;
  undef $self->{tree};
  unless (ref($node)) {
    if ($self->{XPathContext}) {
      $node=$self->{XPathContext}->find($node)->get_node(1);
    } else {
      $node=$self->{node}->find($node)->get_node(1);
    }
  }
  if ($node) {
    $self->{node} = $node;
    $self->{doc} = $node->ownerDocument;
  } else {
    die "[$PACKAGE] Context node doesn't exist.\n";
  }
}


### RESET
#
sub reset {
  my ($self,%args) = @_;
  $self->close;
  $self->init(%args);
}


### GET IT
#
sub contextNode { shift->{node} }

sub document { shift->{doc} }

sub documentElement { shift->{doc}->documentElement }
  

### PARSE
#
sub parse {
  my ($self, $data, $value) = @_;
  
  if (ref($data) eq 'HASH') {
    foreach my $xpath (sort keys %{$data}) {
      print "$xpath\n" if $self->{debug};
      $self->createNode( $xpath, $data->{$xpath} );
    }
  } elsif (ref($data) eq 'ARRAY') {    
    # preserve order
    die "[$PACKAGE] Array must have even number of elements.\n" if (@$data % 2);
    for (my $i=0; $i<@$data; $i+=2) {
      print "$data->[$i]\n" if $self->{debug};
      $self->createNode( $data->[$i], $data->[$i+1] );
    }
  } else {
    $self->createNode( $data, $value );
  }
  
  return $self->{doc}->documentElement();
}


### _CREATE NODE
#
# Creates nodes, text nodes and attributes from an xpath and a value.
#
# Returns the node created
#

sub createNode {
  my ($self, $xpath, $value, $context_node) = @_;

  # strip the uninteresting part
  $xpath=~s{^\.\s+/}{};

  # roughly verify that we have an XPath in a supported form:
  die "[$PACKAGE] Can't create nodes based on XPath $xpath\n" unless $xpath =~ m{^(?:\$${NAME}${FILTER}*)?$STEP*$LAST_STEP$};
#  return;

  if ($xpath=~s{^/}{}) {
    # start from the document level
    $self->_createSteps($self->{doc},$xpath,$value);
  } else {
    if ($xpath =~ s{^(\$${NAME}${FILTER}*)/}{./}) {
      $context_node = $1;
    }
    # start from the current node
    if ($context_node ne "" and !ref($context_node)) {
      if ($self->{XPathContext}) {
	$context_node=$self->{XPathContext}->find($context_node)->get_node(1);
      } else {
	$context_node=$self->{node}->find($context_node)->get_node(1);
      }
      die "[$PACKAGE] Context node doesn't exist.\n" unless ($context_node);
    } else {
      $context_node ||= $self->{node};
    }
    $self->_createSteps($context_node,$xpath,$value);
  }
}

sub _lookup_namespace {
  my ($self,$node,$name)=@_;
  if ($name=~s/^(${NAMECHAR}+)://) {
    my $prefix = $1;
    my $uri = $node->lookupNamespaceURI($prefix);
    if (!defined($uri) and $self->{XPathContext} and
	    UNIVERSAL::can($self->{XPathContext},'lookupNs')) {
      $uri = $self->{XPathContext}->lookupNs($prefix)
    }
    if (!defined($uri) and ref($self->{namespaces})) {
      $uri = $self->{namespaces}->{ $prefix };
    }
    if (!defined($uri)) {
      warn "Couldn't find namespace URI for the element ${prefix}:${node}!\n";
      return ($prefix.':'.$name,undef);
    } else {
      # find the best suitable prefix
      my $real_prefix = $node->lookupNamespacePrefix( $uri );
      if ($real_prefix eq "" and !defined($node->lookupNamespaceURI( undef ))) {
	$real_prefix = $prefix;
      }
      return (($real_prefix ne "") ? $real_prefix.':'.$name : $name , $uri);
    }
  } else {
    return ($name,undef);
  }
}

sub _insertNode {
  my ( $self, $axis, $node, $next ) = @_;
  if ($axis =~ /^$|^child::|^descendant(?:-or-self)?::/) {
    $node->appendChild( $next );
  } elsif ($axis =~ /^(following(?:-sibling)?)::/) {
    my $parent = $node->parentNode;
    die "Can't create axis $1 on a document node" unless $parent;
    $parent->insertAfter( $next, $node );
  } elsif ($axis =~ /^(preceding(?:-sibling)?)::/) {
    my $parent = $node->parentNode;
    die "Can't create axis $1 on a document node" unless $parent;
    $parent->insertBefore( $next, $node );
  } elsif ($axis =~ /^(parent|ancestor|ancestor-or-self|self|namespace)::/) {
    die "Can't create axis $1";
  }
}

sub _createSteps {
  my ($self,$node,$xpath,$value)=@_;

  while ($xpath ne "") {
  # get the first step
    my $step = $xpath;
    my $rest;
    if ($step =~ s{^(.*?)\/(.*)$}{$1}) {
      $rest = $2;
    }

    print "$xpath : Processing step: $step (remains $rest)\n" if $self->{debug};

    my $next = $self->{XPathContext} ?
      $self->{XPathContext}->find($step,$node)->get_node(1) :
      $node->find($step)->get_node(1);

    unless ($next) {
      # auto-create the node(s) implied by the step 

      if ($step =~ /^(?:@|attribute::)($NAME)/) {
	my $name = $1;
	if ($rest eq "") {
	  print "$xpath : auto-creating attribute $name for $step\n" if $self->{debug};
	  my ($real_name,$uri) = $self->_lookup_namespace($node,$name);
	  if (defined($uri) and $uri ne "") {
	    $node->setAttributeNS($uri,$name,$value);
	    return $node->getAttributeNodeNS($uri,$name);
	  } else {
	    $node->setAttribute($name,$value);
	    return $node->getAttributeNode($name);
	  }
	} else {
	  die "[$PACKAGE] XPath steps follow after an attribute: $step/$rest\n";
	}
      } elsif ($step =~ /^($AXIS)text\(\)/) {
	my $axis = $1;
	if ($rest eq "") {
	  print "$xpath : auto-creating text() for $step\n" if $self->{debug};
	  $next = $self->{doc}->createTextNode($value);
	  $self->_insertNode( $axis, $node, $next );
	  return $next;
	} else {
	  die "[$PACKAGE] XPath steps follow after a text(): $step/$rest\n";
	}
      } elsif ($step  =~ /^($AXIS)comment\(\)/) {
	my $axis = $1;
	if ($rest eq "") {
	  print "$xpath : auto-creating comment <!-- $value --> for $step\n" if $self->{debug};
	  $next = $self->{doc}->createComment($value);
	  $self->_insertNode( $axis, $node, $next );
	  return $next;
	} else {
	  die "[$PACKAGE] XPath steps follow after a text(): $step/$rest\n";
	}
      } elsif ($step  =~ /^($AXIS)processing-instruction\((${PREDICATE})\)/o) {
	my $axis = $1;
	my $name = $2;
	if ($name=~/^(?:\s*'([^']*)'|"([^"]*)"\s*)$/) {
	  $name=$1.$2;
	  if ($rest eq "") {
	    print "$xpath : auto-creating comment <!-- $value --> for $step\n" if $self->{debug};
	    $next = $self->{doc}->createProcessingInstruction($name,$value);
	    $self->_insertNode( $axis, $node, $next );
	    return $next;
	  } else {
	    die "[$PACKAGE] XPath steps follow after a processing-instruction(): $step/$rest\n";
	  }
	} else {
	  die "[$PACKAGE] Can't auto-create PI as specified ($name), use processing-instruction('name')\n";
	}
      } else {
	my ($name,$axis);
	if ($step =~ /^($AXIS)($NAME)(?!\()/) {
	  $axis = $1;
	  $name = $2;
	};
	if ($name eq "") {
	  die "[$PACKAGE] Can't determine element name from step $step\n";
	}
	my @auto;
	do {{
	  print "$xpath : auto-creating element $name for $step\n" if $self->{debug};
	  if ($self->{maxAutoSiblings} && @auto>$self->{maxAutoSiblings}) {
	    # unlink all added siblings
	    # print STDERR $self->{doc}->toString(1),"\n @auto\n";
	    $_->unlinkNode for @auto;
	    die "[$PACKAGE] Max automatic creation of siblings overflow ($self->{maxAutoSiblings}) for '$xpath', step '$step'!\n";
	  }
	  my ($real_name,$uri) = $self->_lookup_namespace($node,$name);
	  if (defined($uri) and $uri ne "") {
	    $next = $self->{doc}->createElementNS($uri,$real_name);
	  } else {
	    $next = $self->{doc}->createElement($real_name);
	  }
	  if ($node == $self->{doc}) {
	    $node->setDocumentElement( $next );
	    # iterating won't help here
	    last;
	  } else {
	    $self->_insertNode( $axis, $node, $next );
	  }
	  push @auto,$next;

	  $next = $self->{XPathContext} ?
	    $self->{XPathContext}->find($step,$node)->get_node(1) :
	    $node->find($step)->get_node(1);
	}} while (!$next);
      }
    }
    $xpath = $rest;
    $node = $next;
  };

  if ($node) {
    print "Setting value for $xpath\n" if $self->{debug};
    if ($node->nodeType == XML::LibXML::XML_ATTRIBUTE_NODE()) {
      $node->setValue($value);
    } elsif ($node->nodeType != XML::LibXML::XML_ELEMENT_NODE()) {
      $node->setData($value);
    } else {
      $node->removeChildNodes() if $node->hasChildNodes;
      if (ref($value) and UNIVERSAL::isa($value,'XML::LibXML::Node')) {
	$node->appendChild( $value );
      } else {
	$node->appendTextNode($value) if $value ne "";
      }
    }
  } else {
    warn "No node for XPath ($xpath)\n";
  }
  return $node;
}

### 
#
# The following method use a hash to store all the xpaths and their nodes.
# Locating a node is purely based on looking up its xpath the way it's been
# written. Thus 'somenode[1]' and 'somenode[position()=1]' will be treated as
# two different nodes!
#
# Using proper xpath doc->find to retrieve nodes instead of the hash will
# eliminate this problem.
#
# Anyway:
#   - if you have a 'node[1]' and a 'node[3]' a 2nd node will not be 
#     created inbetween.
#   - if you have a 'node[position()=1]' and a 'node[2]' the nodes will
#     be reversed in the doc (all xpaths are created in alphabetical order).
#
# ALL OF THESE PROBLEMS HAVE BEEN FIXED IN THE createNode METHOD ABOVE!
#
#
sub _createNode_simple {
  my ($self, $xpath, $value) = @_;

  my $name = $xpath;
  $name =~ s{^.*\/(.*)$}{$1};
  $name =~ s{\[.*\]$}{};
  
  my $parent = $xpath;
  $parent =~ s{^(.*)\/.*$}{$1};

  if ($parent && !defined $self->{tree}->{$parent}) {
    $self->_createNode_simple($parent, undef);
  }
  
  # Attribute
  if ($name =~ /^@/) {
    print "   addAttribute: $xpath\n" if $self->{debug};
    $self->{tree}->{$parent}->setAttribute($name,$value);
  } 
  # Element
  else {
    print "  createElement: $xpath\n" if $self->{debug};

    $self->{tree}->{$xpath} = $self->{doc}->createElement($name);  
  
    if ($parent) {
      $self->{tree}->{$parent}->appendChild( $self->{tree}->{$xpath} );
    } else {
      $self->{doc}->setDocumentElement( $self->{tree}->{$xpath} );
    }
  
    $self->{tree}->{$xpath}->appendTextNode($value) if $value;
  }

  return undef;
}


###########
1;


__END__


=head1 NAME

XML::XSH2::XPathToXML - Generates XML document from XPath expressions

=head1 SYNOPSIS

  my @data = (
    '/project/name'         => 'The Ultimate Question',
    '/project/comment()'      => ' generated by XPathToXML ',
    '/project/start'        => '2002-09-08',
    '/project/end'          => '7002002-09-08',
    '/project/@id'          => '42',
    '/project/temp/pre'     => '41',
    '/project/temp/pre[position()=6]' => '46',
    '/project/temp/pre[3]'  => '43',
    '/project/temp/pre[2]'  => XML::LibXML->new->parse_xml_chunk(q(arbitrary <b>XML</b> chunk)),
  );

  my $xpx = new XML::XPathToXML( debug=>1 );

  $xpx->parse( \@data );

  $xpx->parse( '/project/temp/pre[last()]/@guess', 'tooHigh' );

  print $xpx->documentElement->toString(1)."\n";

Result:

  <project id="42">
    <!-- generated by XPathToXML -->
    <name>The Ultimate Question</name>
    <start>2002-09-08</start>
    <end>7002002-09-08</end>
    <temp>
      <pre>41</pre>
      <pre>arbitrary <b>XML</b> chunk</pre>
      <pre>43</pre>
      <pre/>
      <pre/>
      <pre guess="tooHigh">46</pre>
    </temp>
  </project>


=head1 DESCRIPTION

Generates an XML document or node tree from one or more XPath expressions.
Returnes an XML::LibXML::Document or XML::LibXML::Element.

Only a limited subset of XPath is currently supported. Namely, the
XPath expression must be a location path consisting of a /-separated
sequence of one or more location steps along the child, sibling, or attribute
axes.  The node-test part of the expression cannot be
neither a wildcard (C<*>, C<@*>, C<prefix:*>, ...), nor the C<node()>
function. If a namespace prefix is used, then either the namespace
must already be declared in the document or registered with an
XPathContext object. Location steps may contain arbitrary predicates
(filters), but see the details below.

The parser processes the location path as follows:

For an absolute location path (starting with C</>) the evaluation
starts on the document node. For relative location path the
evaluation starts on a specified initial context node.  The parser
evaluates the location path from left to right, one location step at a
time, starting either on the document node (in case of absolute
location path) or on a specified initial context node (in case of
relative location paths). If the location step (including filters)
matches a child node or an attribute of the current node, then the
parser moves to the first node matched and to the next location
step. If no nodes are matched by the location step, then the parser
creates an element or attribute with the name (and possibly namespace)
specified in the node-test part of the location step and tries again.
If still no nodes are matched, the parser repeats the procedure until
the location step matches or the number of sibling nodes created in
this way reaches the limit specified in maximumAutoSiblings. In the
first case the parser moves to the first matching node. In the latter
case the parser fails (removing all sibling-nodes created for the failed
location-step from the tree).

Hence, if a filter predicate of a location step specifies a position
of a node (e.g. with C<[4]>, or C<[position>3], etc), then the parser
tries to automatically create empty siblings nodes until it finally
creates one with for which the predicate is true.

Note, that because the parser only processes one location step at a
time and always picks the first matching node, expressions like
C</root/a/b> are treated as C</root/a[1]/b[1]>. So, in case of the
document

  <root>
    <a/>
    <a>
      <b/> 
    </a>
  </root>

$xpx->parse(q(/root/a/b),'foo') will result in

  <root>
    <a><b>foo</b></a>
    <a>
      <b/>
    </a>
  </root>

although an element matching /root/a/b was already present in the
document. To prevent this, either explicitly state that C<b> must
exist with C</root/a[b]/b> or set the second element C<a> as the context
node and use a relative location path such as C<b>:

$xpx->setContextNode($xpc->document->find('/root/a[2]')->get_node(1))
$xpx->parse("b","foo"); # "./b" is also ok

or simply

$xpx->createNode("b","foo",$xpc->document->find('/root/a[2]')->get_node(1));


In the tradition of XML::LibXML errors must be trapped with eval()
(the parser dies on error).

=head2 Methods

=over 4


=item new(%args)

Generates a new XML::XPathToXML object.

Arguments:

B<version> sets the XML version; default is "1.0".

B<encoding> sets the XML encoding; default is none (meaning UTF8).

B<debug> turns debugging on/off; default is off.

B<doc> provide a XML::LibXML::Document to start with (rather than
starting with an empty document)

B<node> specify initial context node for relative XPath expressions

B<XPathContext> specify XML::LibXML::XPathContext object to use for
XPath evaluation (if not specified, then default LibXML's XPath
support are used).

B<namespaces> specify a hash mapping namespace prefixes to namespace
URIs. This mapping is used to determine the correct namespace URI if
an element or attribute with a prefix is auto-created. Note that if an
XPathContext was specified that provides a lookupNs() method , then
this module will also try to determine the namespace URIs from the
namespace prefixes registered for the XPathContext.

B<maxAutoSiblings> sets the maximum number of siblings that are automatically
generated for a single XPath expression; default is 256.

=item parse( $hashref )

=item parse( $arrayref )

=item parse( $xpath, $value )

Parse XPath/value pairs and generate nodes.

=item createNode( $xpath, $value, $context_node? )

Like parse( $xpath, $value ) but returns the newly created node.

=item document()

Returns the document as an XML::LibXML::Document.

=item documentElement()

Returns the document element as an XML::LibXML::Element.

=item contextNode()

Returns the context node as an XML::LibXML::Node.

=item setContextNode( $node )

Set context to a given XML::LibXML::Node. This node is used as a
context for relative XPath expressions.

=item reset( %args )

Resets the parser. Optionally, B<doc> and B<node> can be specified as
in new().

=item close()

Closes the parser (forgetting current document and context
node). After this you have to call C<init()> before using the parser.

=item init()

Initiates the parser. Only needed after C<close()>.

=back

=head1 AUTHOR

Kurt George Gjerde, version 0.05 by Petr Pajas

=head1 COPYRIGHT

2002 (c) InterMedia, University of Bergen.

Available under the same conditions as Perl.

