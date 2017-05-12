package XML::Writer::Lazy;

=head1 NAME

XML::Writer::Lazy - Pass stringified XML to XML::Writer

=head1 DESCRIPTION

Pass stringified XML to XML::Writer

=head1 SYNOPSIS

    my $writer = XML::Writer::Lazy->new( OUTPUT => 'self');
    my $title  = "My Title!";

    $writer->lazily(<<"XML");
        <html>
            <head>
                <title>$title</title>
        </head>
        <body>
            <p>Pipe in literal XML</p>
    XML

    $writer->startTag( "p", "class" => "simple" );
    $writer->characters("Alongside the usual interface");
    $writer->characters("123456789");
    $writer->lazily("</p></body></html>");

=head1 WHY

This is 2016. The computer should do the hard work. Life's too short to write
a bunch of C<startTag> and C<endTag> when my computer's perfectly capable of
figuring out the right thing to do if I give it a chunk of XML.

=head1 HOW

Using a SAX parser whose events are then passed back to XML::Writer.

=head1 METHODS

B<This is a subclass of> L<XML::Writer>.

=cut

use strict;
use warnings;
use base 'XML::Writer';
use XML::SAX;

#
# The SAX ChunkParser's input, and XML::Writer's output need to be kept in
# sync, because the ChunkParser still expects well-formed XML eventually.
#
# So that means there are two main modes here:
#   - When `lazily` is being used, SAX ChunkParser is being used explicitly to
#     drive XML::Writer, and this keeps it in sync
#   - When XML::Writer's methods are being used directly, we intercept calls
#     to `print`, and add that to a buffer that's fed to the ChunkParser each
#     time before it's used again
#

my $KEY = '_XML_Writer_Lazy_Parser';

=head2 new

Call's L<XML::Writer>'s C<new()> and then instantiates the lazy
parser pieces. Accepts all the same arguments as the parent method.

=cut

sub new {
    my $classname = shift;
    my $self      = $classname->SUPER::new(@_);

    # Create the parser
    my $parser;
    {
        local $XML::SAX::ParserPackage = 'XML::LibXML::SAX::ChunkParser';
        $parser = XML::SAX::ParserFactory->parser(
            Handler => XML::Writer::Lazy::Handler->new );
    }

    # And the buffer...
    my $buffer = '';

    # Save them both in the parent object
    $self->{$KEY} = {
        parser => $parser,
        buffer => $buffer,
    };

    # Capture anything print()'ed via XML::Writer
    $self->wrap_output();
    return $self;
}

my $null_handler = bless {}, 'XML::Writer::Lazy::NullHandler';

=head2 lazily

Take a string of XML. It should be parseable, although doesn't need to be
balanced. C<< <foo><bar>asdf >> is fine, where C<< <foo >> is not. Exercises
the XML::Writer methods appropriately to re-create whatever you'd passed in.

=cut

sub lazily {
    my ( $self, $string, $writer ) = @_;

    # Set the writer object that the Handler is using
    local $XML::Writer::Lazy::Handler::writer
        = ( defined $writer ) ? $writer : $self;

    # Whether or not we might be trying to print an XML dec
    local $XML::Writer::Lazy::Handler::xml_dec
        = ( $string =~ m/^(\xEF\xBB\xBF)?<\?xml/i );

    # First thing we do is look at anything that was output directly by
    # XML::Writer, and pass that to the Chunk Parser
    if ( length $self->{$KEY}->{'buffer'} ) {

        # Save a copy of the buffer, and then nuke the buffer
        my $directly = $self->{$KEY}->{'buffer'};
        $self->{$KEY}->{'buffer'} = '';

        # Re-enter this sub with the buffer as the argument
        $self->lazily( $directly, $null_handler );
    }

    {
        # Turn off buffer collection
        local $XML::Writer::Lazy::InterceptPrint::intercept = 0;

        # Push in the user's string
        $self->{$KEY}->{'parser'}->parse_chunk($string);

        # Flush using a comment
        local $XML::Writer::Lazy::Handler::writer = $null_handler;
        $self->{$KEY}->{'parser'}->parse_chunk("<!-- -->");
    }

    return $self;
}

=head2 wrap_output

Only important if you're doing strange things with the C<OUTPUT> after
instantiation. In order to keep track of what's been written already, this
class wraps the C<OUTPUT> object inside a delegate that intercepts and stores
the contents of C<print>. If you -- post instantiation -- replace the output
object, you can call this method to rewrap it. It will change the class that
that object belongs to.

=cut

sub wrap_output {
    my $self = shift;
    $self->setOutput(
        XML::Writer::Lazy::InterceptPrint->___wrap(
            $self->getOutput(), $self
        )
    );

    return $self;
}

=head1 AUTHOR

Peter Sergeant - C<pete@clueball.com>

L<https://github.com/pjlsergeant/p5-xml-writer-lazy>

=head1 LICENSE

MIT - see the C<LICENSE> file included in the tar.gz of this distribution.

=cut

# I capture output that's produced by calling XML::Writer's methods directly
package XML::Writer::Lazy::InterceptPrint;
our $intercept = 1;

use vars '$AUTOLOAD';
use Scalar::Util qw/weaken/;

sub ___wrap {
    my ( $classname, $delegate, $me ) = @_;
    weaken $delegate;
    weaken $me;
    return bless [ $delegate, $me ], $classname;
}

sub AUTOLOAD {
    my $self = shift;

    my ($sub) = $AUTOLOAD =~ /.*::(.*?)$/;
    return if $sub eq "DESTROY";

    # The object we'll be executing against
    my $wraps = $self->[0];

    # Get a reference to the original
    my $ref = $wraps->can($sub);

    # Do something clever with print
    if ( $sub eq 'print' ) {
        if ($intercept) {
            $self->[1]->{$KEY}->{'buffer'} .= join '', @_;
        }
    }

    # Add the wrapped object to the front of @_
    unshift( @_, $wraps );

    # Redispatch; goto replaces the current stack frame, so it's like
    # we were never here...
    goto &$ref;
}

# I'm the handling class the SAX parser calls when events are generated
package XML::Writer::Lazy::Handler;
our $writer;
our $xml_dec = 0;

use base qw(XML::SAX::Base);
use Carp qw/croak/;

# This gets run for the first chunk
sub xml_decl {
    my ( $self, $element ) = @_;
    return unless $xml_dec;
    $writer->xmlDecl(
          ( defined $element->{'Encoding'} )
        ? ( $element->{'Encoding'} )
        : ()
    );
    return;
}

sub start_element {
    my ( $self, $element ) = @_;
    my %attributes = %{ $element->{'Attributes'} };
    my @attributes;
    for my $attr ( keys %attributes ) {
        if ( ref( $attributes{$attr} ) eq 'HASH' ) {
            my $data = $attributes{$attr};
            push( @attributes, [ $data->{'Name'}, $data->{'Value'} ] );
        }
        else {
            push( @attributes, [ $attr, $attributes{$attr} ] );
        }
    }

    @attributes = map {@$_} sort { $a->[0] cmp $b->[0] } @attributes;
    $writer->startTag( $element->{'Name'}, @attributes );
    return;
}

sub end_element {
    my ( $self, $element ) = @_;
    $writer->endTag( $element->{'Name'} );
    return;
}

sub characters {
    my ( $self, $characters ) = @_;
    $writer->characters( $characters->{'Data'} );
    return;
}

sub processing_instruction {
    my ( $self, $pi ) = @_;
    $writer->pi( $pi->{'Target'}, $pi->{'Data'} );
    return;
}

sub comment {
    my ( $self, $comment ) = @_;
    $comment->{'Data'} ||= '';
    $comment->{'Data'} =~ s/^ //;
    $comment->{'Data'} =~ s/ $//;
    $writer->comment( $comment->{'Data'} );
    return;
}

sub start_dtd {
    my ( $self, $dtd ) = @_;
    $writer->doctype( $dtd->{'Name'}, $dtd->{'PublicId'},
        $dtd->{'SystemId'} );
    return;
}

sub start_prefix_mapping {
    my ( $self, $prefix_mapping ) = @_;
    $writer->addPrefix( $prefix_mapping->{'NamespaceURI'},
        $prefix_mapping->{'Prefix'} );
    return;
}

# No work needed, as the insides will already be magically quoted
sub start_cdata { return; }
sub end_cdata   { return; }

sub not_implemented {
    my ($event) = @_;
    return <<"MSG";
The XML passed to 'lazily()' triggered a `$event` SAX event,
but XML::Writer::Lazy doesn't yet handle those. You can either simplify your
input XML or alternatively you could monkey-patch `XML::Writer::Lazy::Handler`
to add a `$event()` handler method to it.
MSG
}

sub set_document_locator {
    my $self = shift;
    my $data = shift;
    return croak( not_implemented('set_document_locator') );
}

sub skipped_entity {
    my $self = shift;
    my $data = shift;
    return croak( not_implemented('skipped_entity') );
}

sub entity_reference {
    my $self = shift;
    my $data = shift;
    return croak( not_implemented('entity_reference') );
}

sub notation_decl {
    my $self = shift;
    my $data = shift;
    return croak( not_implemented('notation_decl') );
}

sub unparsed_entity_decl {
    my $self = shift;
    my $data = shift;
    return croak( not_implemented('unparsed_entity_decl') );
}

sub element_decl {
    my $self = shift;
    my $data = shift;
    return croak( not_implemented('element_decl') );
}

sub attlist_decl {
    my $self = shift;
    my $data = shift;
    return croak( not_implemented('attlist_decl') );
}

sub doctype_decl {
    my $self = shift;
    my $data = shift;
    return croak( not_implemented('doctype_decl') );
}

sub entity_decl {
    my $self = shift;
    my $data = shift;
    return croak( not_implemented('entity_decl') );
}

sub attribute_decl {
    my $self = shift;
    my $data = shift;
    return croak( not_implemented('attribute_decl') );
}

sub internal_entity_decl {
    my $self = shift;
    my $data = shift;
    return croak( not_implemented('internal_entity_decl') );
}

sub external_entity_decl {
    my $self = shift;
    my $data = shift;
    return croak( not_implemented('external_entity_decl') );
}

sub resolve_entity {
    my $self = shift;
    my $data = shift;
    return croak( not_implemented('resolve_entity') );
}

sub start_entity {
    my $self = shift;
    my $data = shift;
    return croak( not_implemented('start_entity') );
}

sub end_entity {
    my $self = shift;
    my $data = shift;
    return croak( not_implemented('end_entity') );
}

sub warning {
    my $self = shift;
    my $data = shift;
    return croak( not_implemented('warning') );
}

sub error {
    my $self = shift;
    my $data = shift;
    return croak( not_implemented('error') );
}

sub fatal_error {
    my $self = shift;
    my $data = shift;
    return croak( not_implemented('fatal_error') );
}

# I'm used when we feed captured output from XML::Writer to the SAX parser,
# and don't actually want to redispatch that to XML::Writer. I accept and
# silently drop all method calls.
package XML::Writer::Lazy::NullHandler;
sub AUTOLOAD { }

1;
