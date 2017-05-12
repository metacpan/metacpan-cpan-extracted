package XML::Handler::Essex;

$VERSION = 0.000_1;

use XML::Essex::Constants;
use Scalar::Util qw( reftype );

#use Time::HiRes qw( time );
#sub warn { warn sprintf( "%.2f", time ), " ", @_; }

BEGIN {
    require XML::Handler::Essex::Threaded if threaded_essex;
}

=head1 NAME

XML::Handler::Essex - Essex handler object (including XML::Filter::Essex)

=head1 SYNOPSIS

    use XML::Handler::Essex;

    my $h = XML::Handler::Essex->new(
        Main => sub {
            while ( get_chars ) {
                put uc;
            }
        }
    );

=head1 DESCRIPTION

Defines (and exports, by default) C<get()> and C<get_...()> routines
that allow an Essex handler and filter to pull events from the SAX
stream.

Pulling is handled in one of two ways: the entire input document is
buffered if a perl earlier than 5.8.0 is used, due to lack of
multithreading, and threading is used in perls later than 5.8.0.

Note that the event constructor functions (C<start_doc()>, C<end_doc()>,
etc) are not exported by this module as they are from
XML::Generator::Essex and XML::Filter::Essex; handlers rarely need
these.

Returns a "1" by default, use C<result_value> to change.

=for test_script XML-Filter-Essex.t

=cut

use XML::Essex::Base ();  # Don't import things.
use XML::Essex::Model ();
use Carp ();

no warnings "once";

@ISA = qw( XML::Essex::Base );

@EXPORT = qw(
    isa
    next_event
    path
    type
    xeof

    get
    on
);

#    get_start_document
#    get_start_doc
#
#    get_start_element
#    get_start_elt
#    get_end_element
#    get_end_elt
#    get_element
#    get_elt
#
#    get_characters
#    get_chars
#);

use strict;
use NEXT;
use XML::SAX::EventMethodMaker qw( compile_missing_methods sax_event_names );

sub new {
    my $proto = shift;

    return $proto->SUPER::new( @_ ) if ref $proto;

    my $class = $proto;

    if ( threaded_essex ) {
        require XML::Handler::Essex::Threaded;
        $class .= "::Threaded";
    }

    return $class->SUPER::new( @_ );
}


sub _init {  ## Called by new()
    my $self = shift;

    $self->{PendingEvents} = [];
    $self->{Events} = [];

    $self->NEXT::_init( @_ );
}


sub reset {  ## called before main() by execute()
    my $self = shift;
    $self->{Result} = 1;
    ## Hmmm, should we clear Events here?  Can't clear
    ## events in non-threaded mode.
    undef $self->{Dispatchers};
    $self->NEXT::reset( @_ );
}


sub finish { ## called after main() by execute()
    my $self = shift;
    
    my ( $ok, $x ) = @_;

#    die ref( $self ) . "::main() exited before end_document seen\n"
#        if $ok && $self->{InDocument};

    # In case we're also an XML::Generator::Essex, let it have
    # first crack at the result value.  This sort of encodes
    # knowledge of the inheritance hierarchy for XML::Filter::Essex
    # in this code; it would be better to have an arbitration
    # scheme where there is a default result set, then a
    # downstream result, then a manually set result, with the
    # highest ranking one set winning (ie last in that list).
    # The current scheme, however, is BALGE.
$DB::single=1;
    my ( $result_set, $result ) = $self->NEXT::finish( @_ );

    return ( $result_set, $result ) if $result_set;

    unless ( $ok ) {
        if ( $x eq EOD . "\n" ) {
            return ( 1, $self->{Result} );
        }
        die $x;
    }

    return ( 1, $self->{Result} );
}


sub _send_event_to_child {
    my $self = shift;

    warn "Essex $self: queuing $_[0] for child\n" if debugging;
    push @{$self->{Events}}, @{$self->{PendingEvents}}, [ @_ ];
    @{$self->{PendingEvents}} = ();
    # force scalar context to be consistent with the threaded case.
}


## There's a DESTROY in XML::Handler::Essex::Threaded

# NOTE: returns \@event, whereas _send_event_to_child takes @event.
# This is to speed the queue fudging that threaded_execute does on
# start_document.
sub _recv_event_from_parent {
    my $self = shift;

    my $event;

    die EOD . "\n"
        if $self->{PendingResultType} eq "end_document";

    unless ( @{$self->{Events}} ) {
        if ( $self->{Reader} ) {
            do {
                $self->{Reader}->();
            } until @{$self->{Events}};
        }
        else {
            Carp::croak "No XML events to process";
        }
    }

    $event = $self->{Events}->[0];
    my $event_type = $event->[0];
    warn "Essex $self:   got $event_type $event->[1] from parent\n"
        if debugging;

    shift @{$self->{Events}};

    die $event_type . "\n"
        if $event_type eq BOD || $event_type eq EOD || $event_type eq SEPPUKU;

    if ( threaded_essex ) {
        ## Set the default result for this event.
        @$self{ "PendingResultType",    "PendingResult"        } = 
            ( $event_type, "Essex: default result for $event_type" );
    }

    return $event;
}

# Hopefully, this handles inline set_document_locator events relatively
# gracefully, by queueing them up until the next event arrives.  This is
# necessary because set_document_locator events can arrive *before* the
# start_document, and we need to wait for the next event to see whether
# to insert the BOD before the set_document_locator.  This is all so that
# the initial set_document_locator event(s) will arrive before the
# start_document event in the main() routine, given that we need to
# send the BOD psuedo event in case the main() routine is still running.
sub set_document_locator {
    push @{shift->{PendingEvents}}, [ "set_document_locator", @_ ];
    return "Essex: document locator queued";
}


sub end_document {
    my $self = shift;
    ## Must send EOD after the end_document so that we get the end_document
    ## result back first otherwise it would be lost because
    ## _recv_event_from_parent does not send results back if there are any
    ## other events in the queue.  If this were not so, we could add a hack
    ## here to queue up both end_document and EOD at once.
    my $r = $self->_send_event_to_child( "end_document", @_ );

    push @{$self->{Events}}, [ EOD ];
    return $self->execute;

    return $r;
}

compile_missing_methods __PACKAGE__, <<'END_CODE', sax_event_names;
#line 1 XML::Handler::Essex::<EVENT>()
sub <EVENT> {
    shift->_send_event_to_child( "<EVENT>", @_ );
}

END_CODE

=head1 Exported Functions

These are exported by default, use the C<use XML::Essex ();> syntax to suppress
exporting these.  All of these act on $_ by default.

=head2 Miscellaneous

=over

=item isa

    get until isa "start_elt" and $_->name eq "foo";
    $r = get until isa $r, "start_elt" and $_->name eq "foo";

Returns true if the parameter is of the indicated object type.  Tests $_
unless more than one parameter is passed.

Note the use of C<and> instead of C<&&> to get paren-less C<isa()> to
behave as expected (this is a typical Perl idiom).

=cut

sub isa {
    local $_ = shift if @_ >= 2;
    UNIVERSAL::isa( $_, "XML::Essex::Event" )
        ? $_->isa( @_ )
        : UNIVERSAL::isa( $_, @_ );
}

=item path

   get_start_elt until path eq "/path/to/foo:bar"

Returns the path to the current element as a string.

=cut

sub path {
    my $self = @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ )
        ? shift
        : $XML::Essex::Base::self;
    return join "/", "", map $_->name, @{$self->{Stack}};
}

=for import XML::Generator::Essex/put

=item type

    get until type eq "start_document";
    $r = get until type $r eq "start_document";


Return the type name of the object.  This is the class name with a
leading XML::Essex:: stripped off.  This is a wrapper around the
event's C<type()> method.

Dies C<undef> if the parameter is not an object with a C<type> method.

=cut

sub type {
    local $_ = shift if @_;

    Carp::croak
        ref $_ || "a scalar",
        " is not an Essex event, cannot type() it\n"
        unless UNIVERSAL::can( $_, "type" );

    return $_->type( @_ )
}

=item xeof

Return TRUE if the last event read was an end_document event.

=cut

sub xeof {
    my $self = @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ )
        ? shift
        : $XML::Essex::Base::self;

    lock @{$self->{Events}} if threaded_essex;
    return @{$self->{Events}} && $self->{Events}->[0] eq EOD;
}

=item get

Gets an event or element from the incoming SAX input stream, puts it in
C<$_> and returns it.  Throws an exception when reading past the last
event in a document.  This exception is caught by XML::Essex and
causes it to wait until the beginning of the next document and reenter
the main routine.

    Code                     Action
    =======================  =======================================
    get;                     Get the next SAX event, whatever it is.
    get "node()";            Get the next SAX event, whatever it is.
    get "*";                 Get the next element, whatever its name.
    get "start-document::*"; Get the next start document event.
    get "end-document::*";   Get the next end document event.
    get "start-element::*";  Get the next start element event.
    get "end-element::*";    Get the next end element event.
    get "text()";            Get the next characters event.

Right now, only the expressions shown are supported.  This is a
limitation that will be lifted.  There may be multiple characters
events in a row, unlike xpath's text() matching expression.

See C<isa()> and C<type()> functions and method (in
L<XML::Essex::Object>) for how to test what was just gotten.

=cut

sub _get {
    my $self = shift;

    my ( $type, $data ) = @{$self->_recv_event_from_parent};

    my $event = bless \$data, "XML::Essex::Event::$type";

    unless ( $event->isa( "XML::Essex::Event" ) ) {
        no strict 'refs';
        @{"XML::Essex::Event::${type}::ISA"} = qw( XML::Essex::Event );
    }

    pop @{$self->{Stack}} if $self->{PopNext};

    if ( $event->isa( "XML::Essex::Event::start_document" ) ) {
        $self->{Stack} = [];
        $self->{PopNext} = 0;
    }
    elsif ( $event->isa( "XML::Essex::Event::start_element" ) ) {
        push @{$self->{Stack}}, $event;
    }
    elsif ( $event->isa( "XML::Essex::Event::end_element" ) ) {
        # Delay popping so caller can see the end_element on the
        # stack if need be.
        $self->{PopNext} = 1;
    }
    else {
        $self->{PopNext} = 0;
    }

    if ( $self->{Dispatchers} ) {
        $data->{__EssexEvent} = $event;
        for my $d ( @{$self->{Dispatchers}} ) {
            local $_;
            $d->$type( $data );
        }
# TODO: figure out a way to clean these up.
#        delete $data->{__EssexEvent};
    }

    return $event;
}


sub get {
    my $self = @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ )
        ? shift
        : $XML::Essex::Base::self;

    my ( $xpathlet ) = @_;

    my $event_type;
    if ( ! defined $xpathlet || $xpathlet eq "node()" ) {
        return $_ = $self->_get;
    }
    elsif ( $xpathlet eq "*" ) {
        return $self->get_element;
    }
    elsif ( $xpathlet eq "start-document::*" ) {
        $event_type = "start_document";
    }
    elsif ( $xpathlet eq "end-document::*" ) {
        $event_type = "end_document";
    }
    elsif ( $xpathlet eq "start-element::*" ) {
        $event_type = "start_element";
    }
    elsif ( $xpathlet eq "end-element::*" ) {
        $event_type = "end_element";
    }
    elsif ( $xpathlet eq "text()" ) {
        $event_type = "characters";
    }
    elsif ( $xpathlet eq "comment()" ) {
        $event_type = "comment";
    }
    elsif ( $xpathlet eq "processing-instruction()" ) {
        $event_type = "processing_instruction";
    }
    else {
        Carp::croak "Unsupported or invalid expression '$xpathlet'";
    }

    my $event;
    while (1) {
        $event = $self->_get;
        last if $event->isa( $event_type );
        $self->_skip_event( $event );
    }

    $_ = $event;
}

=item skip

Skips one event.  This is what happens to events that are not returned
from get().  For a handler, skip() does nothing (the event is ignored).
For a Filter, the event is passed on the the handler.

=cut

sub _skip_event {
    ## Ignore it by default.  XML::Filter::Essex overloads this.
}

sub skip {
    my $self = @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ )
        ? shift
        : $XML::Essex::Base::self;
    $self->_skip_event( $self->_get );   
}

=item next_event

Returns the event that the next call to get() will return.  Dies if
at xeof.  Does not set $_.

NOTE: NOT YET IMPLEMENTED IN THREADED MODE.

=cut

sub next_event {
    my $self = shift;

    my ( $type, $data ) = do {
Carp::croak "Essex: next_event() not yet implemented in threaded mode"
    if threaded_essex;
        lock @{$self->{Events}} if threaded_essex;
        @{$self->{Events}->[0]};
    };

    my $e = bless \$data, "XML::Essex::Event::$type";

    unless ( $e->isa( "XML::Essex::Event" ) ) {
        no strict 'refs';
        @{"XML::Essex::Event::${type}::ISA"} = qw( XML::Essex::Event );
    }

    return $e;
}

#=item get_start_document
#
#aka: get_start_doc
#
#Skips all events until the next start_document event.  Perhaps only
#useful in multi-document streams.
#
#=cut
#
#sub get_start_document {
#    my $self = @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ )
#        ? shift
#        : $XML::Essex::Base::self;
#
#    my $event;
#    do {
#        $event = $self->get;
#    } until $_->isa( "start_document" );
#
#    $_ = $event;
#}
#
#*get_start_doc = \&get_start_document;
#
#=item get_end_document
#
#aka: get_end_doc
#
#Skips all events until the next end_document event.
#
#=cut
#
#sub get_end_document {
#    my $self = @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ )
#        ? shift
#        : $XML::Essex::Base::self;
#
#    my $event;
#    do {
#        $event = $self->get;
#    } until $_->isa( "end_document" );
#
#    $_ = $event;
#}
#
#*get_end_doc = \&get_end_document;
#
#=item get_start_element
#
#aka: get_start_elt
#
#Skips all events until the next start_element event.
#
#=cut
#
#sub get_start_element{
#    my $self = @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ )
#        ? shift
#        : $XML::Essex::Base::self;
#
#    my $event;
#    do {
#        $event = $self->_get;
#    } until $event->isa( "start_element" );
#
#    return $_ = $event;
#}
#
#*get_start_elt = \&get_start_element;
#
#=item get_end_element
#
#aka: get_end_elt
#
#Skips all events until the next end_element event.  Returns an
#end_element object.
#
#=cut
#
#sub get_end_element {
#    my $self = @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ )
#        ? shift
#        : $XML::Essex::Base::self;
#
#    my $event;
#    do {
#        $event = $self->get;
#    } until $_->isa( "end_element" );
#
#    return $_ = $event;
#}
#
#*get_end_elt = \&get_end_element;
#
#=item get_element
#
#aka: get_elt
#
#    my $elt = get_elt;
#
#Skips all events until the next start_element event, then consumes it
#and all events up to and including the matching eld_element event.
#Returns an L<element|XML::Essex::Model/element> object.
#
#    my $start_element = get_start_elt;
#    my $elt = get_elt $start_element;
#
#Skips nothing; takes a start_element and uses it to create an element
#object by reading all content and then matching end_element event
#from the input stream.
#
#=cut
#
#
sub get_element {
    my $self = @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ )
        ? shift
        : $XML::Essex::Base::self;

    my $start_elt;
    if ( @_ ) {
        $start_elt = shift;
    }
    else {
        do {
            $start_elt = $self->_get;
        } until $start_elt->isa( "start_element" );
    }
    my $elt = XML::Essex::Event::element->new( $start_elt );
    while (1) {
        my $event = $self->_get;
        if ( $event->isa( "XML::Essex::Event::start_element" ) ) {
            $elt->_add_content( get_element $event );
        }
        elsif ( $event->isa( "XML::Essex::Event::end_element" ) ) {
            $elt->_end_element( $event );
            last;
        }
        else {
            $elt->_add_content( $event );
        }
    }

    return $_ = $elt;
}

#*get_elt = \&get_element;
#
#=item get_characters
#
#aka: get_chars
#
#Skips to the next characters event and returns it.
#
#=cut
#
#sub get_characters {
#    my $self = @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ )
#        ? shift
#        : $XML::Essex::Base::self;
#
#    my $event;
#    do {
#        $event = $self->get;
#    } until $_->isa( "characters" );
#
#    return $_ = $event;
#}
#
#*get_chars = \&get_characters;

=item on

    on(
        "start_document::*" => sub { warn "start of document reached" },
        "end_document::*"   => sub { warn "end of document reached"   },
    );

=for TODO
    my $rule = on $pat1 => sub { ... }, ...;
        ...time passes with rules in effect...
    disable_rule $rule;
        ...time passes with rules I<not> in effect...
    enable_rule $rule;
        ...time passes with rules in effect again...

This declares that a rule should be in effect until the end of the
document is reached.  Each rule is a ( $pattern => $action ) pair where
$pattern is an EventPath pattern (see
L<XML::Filter::Dispatcher|XML::Filter::Dispatcher>) and $action is a
subroutine reference.

The Essex event object matched is passed in $_[1].  A reference to
the current Essex handler is passed in $_[0].  This allows you to
write libraries of functions that access the current Essex
handler/filter/whatever.

Do not call get() in the actions, you'll confuse everything.  That's
a limitation that should be lifted one day.

=for TODO or it is disabled.

=for TODO Returns a handle that may be used to enable or disable all
rules passed in.

For now, this must be called before the first get() for predictable
results.

Rules remain in effect after the main() routine has exited to facilitate
pure rule based processing.

=cut

## TODO: parse but don't compile rules; allow them to be compiled as
## one large rule and added to a single X::F::D when the Reader
## sub is run.
sub _wrap_action {
    my ( $self, $action ) = @_;
    sub {
        local $XML::Essex::dispatcher = shift;
        $action->( $self, $_[0]->{__EssexEvent} );
    };
}


sub on {
    my $self = @_ && UNIVERSAL::isa( $_[0], __PACKAGE__ )
        ? shift
        : $XML::Essex::Base::self;

    return undef unless @_;
    
    require XML::Filter::Dispatcher;

    my @rules;

    while ( @_ ) {
        my ( $pattern, $action ) = ( shift, shift );

        if ( ref $action eq "ARRAY" ) {
            ## TODO: make this recursive
            my @actions = map {
                ref $_ eq "CODE"
                    ? _wrap_action( $self, $_ )
                    : $_;
            } @$action;

            $action = \@actions;
        }
        else {
            $action = _wrap_action( $self, $action );
        }

        push @rules, ( $pattern => $action );
    }

    push @{$self->{Dispatchers}}, XML::Filter::Dispatcher->new(
        Rules => \@rules,
    );

    return undef;
}

sub xvalue { $XML::Essex::dispatcher->xvalue( @_ ) }

sub xpush { XML::Filter::Dispatcher::xpush( @_ ) }
sub xpop  { XML::Filter::Dispatcher::xpop( @_ ) }
sub xadd  { XML::Filter::Dispatcher::xadd( @_ ) }
sub xset  { XML::Filter::Dispatcher::xset( @_ ) }


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
