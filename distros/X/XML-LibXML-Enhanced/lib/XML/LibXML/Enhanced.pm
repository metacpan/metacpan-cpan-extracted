use strict;
use warnings;

our $VERSION = "0.01";

=head1 NAME

XML::LibXML::Enhanced - adds convenience methods to XML::LibXML and LibXSLT

=head1 SYNOPSIS

  use XML::LibXML::Enhanced;
  
  my $xml = XML::LibXML::Singleton->instance;
  my $xsl = XML::LibXSLT::Singleton->instance;
  
  my $doc = $xml->parse_xml_string("<root/>");
  
  my $root = $doc->getDocumentElement;
  
  $root->appendHash({ name => 'Michael', email => 'mjs@beebo.org' });

=head1 DESCRIPTION

=head1 ADDED FUNCTIONS

=over 4

=item $xml = parse_xml_file($filename)

=item $xml = parse_xml_string($string)

=item $xml = parse_xml_chunk($string)

Parses a file or string, and returns an XML::LibXML::Document
(parse_xml_file(), parse_xml_string()) or
XML::LibXML::DocumentFragment (parse_xml_chunk()).

That is, the equivalent of
XML::LibXML::Singleton->instance->parse_file($filename), etc.

=item $xsl = parse_xslt_file($filename)

=item $xsl = parse_xslt_string($string)

Parses a file or string, and returns an XML::LibXSLT::Stylesheet.
(L<XML::LibXSLT>.)

That is, the equivalent of
XML::LibXSLT::Singleton->instance->parse_stylesheet(XML::LibXML::Singleton->instance->parse_file($filename)),
etc.

=back

=cut

package XML::LibXML::Enhanced;

use base qw(Exporter);
use vars qw(@EXPORT_OK);

@EXPORT_OK = qw(
    parse_xml_file  parse_xml_string  parse_xml_chunk
    parse_xslt_file parse_xslt_string promote
);

sub parse_xml_file {
    if (wantarray) {
	return map {
	    XML::LibXML::Singleton->instance->parse_file($_)
	} @_;
    }
    else {
	return XML::LibXML::Singleton->instance->parse_file($_[0]);
    }
}

sub parse_xml_string {
    return XML::LibXML::Singleton->instance->parse_string(@_);
}

sub parse_xml_chunk {
    return XML::LibXML::Singleton->instance->parse_balanced_chunk(@_);
}

sub parse_xslt_file {
    if (wantarray) {
	return map {
	    XML::LibXSLT::Singleton->instance->parse_stylesheet(parse_xml_file($_))
	} @_;
    }
    else {
	return XML::LibXSLT::Singleton->instance->parse_stylesheet(parse_xml_file($_[0]));
    }
}

sub parse_xslt_string {
    return XML::LibXSLT::Singleton->instance->parse_stylesheet(parse_xml_string(@_));
}

sub promote {
    return XML::LibXSLT::xpath_to_string(@_);
}    

=head1 ADDED CLASSES

=head2 XML::LibXML::Singleton

Singleton version of XML::LibXML; get an instance via
C<XML::LibXML::SIngleton-E<gt>instance>.

Note that the methods C<load_ext_dtd(0)> and C<validation(0)> have
been called on the returned object; see C<XML::LibXML> for futher
details.

=cut

package XML::LibXML::Singleton;

use base qw(XML::LibXML Class::Singleton);

sub _new_instance {
    my ($proto, @args) = @_;
    
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(@args);
    
    $self->load_ext_dtd(0);
    $self->validation(0);
    
    $self;
}

=head2 XML::LibXSLT::Singleton

Singleton version of XML::LibXSLT; get an instance via
C<XML::LibXSLT::SIngleton-E<gt>instance>.

=cut

package XML::LibXSLT::Singleton;

use base qw(XML::LibXSLT Class::Singleton);

=head1 ADDED METHODS

=head2 TO XML::LibXML::Node

=over 4

=cut

package XML::LibXML::Node;

use Carp;
use XML::LibXML qw(XML_ELEMENT_NODE XML_TEXT_NODE);
use HTML::Entities;
use Data::Eacherator qw(eacherator);

=item $n->appendHash( $hash [, $values_are_text ])

Converts C<$hash> to an XML element, and adds it to C<$n>.  (That is,
the opposite of C<$hash = $n-E<gt>toHash>.)

If C<$values_are_text> is 1, the values of the hash are treated as
text, and are XML-encoded (C<&> to C<&amp;> and so forth) before being
added to the node.

If C<$values_are_text> is 0 or undefined, the values of the hash are
treated as XML, and are parsed before being added to the node.  In
this case, the key values must be either be well-formed XML, or
well-balanced XML chunks.  (i.e. "<foo/><bar/>" is okay, but not
"<foo>".)  If neither is true, a comment will be inserted in the place
of value--C<NOT BALANCED XML>.

For example, if

  $hash = {
    name => "Clive",
    email => "clive@example.com",
  };
  
and

  $node
  
is

  <row>
  </row>
  
then

  $node->appendHash($hash);
  
results in the C<$node>

  <row>
      <name>Clive</name>
      <email>clive@example.com</email>
  </row>

NOTE: attribute names (i.e. key values) are lowercased.

=cut

sub appendHash {
    my ($self, $data, $values_are_text) = @_;
    
    my $doc = $self->getOwnerDocument;

    my $iter = eacherator($data);

    while (my ($k, $v) = $iter->()) {

	my $n = $doc->createElement($k);
	
	if ((defined $v) && ($v ne '') && !ref($v)) {

	    if ($values_are_text) {
		$n->appendChild($doc->createTextNode($v));
	    }

	    else {
		my $c = eval {
		    XML::LibXML::Singleton->instance->parse_balanced_chunk($v);
		};
		if ($@) { 
		    $n->appendChild(
			$doc->createComment("NOT BALANCED XML")
		    );
		}
		else {
		    $n->appendChild(
			$doc->adoptNode($c)
		    );
		}
	    }
	}

	$self->appendChild($n);
    }
    
    $data; # because $n->appendChild($c) returns $c
}

=item $n->appendAttributeHash( $hash )

Adds attributes to node C<$n>.

=cut

sub appendAttributeHash {
    my ($self, $data) = @_;
    
    my $iter = eacherator($data);

    while (my ($k, $v) = $iter->()) {
	$self->setAttribute($k, $v);
    }
    
    $data;
}

=item $h = $n->toHash( [ $values_are_text ] )

Returns a simple hash reference representation of node C<$n>.  (That
is, the opposite of C<$n-E<gt>appendHash($h)>.)

If C<$values_are_text> is 1, an XML decoding of the values is
performed.  (C<&amp;> to C<&>, etc.) 

If C<$values_are_text> is 0 or undefined, then no transformation of
the values are performed.

For example, when C<toHash()> is called on the C<row> node

  <row>
    <name>Michael</name>
    <email>mjs@beebo.org</email>
  </row>

the return value will be

  {
    name => 'Michael',
    email => 'mjs@beebo.org',
  }

B<NOTE>:

=over 4

=item o

order is not necessarily preserved, and if two or more tags of the
same name are present, only one will be present in the hash.

=item o

attributes are discarded.

=back
  
=cut

sub toHash {
    my ($self, $values_are_text) = @_;
    
    # The grep below filters out non element nodes because we need to
    # skip text nodes in the event of mixed content.

    my $hash = {
	map { 
	    $_->nodeName, $_->childrenToString 
	}
	grep { 
	    $_->nodeType == XML_ELEMENT_NODE 
	}
	$self->childNodes
    };
    
    if ($values_are_text) {
	
	# createTextNode() encodes its argument; we need to perform
	# the reverse process here.  (&amp; => &, and so on.)

	foreach (values %$hash) {
	    $_ = decode_entities($_);
	}

    }
    
    return $hash;
}

=item $h = $n->toAttributeHash

=cut

sub toAttributeHash {
    my ($self) = @_;
    
    return { map { $_->nodeName, $_->value } $self->attributes };
}

=item $n->appendRow($hash [, $name ])

Similar to C<appendHash($hash)> except that the appended hash is added
as child of a C<$name> element.  That is, if C<$n> is the node
"<root/>", C<$n-E<gt>appendRow({ name =E<gt> 'Michael' }, "row")> results
in

  <root>
    <row>
      <name>Michael</name>
    </row>
  </root>
  
C<$name> defaults to "row".  

=cut

sub appendRow {
    my ($self, $hash, $name, $values_are_text) = @_;

    $name = "row" unless defined $name;
    $values_are_text = 0 unless defined $values_are_text;

    my $doc = $self->getOwnerDocument;
    my $row = $doc->createElement(lc($name));
    
    $row->appendHash($hash, $values_are_text);
    
    return $self->appendChild($row);
}

=item $s = $n->childrenToString

Like C<toString()> except that only the node's I<children> are
stringified--the opening and closing tags of the node itself are
omitted.  (This may create a "balanced chunk.")

=cut

sub childrenToString {
    my ($self) = @_;
    
    return join('', map { defined $_->toString ? $_->toString : '' } $self->childNodes);
}

=back

=head1 AUTHOR

Michael Stillwell <mjs@beebo.org>

=cut

1;

__END__

=pod

# OLD CODE

sub toHash_can_recurse {
    my ($self, $recursive) = @_;
    
    $recursive = 0 unless defined $recursive;

    my @children = grep { $_->nodeType == XML_ELEMENT_NODE } 
                        $self->childNodes;
    
    if (@children) {

	# WE GET HERE IF: THERE'S AT LEAST ONE ELEMENT NODE.
	#
	# NOTE: THE FOLLOWING SECTIONS, BY PROCESSING ONLY @children,
	# PROCESS ONLY ELEMENT NODES--ANY TEXT NODES THAT MAY HAVE
	# BEEN CHILDREN OF $self (E.G. IN THE CASE OF MIXED CONTENT)
	# ARE IGNORED.

	if ($recursive) {
	    return {
		map { $_->nodeName, $_->toHash($recursive) }
	            @children
	    };
	}
	
	else {
	    return {
		map { $_->nodeName, $_->childrenToString }
	            @children
	    };
	}

    }
    
    else {

	# WE GET HERE IF: THERE'S EITHER NO CHILDREN, OR NO CHILDREN
	# THAT ARE ELEMENT NODES.  (WE ASSUME THAT IN THE LATTER
	# CASE, THERE'S ONE CHILD, AND IT'S A TEXT NODE.)

	return $self->hasChildNodes ? $self->firstChild->toString : '';
	    
    }

}

sub appendHash_old {
    my ($self, $hash, $values_are_xml) = @_;
    
    $values_are_xml = 1 unless defined $values_are_xml;

    my $doc = $self->getOwnerDocument;

    while (my ($k, $v) = each %$hash) {

	my $n = $doc->createElement(lc($k));
	
	if (defined $v) {

	    if (!ref($v)) {
		
		if ($values_are_xml) {

		    my $c = eval {
			XML::LibXML::Singleton->instance->parse_balanced_chunk(
			    $v
			);
		    };

		    if ($@) {
			
			# COULDN'T PARSE $v

			$n->appendChild($doc->createComment(
			    "VALUE NOT BALANCED XML"
			));
		    }
		    else {
			
			# COULD PARSE $v

			$n->appendChild($doc->adoptNode(
			    $c
			));
		    }
		}
		
		else {
		    $n->appendChild($doc->createTextNode($v));
		}
	    }

	    elsif (ref($v) eq "HASH") {
		$n->appendHash($v, $values_are_xml);
	    }

	    else {
		# SOME OTHER SORT OF REFERENCE, SKIP IT (SILENTLY)
	    }
	}
	    
	$self->appendChild($n);
    }
    
    $hash; # because $n->appendChild($c) returns $c
}

=cut

