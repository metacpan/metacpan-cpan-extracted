#
# Usage:
# 
#	$dom_sax = new XML::DOM::PerlSax (KeepCDATA => 1);
#	$parser = new XML::Parser::PerlSAX (Handler => $dom_sax);
#	$parser->parse ($file);
#	$dom_doc = $dom_sax->document;

# TODO:
# - add support for defaulted attributes
# - add support for parameter entity references
# - expand API: insert Elements in the tree or stuff into DocType etc.

package XML::DOM::PerlSAX;
use strict;
use XML::DOM;

# Options:
# - KeepCDATA => 1 (if 0, CDATA is treated as regular text)
# - Document => $doc (if undef, start_document will extract it from Element or 
#		      DocType (if set) or a new XML::DOM::Document)
# - Element => $elem (if undef, it's set to Document (i.e. parent))
# - DocType => $doctype (if undef, start_document will extract it from
#			 Document or create a new XML::DOM::DocumentType in it)

sub new
{
    my ($class, %args) = @_;
    bless $class, \%args;
}

# Set/Get Document
sub document
{
    (@_ == 1) ? $_[0]->{Document} : ($_[0]->{Document} = $_[1]);
}
#?? InCDATA, LastText etc. should be re-initialized (or not?)

#-------- PerlSAX Handler methods ------------------------------

sub start_document # was Init
{
    # Define Document if it's not set & not obtainable from Element or DocType
    $self->{Document} ||= 
	(defined $self->{Element} ? $self->{Element}->getOwnerDocument : undef)
     || (defined $self->{DocType} ? $self->{DocType}->getOwnerDocument : undef)
     || new XML::DOM::Document();

    $self->{Element} ||= $self->{Document};

    unless (defined $self->{DocType})
    {
	$self->{DocType} = $self->{Document}->getDocType
	    if defined $self->{Document};

	unless (defined $self->{Doctype})
	{
#?? should be $doc->createDocType for expandability!
	    $self->{DocType} = new XML::DOM::DocumentType ($self->{Document});
	    $self->{Document}->setDoctype ($self->{DocType});
	}
    }
  
    # Prepare for document prolog
    $self->{InProlog} = 1;

    # We haven't passed the root element yet
    $self->{EndDoc} = 0;

    undef $self->{LastText};
}

sub end_document # was Final
{
    unless ($self->{SawDocType})
    {
	my $doctype = $self->{Document}->removeDoctype;
	$doctype->dispose;
#?? do we really want to destroy the Doctype?
    }
    $self->{Document};
}

sub characters # was Char
{
    my $str = $_[1]->{Data};

    if ($self->{InCDATA} && $self->{KeepCDATA})
    {
	undef $self->{LastText};
	# Merge text with previous node if possible
	$self->{Element}->addCDATA ($str);
    }
    else
    {
	# Merge text with previous node if possible
	# Used to be:	$expat->{DOM_Element}->addText ($str);
	if ($self->{LastText})
	{
	    $self->{LastText}->{Data} .= $str;
	}
	else
	{
	    $self->{LastText} = $self->{Document}->createTextNode ($str);
	    $self->{LastText}->{Parent} = $self->{Element};
	    push @{$self->{Element}->{C}}, $self->{LastText};
	}
    }
}

sub start_element # was Start
{
    my ($self, $hash) = @_;
    my $elem = $hash->{Name};
    my @attr = @{ $hash->{Attributes} };

    my $parent = $self->{Element};
    my $doc = $self->{Document};
    
    if ($parent == $doc)
    {
	# End of document prolog, i.e. start of first Element
	$self->{InProlog} = 0;
    }
    
    undef $self->{LastText};
    my $node = $doc->createElement ($elem);
    $self->{Element} = $node;
    $parent->appendChild ($node);
    
    my $i = 0;
    my $n = @attr;

# was:    my $first_default = $expat->specified_attr;
    my $first_default = $n;
#?? fix this when PerlSAX interface supports defaulted attributes

    while ($i < $n)
    {
	my $specified = $i < $first_default;
	my $name = $attr[$i++];
	undef $self->{LastText};
	my $attr = $doc->createAttribute ($name, $attr[$i++], $specified);
	$node->setAttributeNode ($attr);
    }
}

sub end_document
{
    $self->{Element} = $self->{Element}->{Parent};
    undef $self->{LastText};

    # Check for end of root element
    $self->{EndDoc} = 1 if ($self->{Element} == $self->{Document});
}

sub entity_reference # was Default
{
    my $name = $_[1]->{Name};
    
    $self->{Element}->appendChild (
			    $self->{Document}->createEntityReference ($name));
    undef $self->{LastText};
}

sub start_cdata
{
    $self->{InCDATA} = 1;
}

sub end_cdata
{
    $self->{InCDATA} = 0;
}

sub comment
{
    undef $self->{LastText};
    my $comment = $self->{Document}->createComment ($_[1]->{Data});
    $self->{Element}->appendChild ($comment);
}

sub doctype_decl
{
    my ($self, $hash) = @_;

    $self->{DocType}->setParams ($hash->{Name}, $hash->{SystemId}, 
				 $hash->{PublicId}, $hash->{Internal});
    $self->{SawDocType} = 1;
}

sub attlist_decl
{
    my $hash = $_[1];
    $self->{DocType}->addAttDef ($hash->{EntityName},
				 $hash->{AttributeName},
				 $hash->{Type},
				 $hash->{Default},
				 $hash->{Fixed});
}

sub xml_decl
{
    my ($self, $hash) = @_;

    undef $self->{LastText};
    $self->{Document}->setXMLDecl (new XML::DOM::XMLDecl ($self->{Document}, 
							  $hash->{Version},
							  $hash->{Encoding},
							  $hash->{Standalone}));
}

sub entity_decl
{
    my ($self, $hash) = @_;
    
    # Parameter Entities names are passed starting with '%'
    my $parameter = 0;

#?? parameter entities currently not supported by PerlSAX!

    undef $self->{LastText};
    $self->{DocType}->addEntity ($parameter, $hash->{Name}, $hash->{Value}, 
				 $hash->{SystemId}, $hash->{PublicId}, 
				 $hash->{Notation});
}

# Unparsed is called when it encounters e.g:
#
#   <!ENTITY logo SYSTEM "http://server/logo.gif" NDATA gif>
#
sub unparsed_decl
{
    my ($self, $hash) = @_;

    # same as regular ENTITY, as far as DOM is concerned
    $self->entity_decl ($hash);
}

sub element_decl
{
    my ($self, $hash) = $_;

    undef $self->{LastText};
    $self->{DocType}->addElementDecl ($hash->{Name}, $hash->{Model});
}

sub notation_decl
{
    my ($self, $hash) = @_;

    undef $self->{LastText};
    $self->{DocType}->addNotation ($hash->{Name}, $hash->{Base}, 
				   $hash->{SystemId}, $hash->{PublicId});
}

sub processing_instruction
{
    my ($self, $hash) = @_;

    undef $self->{LastText};
    $self->{Element}->appendChild (new XML::DOM::ProcessingInstruction 
			    ($self->{Document}, $hash->{Target}, $hash->{Data}));
}

return 1;

__END__

=head1 NAME

XML::DOM::PerlSAX - PerlSAX handler that creates XML::DOM document structures

=head1 SYNOPSIS

 use XML::DOM::PerlSAX;
 use XML::Parser::PerlSAX;

 my $handler = new XML::DOM::PerlSAX (KeepCDATA => 1);
 my $parser = new XML::Parser::PerlSAX (Handler => $handler);

 my $doc = $parser->parsefile ("file.xml");

=head1 DESCRIPTION

XML::DOM::PerlSAX creates L<XML::DOM> document structures 
(i.e. L<XML::DOM::Document>) from PerlSAX events.

=head2 CONSTRUCTOR OPTIONS

The XML::DOM::PerlSAX constructor supports the following options:

=over 4

=item * KeepCDATA => 1 

If set to 0 (default), CDATASections will be converted to regular text.

=item * Document => $doc

If undefined, start_document will extract it from Element or DocType (if set),
otherwise it will create a new XML::DOM::Document.

=item * Element => $elem

If undefined, it is set to Document. This will be the insertion point (or parent)
for the nodes defined by the following callbacks.

=item * DocType => $doctype

If undefined, start_document will extract it from Document (if possible).
Otherwise it adds a new XML::DOM::DocumentType to the Document.

=back
