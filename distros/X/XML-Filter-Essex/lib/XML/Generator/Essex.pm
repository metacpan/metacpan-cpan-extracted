package XML::Generator::Essex;

$VERSION = 0.000_1;

=head1 NAME

XML::Generator::Essex - Generate XML with Essex

=head1 SYNOPSIS

    package My::Generator;

    use XML::Generator::Essex;
    @ISA = qw( XML::Generator::Essex );

    use strict;

    sub main {  # Called by XML::Generator::Essex->generate().
        my $self = shift;
    }

    ## And, to use:

    my $g = MY::Generator->new( Handler => $h );
    $g->generate( ... );

=head1 DESCRIPTION

Provides Essex output primitives like C<put()> and constructors for
essex events.

=for test_script XML-Filter-Essex.t

=cut

use XML::Essex::Constants qw( EOD );

use XML::Essex::Base ();  # Don't import things.
use XML::Essex::Model ();
use XML::SAX::Base ();

no warnings "once";

@ISA = qw( XML::Essex::Base XML::SAX::Base );

## This is duplicated in XML::Essex
@event_ctors = qw(
    characters
    chars
    end_document
    end_doc
    end_element
    end_elt
    end
    start_document
    start_doc
    start_element
    start_elt
    start
    xml_decl
);

@EXPORT = (
    qw(
        get_handler
        output_monitor
        set_handler

        put
    ),
    @event_ctors,
);

use strict;
use NEXT;
use XML::Essex::Filter::OutputMonitor;

sub _init {  ## Called by new()
    my $self = shift;

    $self->SUPER::set_handler(
        XML::Essex::Filter::OutputMonitor->new(
            Handler => $self->SUPER::get_handler
        )
    );

    $self->NEXT::_init( @_ );
}


sub reset {  ## Called by execute()
    my $self = shift;
    $self->output_monitor->reset;
    $self->NEXT::reset( @_ );
}


sub finish {  ## Called by execute()
    my $self = shift;
    my ( $ok, $x ) = @_;

    my $om = $self->output_monitor;

    unless ( $ok ) {
        if ( $x eq EOD . "\n" ) {
            return ( 1, $om->end_document_result )
                if $om->end_document_result_has_been_set;

            return ( 1, undef )
                unless $om->start_document_seen;

            my $eod = EOD;
            $x =~ s/^$eod/$eod and no result set by $self/o;
        }
        die $x;
    }

    $self->output_monitor->finish;

    die "incomplete document emitted by $self\n"
        if $om->start_document_seen && ! $om->end_document_seen;

    $self->NEXT::finish( @_ );
    return ( 1, $om->end_document_result )
        if $om->end_document_result_has_been_set;

    die "no result set by $self\n"
        if $om->start_document_seen;

    return ();
}


=head2 Methods

=over

=item put

   Example             What's emitted
   =======             ==============
   put;                ## (whatever's in $_: event, characters, etc)
   put "text<";        ## text&lt;
   put [ a => "foo" ]  ## <a>foo</a>
   put comment "foo";  ## <!--foo-->
   put $event;         ## an event (see constructors below)
   put $data;          ## Emit a data structure
   put @list;          ## Emit multiple events and / or data structures

Emits one or more data structures as XML.  Returns the result of
emitting the last event (ie the result from the next SAX processor).

Most of the things you can pass to put (strings, constructed events) are
relatively self evident.

For instance, you can pass any events you construct, so an Essex script
to make sure all character data is emitted in CDATA sections might look
like:

    get( "text()" ), put cdata $_ while 1;

A less obvious feature is that you can pass a (possibly nested) Perl
ARRAY that defines an XML tree to emit:

   put [
       root => { id => 1 },              ## HASHes contain attributes
           "root content",
           [ a => "a content" ],
           "more root content",
           [ b => { id => 2 }, "b content" ],
   ];

will emit the SAX events corresponding to the XML (whitespace added for
legibility):

    <root id="1">
      root content
      <a>a content</a>
      more root content
      <b id="2">b content</b>
    </root>

NOTE: this does not allow you to control attribute order.

By using the DOM constructors, you could also write the above as:

   put elt(
       root => { id => 1 },              ## HASHes contain attributes
           "root content",
           elt( a => "a content" ),
           "more root content",
           elt( b => { id => 2 }, "b content" ),
   ];

to emit the XML C<< <root id="1"><!--comment-->content</root> >>.

You can actually pass any blessed object to C<put()> that provides a
C<generate_SAX()> method.  This will be called with the results of
$self->get_handler() (which may be undefined) and should return
a TRUE if the handler is undefined or if no events are sent.  If any
events are sent, it should return the result of the last event.

See XML::Essex::Model for some more examples.

C<put()> is a bit DWIMy: it will fill in the name of end_elements for
you if you leave them out:

    put start "foo";
        ...
    put end;

It will also C<die()> if you emit the wrong end_elt for the currently
open element (it keeps a stack), or if you emit and end_document
without emitting end_elements.  You can catch this error and C<put()> the
proper end_element events if you like.

If the filter exits after half-emitting a document and does not
set a result, an error is emitted.  This is to notify you that a
document was half-emitted.  die() to get around this.

Note that downstream filters are free to cache things you send, so don't
modify events once they're sent.  If you need to do that, send a copy
and modify the original.

=cut

sub put {
    my $self = @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ )
        ? shift
        : $XML::Essex::Base::self;

    my $om = $self->output_monitor;

    if ( ! $om->get_handler
        || $om->get_handler->isa( "XML::SAX::Base::NoHandler" )
        && $self->{Writer}
    ) {
        $om->set_handler( $self->{Writer}->() );
    }
    
    my $r;
    for ( @_ ? @_ : $_ ) {
        if ( ! ref $_ ) {
            $r = $om->characters( { Data => $_ } );
        }
        elsif ( UNIVERSAL::can( $_, "generate_SAX" ) ) {
            $r = $_->generate_SAX( $om );
        }
        elsif ( ref $_ eq "ARRAY" ) {
            $r = XML::Essex::Event::element->new( @$_ )->generate_SAX( $om );
        }
        else {
            Carp::croak "Unable to put() ", ref $_ || "'$_'";
        }
    }

    return $r;
}

=item output_monitor

Returns a handle to the output monitor.  See
L<XML::Essex::Filter::OutputMonitor> for details.

=cut

sub set_handler {
    my $self = @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ )
        ? shift
        : $XML::Essex::Base::self;
    $self->output_monitor->set_handler( @_ );
}

sub get_handler {
    my $self = @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ )
        ? shift
        : $XML::Essex::Base::self;
    $self->output_monitor->get_handler( @_ );
}

sub output_monitor {
    my $self = @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ )
        ? shift
        : $XML::Essex::Base::self;
    $self->SUPER::get_handler
}

=back

=head2 Event Constructors

Each event can be constructed by calling the appropriate function or
abbreviated function.

=over

=cut

=item start_document

aka: start_doc

    start_doc \%values;  ## SAX does not define any %values.

=cut

sub start_document { XML::Essex::Event::start_document->new( @_ ) }
*start_doc = \&start_document;

=item end_document

aka: end_doc

    end_doc \%values;    ## SAX does not define any %values.

=cut

sub end_document { XML::Essex::Event::end_document->new( @_ ) }
*end_doc = \&end_document;

=item xml_decl

aka: no abbreviated form

    xml_decl
        Version    => 1,
        Encoding   => "UTF-8",
        Standalone => "yes";

    xml_decl {
        Version    => 1,
        Encoding   => "UTF-8",
        Standalone => "yes"
    };

=cut

sub xml_decl { XML::Essex::Event::xml_decl->new( @_ ) }

=item start_element

aka: start_elt, start

    my $e = start "foo", { "attr" => "va1", ... };
    my $e = start $start_elt;   ## copy constructor
    my $e = start $elt;
    my $e = start $end_elt;

Stringifies like:  C<< <foo attr="val"> >>

=cut

sub start_element { XML::Essex::Event::start_element->new( @_ ) }
*start_elt = \&start_element;
*start = \&start_element;

=item end_element

aka: end_elt, end

    my $e = end "foo";
    my $e = end $end_elt;   ## copy constructor
    my $e = end $start_elt; ## end for a given start_elt
    my $e = end $elt;       ## elt deconstructor

Stringifies like:  C<< </foo> >>

=cut

sub end_element { XML::Essex::Event::end_element->new( @_ ) }
*end_elt = \&end_element;
*end = \&end_element;

=item characters

aka: chars

    my $e = chars "foo", "bar";

Stringifies like the string it is:  C<< foobar >>

NOTE: the stringified form is not XML escaped.

=cut

sub characters { XML::Essex::Event::characters->new( @_ ) }
*chars = \&characters;

=back


=head1 LIMITATIONS

=head1 COPYRIGHT

    Copyright 2002, R. Barrie Slaymaker, Jr., All Rights Reserved

=head1 LICENSE

You may use this module under the terms of the BSD, Artistic, oir GPL licenses,
any version.

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=cut

1;
