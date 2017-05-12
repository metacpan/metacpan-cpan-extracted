package XML::DOM2::Parser;

=head1 NAME

XML::DOM2::Parser - Sax based xml parser for XML::DOM2

=head1 DESCRIPTION

This parser was constructed using XML::SAX::PurePerl which
Was known at the time to lack a number of calls which where
important for dealing with things like document type and
text formating and xml decls. hopfully in the future this
will be fixed and this method will be able to take advantage
of those part of an xml page.

=cut

use strict;
use base qw(XML::SAX::Base);
use Carp;

=head2 $parser->new( %options )

  Create a new parser object.

=cut
sub new
{
	my ($proto, %opts) = @_;
	$opts{'inline'} = 1;
	if(not $opts{'document'}) {
		croak "Unable to parse xml without document";
	}
	return bless \%opts, $proto;
}

=head2 $parser->document()

  Return the document object

=cut
sub document
{
	my ($self) = @_;
	return $self->{'document'};
}

=head2 $parser->start_document( $document )

  Called at the start of a document.

=cut
sub start_document {
	my ($self, $doc) = @_;
	$self->{'inline'} = 0;
}

=head2 $parser->end_document()

  Called at the end of a document.

=cut
sub end_document {
	my ($self) = @_;
}

=head2 $parser->start_element( $node )

  Start a new xml element

=cut
sub start_element
{
	my ($self, $node) = @_;
	$self->text;
	# ELEMENT
	# LocalName - The name of the element minus any namespace prefix it may have come with in the document.
	# NamespaceURI - The URI of the namespace associated with this element, or the empty string for none.
	# Attributes - A set of attributes as described below.
	# Name - The name of the element as it was seen in the document (i.e.  including any prefix associated with it)
	# Prefix - The prefix used to qualify this element’s namespace, or the empty string if none.

	my $element;
	my $parent = $self->{'parent'};

	if(not $parent and not $self->{'inline'}) {
		$self->document->doctype->name($node->{'LocalName'});
	}

	if( $node->{'LocalName'} ) {
		if($parent) {
			# Name spaces
			my $ns = $self->document->getNamespace( $node->{'Prefix'} ) if $node->{'Prefix'};
			warn "Could not get namespace for node: ".$node->{'Prefix'}."\n" if $node->{'Prefix'} && not defined($ns);
			$element = $parent->createChildElement($node->{'LocalName'},
				document  => $self->document,
				namespace => $ns,
			);
		} else {
			# This would be a root element (document)
			$self->{'parents'} = [];
			$element = $self->document->createElement( $node->{'LocalName'}, document => $self->document );
			$self->document->documentElement($element);
			# Name spaces, we do this first so later on we don't try adding attributes
			# into the document element that have namespaces yet to be added in the hash
			# order (perl!)
			my $ns = $self->document->getNamespace( 'xmlns' );
			foreach my $a (keys(%{$node->{'Attributes'}})) {
				my $attribute = $node->{'Attributes'}->{$a};
				if($attribute->{'Name'} eq 'xmlns') {
#					warn "Namespace ".$attribute->{'Prefix'}.':'.$attribute->{'Name'}.'='.$attribute->{'Value'}." to ".$node->{'Name'}."\n";
					$element->setAttribute( $attribute->{'LocalName'}, $attribute->{'Value'} );
				} elsif($attribute->{'Prefix'} eq 'xmlns') {
#					warn "NSW ".$attribute->{'Prefix'}.':'.$attribute->{'Name'}.'='.$attribute->{'Value'}." to ".$node->{'Name'}."\n";
					$self->document->createNamespace($attribute->{'LocalName'}, $attribute->{'Value'});
				} else {
					next;
				}
				delete($node->{'Attributes'}->{$a});
			}
		}
	}

	# ATTRIBUTES {}
    # LocalName - The name of the attribute minus any namespace prefix it may have come with in the document.
    # NamespaceURI - The URI of the namespace associated with this attribute. If the attribute had no prefix, then this consists of just the empty string.
    # Name - The attribute’s name as it appeared in the document, including any namespace prefix.
    # Prefix - The prefix used to qualify this attribute’s namepace, or the empty string if none.
    # Value - VALUE.

	foreach my $attribute (values(%{$node->{'Attributes'}})) {
		if($attribute->{'Prefix'}) {
			my $ns = $self->document->getNamespace( $attribute->{'Prefix'} );
			if(not $ns) {
				warn "Could not get namespace for attribute: ".$attribute->{'Prefix'}." (".$attribute->{'NamespaceURI'}.")\n";
				next;
			}
			$element->setAttributeNS( $ns, $attribute->{'LocalName'}, $attribute->{'Value'} );
		} else {
			$element->setAttribute( $attribute->{'LocalName'}, $attribute->{'Value'} );
		}
	}

	push(@{$self->{'parents'}}, $self->{'parent'})if $self->{'parent'};
	$self->{'parent'} = $element;

}

=head2 $parser->end_element( $element )

  Ends an xml element

=cut
sub end_element
{
	my ($self, $element) = @_;
	$self->text;
    # ELEMENT
	# LocalName - The name of the element minus any namespace prefix it may have come with in the document.
	# NamespaceURI - The URI of the namespace associated with this element, or the empty string for none.
	# Name - The name of the element as it was seen in the document (i.e.  including any prefix associated with it)
	# Prefix - The prefix used to qualify this element’s namespace, or the empty string if none.
	$self->{'parent'} = pop @{$self->{'parents'}};
}

=head2 $parser->characters()

  Handle part of a cdata by concatination

=cut
sub characters
{
	my ($self, $text) = @_;

	$text = $text->() if ref($text) eq 'CODE';
	# We wish to keep track of text characters, and
	# and deal with text once other elements are found
	$self->{'text'} = '' if not defined($self->{'-text'});
	$self->{'text'} .= $text->{'Data'};
}

=head2 $parser->text()

  Handle combined text strings as cdata

=cut
sub text
{
	my ($self) = @_;
	if($self->{'text'}) {
		my $text = $self->{'text'};
		if($text =~ /\S/) {
			$self->{'parent'}->cdata($text);
		}
		delete($self->{'text'});
	}
}

=head2 $parser->comment()

 WARNING: Comments are currently removed!

=cut
sub comment
{
	my ($self, $comment) = @_;
	$self->text;
#	warn "Comment '".$comment->{'Data'}."'\n";
	# Data
}

=head2 $parser->start_cdata()

  Never used by parser.

=cut
sub start_cdata
{
	print STDERR "START CDATA\n";
}

=head2 $parser->end_cdata()

  Never used by parser.

=cut
sub end_cdata
{
	print STDERR "END CDATA\n";
}

=head2 $parser->processing_instruction()

  Never used by parser.

=cut
sub processing_instruction
{
	print STDERR "PI\n";
}

=head2 $parser->doctype_decl( $dtd )

  We want to store the below details for the document creation

=cut
sub doctype_decl
{
	my ($self, $dtd) = @_;
	my $doc = $self->document;
	# Name
	# SystemId
	# PublicId
	warn "Setting doctype name to ".$dtd->{'Name'}."\n";
	$doc->doctype->name($dtd->{'Name'});
	$doc->doctype->systemId($dtd->{'SystemId'});
	$doc->doctype->publicId($dtd->{'PublicId'});
#	$self->{'dtd'} = $dtd;
}

=head2 $parser->xml_decl( $xml )

  Decode the xml decleration information.

=cut
sub xml_decl
{
	my ($self, $xml) = @_;
	my $doc = $self->document;
	# Version
	# Encoding
	# Standalone
	$doc->version($xml->{'Version'});
	$doc->encoding($xml->{'Encoding'});
	$doc->standalone($xml->{'Standalone'});
#	$self->{'xml'} = $xml;
}

=head1 COPYRIGHT

Martin Owens, doctormo@cpan.org

=head1 SEE ALSO

L<XML::DOM2>,L<XML::SAX>

=cut
1;
