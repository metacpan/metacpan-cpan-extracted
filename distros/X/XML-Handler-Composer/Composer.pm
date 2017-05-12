package XML::Handler::Composer;
use strict;
use XML::UM;
use Carp;

use vars qw{ $VERSION %DEFAULT_QUOTES %XML_MAPPING_CRITERIA };

$VERSION = '0.01';

%DEFAULT_QUOTES = (
		   XMLDecl => '"', 
		   Attr => '"',
		   Entity => '"',
		   SystemLiteral => '"',
		  );

%XML_MAPPING_CRITERIA = 
(
 Text => 
 {
   '<' => '&lt;',
   '&' => '&amp;',

   ']]>' => ']]&gt;',
 },

 CDataSection => 
 {
   ']]>' => ']]&gt;',	# NOTE: this won't be translated back correctly
 },

 Attr =>	# attribute value (assuming double quotes "" are used)
 {
#   '"' => '&quot;',	# Use ("'" => '&apos;') when using single quotes
   '<' => '&lt;',
   '&' => '&amp;',
 },

 Entity =>	# entity value (assuming double quotes "" are used)
 {
#   '"' => '&quot;',	# Use ("'" => '&apos;') when using single quotes
   '%' => '&#37;',
   '&' => '&amp;',
 },

 Comment => 
 {
   '--' => '&#45;&#45;',	# NOTE: this won't be translated back correctly
 },

 ProcessingInstruction =>
 {
   '?>' => '?&gt;',	# not sure if this will be translated back correctly
 },

 # The SYSTEM and PUBLIC identifiers in DOCTYPE declaration (quoted strings)
 SystemLiteral => 
 {
#   '"' => '&quot;',	# Use ("'" => '&apos;') when using single quotes
 },

);

sub new
{
    my ($class, %options) = @_;
    my $self = bless \%options, $class;

    $self->{EndWithNewline} = 1 unless defined $self->{EndWithNewline};

    if (defined $self->{Newline})
    {
	$self->{ConvertNewlines} = 1;
    }
    else
    {
	# Use this when printing newlines in case the user didn't specify one
	$self->{Newline} = "\x0A";
    }

    $self->{DocTypeIndent}  = $self->{Newline} . "  " 
	unless defined $self->{DocTypeIndent};

    $self->{IndentAttlist}  = "        " unless defined $self->{IndentAttlist};

    $self->{Print}	    = sub { print @_ } unless defined $self->{Print};

    $self->{Quote} ||= {};
    for my $q (keys %DEFAULT_QUOTES)
    {
	$self->{Quote}->{$q} ||= $DEFAULT_QUOTES{$q};
    }

    # Convert to UTF-8 by default, i.e. when <?xml encoding=...?> is missing 
    # and no {Encoding} is specified.
    # Note that the internal representation *is* UTF-8, so we
    # simply return the (string) parameter.
    $self->{Encode} = sub { shift } unless defined $self->{Encode};

    # Convert unmapped characters to hexadecimal constants a la '&#x53F7;'
    $self->{EncodeUnmapped} = \&XML::UM::encode_unmapped_hex
	unless defined $self->{EncodeUnmapped};

    my $encoding = $self->{Encoding};
    $self->setEncoding ($encoding) if defined $encoding;

    $self->initMappers;

    $self;
}

#
# Setup the mapping routines that convert '<' to '&lt;' etc.
# for the specific XML constructs.
#
sub initMappers
{
    my $self = shift;
    my %escape;
    my $convert_newlines = $self->{ConvertNewlines};

    for my $n (qw{ Text Comment CDataSection Attr SystemLiteral
		   ProcessingInstruction Entity })
    {
	$escape{$n} = $self->create_utf8_mapper ($n, $convert_newlines);
    }

    # Text with xml:space="preserve", should not have newlines converted.
    $escape{TextPreserveNL} = $self->create_utf8_mapper ('Text', 0);
    # (If newline conversion is inactive, $escape{TextPreserveNL} does the 
    # same as $escape{Text} defined above ...)

    $self->{Escape} = \%escape;
}

sub setEncoding
{
    my ($self, $encoding) = @_;

    $self->{Encode} = XML::UM::get_encode (
	Encoding => $encoding, EncodeUnmapped => $self->{EncodeUnmapped});
}

sub create_utf8_mapper
{
    my ($self, $construct, $convert_newlines) = @_;

    my $c = $XML_MAPPING_CRITERIA{$construct};
    croak "no XML mapping criteria defined for $construct" 
           unless defined $c;

    my %hash = %$c;

    # If this construct appears between quotes in the XML document
    # (and it has a quoting character defined), 
    # ensure that the quoting character is appropriately converted
    # to &quot; or &apos;
    my $quote = $self->{Quote}->{$construct};
    if (defined $quote)
    {
	$hash{$quote} = $quote eq '"' ? '&quot;' : '&apos;';
    }

    if ($convert_newlines)
    {
	$hash{"\x0A"} = $self->{Newline};
    }

    gen_utf8_subst (%hash);
}

#
# Converts a string literal e.g. "ABC" into '\x41\x42\x43'
# so it can be stuffed into a regular expression
#
sub str_to_hex		# static
{
    my $s = shift;

    $s =~ s/(.)/ sprintf ("\\x%02x", ord ($1)) /egos;

    $s;
}

#
# In later perl versions (5.005_55 and up) we can simply say:
#
# use utf8;
# $literals = join ("|", map { str_to_hex ($_) } keys %hash);
# $s =~ s/($literals)/$hash{$1}/ego;
#

sub gen_utf8_subst	# static
{
    my (%hash) = @_;

    my $code = 'sub { my $s = shift; $s =~ s/(';
    $code .= join ("|", map { str_to_hex ($_) } keys %hash);
    $code .= ')|(';
    $code .= '[\\x00-\\xBF]|[\\xC0-\\xDF].|[\\xE0-\\xEF]..|[\\xF0-\\xFF]...';
    $code .= ')/ defined ($1) ? $hash{$1} : $2 /ego; $s }';

    my $f = eval $code;
    croak "XML::Handler::Composer - can't eval code: $code\nReason: $@" if $@;

    $f;
}

# This should be optimized!
sub print
{
    my ($self, $str) = @_;
    $self->{Print}->($self->{Encode}->($str));
}

# Used by start_element. It determines the style in which empty elements
# are printed. The default implementation returns "/>" so they are printed
# like this: <a/>
# Override this method to support e.g. XHTML style tags. 
sub get_compressed_element_suffix
{
    my ($self, $event) = @_;

    "/>";

    # return " />" for XHTML style, or
    # "><$tagName/>" for uncompressed tags (where $tagName is $event->{Name})
}

#----- PerlSAX handlers -------------------------------------------------------

sub start_document
{
    my ($self) = @_;

    $self->{InCDATA} = 0;
    $self->{DTD} = undef;
    $self->{PreserveWS} = 0;	# root element has xml:space="default"
    $self->{PreserveStack} = [];
    $self->{PrintedXmlDecl} = 0;	# whether <?xml ...?> was printed
}

sub end_document
{
    my ($self) = @_;

    # Print final Newline at the end of the XML document (if desired)
    $self->print ($self->{Newline}) if $self->{EndWithNewline};
}

# This event is received *AFTER* the Notation, Element, Attlist etc. events 
# that are contained within the DTD.
sub doctype_decl
{
    my ($self, $event) = @_;
    $self->flush_xml_decl;

    my $q = $self->{Quote}->{SystemLiteral};
    my $escape_literal = $self->{Escape}->{SystemLiteral};

    my $name = $event->{Name};
    my $sysId = $event->{SystemId};
    $sysId = &$escape_literal ($sysId) if defined $sysId;
    my $pubId = $event->{PublicId};
    $pubId = &$escape_literal ($pubId) if defined $pubId;

    my $str = "<!DOCTYPE $name";
    if (defined $pubId)
    {
	$str .= " PUBLIC $q$pubId$q $q$sysId$q";
    }
    elsif (defined $sysId)
    {
	$str .= " SYSTEM $q$sysId$q";
    }

    my $dtd_contents = $self->{DTD};
    my $nl = $self->{Newline};
    
    if (defined $dtd_contents)
    {
	delete $self->{DTD};
	
	$str .= " [$dtd_contents$nl]>$nl";
    }
    else
    {
	$str .= ">$nl";
    }
    $self->print ($str);
}

sub start_element
{
    my ($self, $event) = @_;

    my $preserve_stack = $self->{PreserveStack};
    if (@$preserve_stack == 0)
    {
	# This is the root element. Print the <?xml ...?> declaration now if
	# it wasn't printed and it should be.
	$self->flush_xml_decl;
    }

    my $str = "<" . $event->{Name};

    my $suffix = ">";
    if ($event->{Compress})
    {
	$suffix = $self->get_compressed_element_suffix ($event);
    }

    # Push PreserveWS state of parent element on the stack
    push @{ $preserve_stack }, $self->{PreserveWS};
    $self->{PreserveWS} = $event->{PreserveWS};

    my $ha = $event->{Attributes};
    my @attr;
    if (exists $event->{AttributeOrder})
    {
	my $defaulted = $event->{Defaulted};
	if (defined $defaulted && !$self->{PrintDefaultAttr})
	{
	    if ($defaulted > 0)
	    {
		@attr = @{ $event->{AttributeOrder} }[0 .. $defaulted - 1];
	    }
	    # else: all attributes are defaulted i.e. @attr = ();
	}
	else	# no attr are defaulted
	{
	    @attr = @{ $event->{AttributeOrder} };
	}
    }
    else	# no attr order defined
    {
	@attr = keys %$ha;
    }

    my $escape = $self->{Escape}->{Attr};
    my $q = $self->{Quote}->{Attr};

    for (my $i = 0; $i < @attr; $i++)
    {
#?? could print a newline every so often...
	my $name = $attr[$i];
	my $val = &$escape ($ha->{$name});
	$str .= " $name=$q$val$q";
    }
    $str .= $suffix;

    $self->print ($str);
}

sub end_element
{
    my ($self, $event) = @_;

    $self->{PreserveWS} = pop @{ $self->{PreserveStack} };

    return if $event->{Compress};

    $self->print ("</" . $event->{Name} . ">");
}

sub characters
{
    my ($self, $event) = @_;

    if ($self->{InCDATA})
    {
#?? should this use $self->{PreserveWS} ?

	my $esc = $self->{Escape}->{CDataSection};
	$self->print (&$esc ($event->{Data}));
    }
    else # regular text
    {
	my $esc = $self->{PreserveWS} ? 
	    $self->{Escape}->{TextPreserveNL} :
	    $self->{Escape}->{Text};

	$self->print (&$esc ($event->{Data}));
    }
}

sub start_cdata
{
    my $self = shift;
    $self->{InCDATA} = 1;

    $self->print ("<![CDATA[");
}

sub end_cdata
{
    my $self = shift;
    $self->{InCDATA} = 0;

    $self->print ("]]>");
}

sub comment
{
    my ($self, $event) = @_;
    $self->flush_xml_decl;

    my $esc = $self->{Escape}->{Comment};
#?? still need to support comments in the DTD

    $self->print ("<!--" . &$esc ($event->{Data}) . "-->");
}

sub entity_reference
{
    my ($self, $event) = @_;
    $self->flush_xml_decl;

    my $par = $event->{Parameter} ? '%' : '&';
#?? parameter entities (like %par;) are NOT supported!
# PerlSAX::handle_default should be fixed!

    $self->print ($par . $event->{Name} . ";");
}

sub unparsed_entity_decl
{
    my ($self, $event) = @_;
    $self->flush_xml_decl;

    $self->entity_decl ($event);
}

sub notation_decl
{
    my ($self, $event) = @_;
    $self->flush_xml_decl;

    my $name = $event->{Name};
    my $sysId = $event->{SystemId};
    my $pubId = $event->{PublicId};

    my $q = $self->{Quote}->{SystemLiteral};
    my $escape = $self->{Escape}->{SystemLiteral};

    $sysId = &$escape ($sysId) if defined $sysId;
    $pubId = &$escape ($pubId) if defined $pubId;

    my $str = $self->{DocTypeIndent} . "<!NOTATION $name";

    if (defined $pubId)
    {
	$str .= " PUBLIC $q$pubId$q";	
    }
    if (defined $sysId)
    {
	$str .= " SYSTEM $q$sysId$q";	
    }
    $str .= ">";

    $self->{DTD} .= $str;
}

sub element_decl
{
    my ($self, $event) = @_;
    $self->flush_xml_decl;

    my $name = $event->{Name};
    my $model = $event->{Model};

    $self->{DTD} .= $self->{DocTypeIndent} . "<!ELEMENT $name $model>";
}

sub entity_decl
{
    my ($self, $event) = @_;
    $self->flush_xml_decl;

    my $name = $event->{Name};

    my $par = "";
    if ($name =~ /^%/)
    {
	# It's a parameter entity (i.e. %ent; instead of &ent;)
	$name = substr ($name, 1);
	$par = "% ";
    }

    my $str = $self->{DocTypeIndent} . "<!ENTITY $par$name";

    my $value = $event->{Value};
    my $sysId = $event->{SysId};
    my $pubId = $event->{PubId};
    my $ndata = $event->{Ndata};

    my $q = $self->{Quote}->{SystemLiteral};
    my $escape = $self->{Escape}->{SystemLiteral};

    if (defined $value)
    {
#?? use {Entity} quote etc...
	my $esc = $self->{Escape}->{Entity};
	my $p = $self->{Quote}->{Entity};
	$str .= " $p" . &$esc ($value) . $p;
    }
    if (defined $pubId)
    {
	$str .= " PUBLIC $q" . &$escape ($pubId) . $q;	
    }
    elsif (defined $sysId)
    {
	$str .= " SYSTEM";
    }

    if (defined $sysId)
    {
	$str .= " $q" . &$escape ($sysId) . $q;
    }
    $str .= " NDATA $ndata" if defined $ndata;
    $str .= ">";

    $self->{DTD} .= $str;
}

sub attlist_decl
{
    my ($self, $event) = @_;
    $self->flush_xml_decl;

    my $elem = $event->{ElementName};

    my $str = $event->{AttributeName} . " " . $event->{Type};    
    $str .= " #FIXED" if defined $event->{Fixed};

    $str = $str;

    my $def = $event->{Default};
    if (defined $def)
    {
	$str .= " $def";
	
	# Note sometimes Default is a value with quotes.
	# We'll use the existing quotes in that case...
    }

    my $indent;
    if (!exists($event->{First}) || $event->{First})
    {
	$self->{DTD} .= $self->{DocTypeIndent} . "<!ATTLIST $elem";

	if ($event->{MoreFollow})
	{
	    $indent = $self->{Newline} . $self->{IndentAttlist};
	}
	else
	{
	    $indent = " ";
	}
    }
    else
    {
	$indent = $self->{Newline} . $self->{IndentAttlist};
    }

    $self->{DTD} .= $indent . $str;

    unless ($event->{MoreFollow})
    {
	$self->{DTD} .= '>';
    }
}

sub xml_decl
{
    my ($self, $event) = @_;
    return if $self->{PrintedXmlDecl};	# already printed it

    my $version = $event->{Version};
    my $encoding = $event->{Encoding};
    if (defined $self->{Encoding})
    {
	$encoding = $self->{Encoding};
    }
    else
    {
	$self->setEncoding ($encoding) if defined $encoding;
    }

    my $standalone = $event->{Standalone};
    $standalone = ($standalone ? "yes" : "no") if defined $standalone;

    my $q = $self->{Quote}->{XMLDecl};
    my $nl = $self->{Newline};

    my $str = "<?xml";
    $str .= " version=$q$version$q"	  if defined $version;    
    $str .= " encoding=$q$encoding$q"	  if defined $encoding;
    $str .= " standalone=$q$standalone$q" if defined $standalone;
    $str .= "?>$nl$nl";

    $self->print ($str);
    $self->{PrintedXmlDecl} = 1;
}

#
# Prints the <xml ...?> declaration if it wasn't already printed
# *and* the user wanted it to be printed (because s/he set $self->{Encoding})
#
sub flush_xml_decl
{
    my ($self) = @_;
    return if $self->{PrintedXmlDecl};

    if (defined $self->{Encoding})
    {
	$self->xml_decl ({ Version => '1.0', Encoding => $self->{Encoding} });
    }

    # If it wasn't printed just now, it doesn't need to be printed at all,
    # so pretend we did print it.
    $self->{PrintedXmlDecl} = 1;
}

sub processing_instruction
{
    my ($self, $event) = @_;
    $self->flush_xml_decl;

    my $escape = $self->{Escape}->{ProcessingInstruction};

    my $str = "<?" . $event->{Target} . " " . 
		&$escape ($event->{Data}). "?>";

    $self->print ($str);
}

1; # package return code

__END__

=head1 NAME

XML::Handler::Composer - Another XML printer/writer/generator

=head1 SYNOPSIS

use XML::Handler::Composer;

my $composer = new XML::Handler::Composer ( [OPTIONS] );

=head1 DESCRIPTION

XML::Handler::Composer is similar to XML::Writer, XML::Handler::XMLWriter,
XML::Handler::YAWriter etc. in that it generates XML output.

This implementation may not be fast and it may not be the best solution for
your particular problem, but it has some features that may be missing in the
other implementations:

=over 4

=item * Supports every output encoding that L<XML::UM> supports

L<XML::UM> supports every encoding for which there is a mapping file 
in the L<XML::Encoding> distribution.

=item * Pretty printing

When used with L<XML::Filter::Reindent>.

=item * Fine control over which kind of quotes are used

See options below.

=item * Supports PerlSAX interface

=back

=head1 Constructor Options

=over 4

=item * EndWithNewline (Default: 1)

Whether to print a newline at the end of the file (i.e. after the root element)

=item * Newline (Default: undef)

If defined, which newline to use for printing.
(Note that XML::Parser etc. convert newlines into "\x0A".)

If undef, newlines will not be converted and XML::Handler::Composer will
use "\x0A" when printing.

A value of "\n" will convert the internal newlines into the platform
specific line separator.

See the PreserveWS option in the characters event (below) for finer control
over when newline conversion is active.

=item * DocTypeIndent (Default: a Newline and 2 spaces)

Newline plus indent that is used to separate lines inside the DTD.

=item * IndentAttList (Default: 8 spaces)

Indent used when printing an <!ATTLIST> declaration that has more than one
attribute definition, e.g.

 <!ATTLIST my_elem
        attr1 CDATA "foo"
        attr2 CDATA "bar"
 >

=item * Quote (Default: { XMLDecl => '"', Attr => '"', Entity => '"', SystemLiteral => '"' })

Quote contains a reference to a hash that defines which quoting characters 
to use when printing XML declarations (XMLDecl), attribute values (Attr), 
<!ENTITY> values (Entity) and system/public literals (SystemLiteral) 
as found in <!DOCTYPE>, <!ENTITY> declarations etc.

=item * PrintDefaultAttr (Default: 0)

If 1, prints attribute values regardless of whether they are default 
attribute values (as defined in <!ATTLIST> declarations.)
Normally, default attributes are not printed.

=item * Encoding (Default: undef)

Defines the output encoding (if specified.) 
Note that future calls to the xml_decl() handler may override this setting
(if they contain an Encoding definition.)

=item * EncodeUnmapped (Default: \&XML::UM::encode_unmapped_dec)

Defines how Unicode characters not found in the mapping file (of the 
specified encoding) are printed. 
By default, they are converted to decimal entity references, like '&#123;'

Use \&XML::UM::encode_unmapped_hex for hexadecimal constants, like '&#xAB;'

=item * Print (Default: sub { print @_ }, which prints to stdout)

The subroutine that is used to print the encoded XML output.
The default prints the string to stdout.

=back

=head1 Method: get_compressed_element_suffix ($event)

Override this method to support the different styles for printing
empty elements in compressed notation, e.g. <p/>, <p></p>, <p />, <p>.

The default returns "/>", which results in <p/>.
Use " />" for XHTML style elements or ">" for certain HTML style elements.

The $event parameter is the hash reference that was received from the
start_element() handler.

=head1 Extra PerlSAX event information

XML::Handler::Composer relies on hints from previous SAX filters to
format certain parts of the XML. 
These SAX filters (e.g. XML::Filter::Reindent) pass extra information by adding
name/value pairs to the appropriate PerlSAX events (the events themselves are 
hash references.)

=over 4

=item * entity_reference: Parameter => 1

If Parameter is 1, it means that it is a parameter entity reference. 
A parameter entity is referenced with %ent; instead of &ent; and the
entity declaration starts with <!ENTITY % ent ...> instead of <!ENTITY ent ...>

NOTE: This should be added to the PerlSAX interface!

=item * start_element/end_element: Compress => 1

If Compress is 1 in both the start_element and end_element event, the element
will be printed in compressed form, e.g. <a/> instead of <a></a>.

=item * start_element: PreserveWS => 1

If newline conversion is active (i.e. Newline was defined in the constructor),
then newlines will *NOT* be converted in text (character events) within this
element.

=item * attlist_decl: First, MoreFollow

The First and MoreFollow options can be used to force successive <!ATTLIST>
declarations for the same element to be merged, e.g.

 <!ATTLIST my_elem
        attr1 CDATA "foo"
        attr2 CDATA "bar"
        attr3 CDATA "quux"
 >

In this example, the attlist_decl event for foo should contain
(First => 1, MoreFollow => 1) and the event for bar should contain 
(MoreFollow => 1). The quux event should have no extra info.

'First' indicates that the event is the first of a sequence.
'MoreFollow' indicates that more events will follow in this sequence.

If neither option is set by the preceding PerlSAX filter, each attribute
definition will be printed as a separate <!ATTLIST> line.

=back

=head1 CAVEATS

This code is highly experimental! 
It has not been tested well and the API may change.

=head1 AUTHOR

Enno Derksen is the original author.

Send bug reports, hints, tips, suggestions to T.J. Mather at
<F<tjmather@tjmather.com>>. 

=cut
