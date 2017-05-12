package XML::Essex::Filter::OutputMonitor;

$VERSION = 0.000_1;

=head1 NAME

XML::Essex::Filter::OutputMonitor - Enforce and cajol Essex output

=head1 SYNOPSIS

    ## Internal use only

=head1 DESCRIPTION

Used by XML::Generator::Essex and XML::Filter::Essex instances to watch
what's emitted downstream so as to capture result codes and notice
incomplete documents.

Fills in partially filled end_element events and dies on mismatched
end_element events.  Fills in missing start_document and end_document
events (unless L<auto_document_events|/auto_document_events> is
cleared).

NOTE: This could actually fill in missing end_element events, but I
think that would lead to subtle bugs and would not help in many cases.
It's safer to leave it out and we can always add this feature in the
future, whereas taking it out would be difficult.

Returns a 1 from the end_document if no downstream handler is found.

=for test_script XML-Generator-Essex.t

=head2 Methods

=over

=cut

use XML::SAX::Base ();
@ISA = qw( XML::SAX::Base );

# Not sure why Carp is still reporting errors in XML::Essex.
@CARP_NOT = ( @ISA, qw( XML::Essex XML::Essex::Event XML::Filter::Essex ) );

use strict;
use Carp ();
use XML::Essex::Model ();

sub new {
    my $self = shift->SUPER::new( @_ );
    $self->auto_document_events( 1 );
    return $self;
}


sub start_document {
    my $self = shift;

    $self->start_document_seen( 1 );
    $self->end_document_seen( 0 );
    $self->end_document_result( undef );
    $self->end_document_result_has_been_set( 0 );
    $self->{Stack} = [];

    $self->SUPER::start_document( @_ );
}


sub start_element {
    my $self = shift;

    $self->start_document( {} )
        if $self->auto_document_events
            && ! $self->start_document_seen;

    push @{$self->{Stack}}, $_[0];

    $self->SUPER::start_element( @_ );
}

sub end_element {
    my $self = shift;
    my ( $elt ) = @_;

    my $s = $self->{Stack};

    Carp::croak "extra end_element at end of document: </",
        XML::Essex::Model::_render_event_name( $elt ),
        ">"
        unless @$s;

    # Only DWIM if nothing has been set so that partially built
    # end_elements are more likely to cause downstream errors.
    if (   ! defined $elt->{NamespaceURI}
        && ! defined $elt->{LocalName}
        && ! defined $elt->{Prefix}
        && ! defined $elt->{Name}
    ) {
        @{$elt}{qw(
            NamespaceURI
            LocalName
            Prefix
            Name
        )} = @{$s->[-1]}{qw(
            NamespaceURI
            LocalName
            Prefix
            Name
        )};
    }

    my $ns_uri = defined $elt->{NamespaceURI}
        ? $elt->{NamespaceURI}
        : "";

    if ( $s->[-1]->{LocalName} eq $elt->{LocalName}
        &&  (
            defined $s->[-1]->{NamespaceURI}
                ? $s->[-1]->{NamespaceURI}
                : ""
        )
        eq $ns_uri
    ) {
        pop @$s;
    }
    else {
        my @missing;
        for ( reverse @$s ) {
            last
                if $_->{LocalName} eq $elt->{LocalName}
                && (
                    defined $_->{NamespaceURI}
                        ? $_->{NamespaceURI}
                        : ""
                ) eq $ns_uri;
            push @missing, $_;
        }

        Carp::croak( "end_element mismatch:  expected </",
            XML::Essex::Model::_render_event_name( $s->[-1] ),
            ">, got </",
            XML::Essex::Model::_render_event_name( $elt ),
            ">",
            ! @missing
                ? ()
                : (
                    ".  These may have been skipped: ",
                    map "</"
                        . XML::Essex::Model::_render_event_name( $_ )
                        . ">",
                        @missing
                ),
        );
    }

    $self->SUPER::end_element( @_ );
}


sub end_document {
    my $self = shift;

    $self->end_document_seen( 1 );

    Carp::croak( "end_document sent but no start_document" )
        unless $self->{Stack};

    if ( @{$self->{Stack}} ) {
        Carp::croak( "missing end_element(s) at end of document: ",
            map "</"
                . XML::Essex::Model::_render_event_name( $_ )
                . ">",
                reverse @{$self->{Stack}}
        );
    }

    delete $self->{Stack};

    # Use a scalar to catch the result so a return of ()
    # converts to "undef".
    my $r = $self->SUPER::get_handler
        ? $self->SUPER::end_document( @_ )
        : 1;

    $self->end_document_result( $r );
    return $r;
}


=item reset

Undefines all state variables.

=cut

sub reset {
    my $self = shift;

    $self->start_document_seen( undef );
    $self->end_document_seen( undef );
    $self->end_document_result( undef );
    $self->end_document_result_has_been_set( 0 );
}


=item finish

Emits an end_doc if need be.

=cut

sub finish {
    my $self = shift;

    $self->end_document( {} )
        if $self->auto_document_events
            && $self->start_document_seen
            && ! $self->end_document_seen;
}


=item start_document_seen

Sets/gets whether the start_document event was seen.

=cut

sub start_document_seen {
    my $self = shift;
    $self->{EssexStartDocumentSeen} = shift if @_;
    return $self->{EssexStartDocumentSeen};
}

=item end_document_seen

Sets/gets whether the end_document event was seen.  Will be set if the
downstream filter's C<end_document()> throws an exception.

=cut

sub end_document_seen {
    my $self = shift;
    $self->{EssexEndDocumentSeen} = shift if @_;
    return $self->{EssexEndDocumentSeen};
}

=item end_document_result

Sets/gets the result returned by the downstream filter's C<end_document()>
event handler.  Set to undef if nothing else, for instance if the
downstream C<end_document()> throws an exception.

=cut

sub end_document_result {
    my $self = shift;
    if ( @_ ) {
        $self->{EssexEndDocumentResult} = shift;
        $self->{EssexEndDocumentResultHasBeenSet} = 1;
    }
    return $self->{EssexEndDocumentResult};
}

=item end_document_result_has_been_set

Set if the end_document_result() has been called.

=cut

sub end_document_result_has_been_set {
    my $self = shift;
    $self->{EssexEndDocumentResultHasBeenSet} = shift if @_;
    return $self->{EssexEndDocumentResultHasBeenSet};
}

=item auto_document_events

When set (the default), a start_document will be emitted before the
first event unless it is start_document event and an end_document will
be emitted after the last event unless an end_document was emitted.
When cleared, this automation does not occur.  The automatic end_document
will not be emitted if an exception is thrown so as not to cause
a stateful downstream handler to throw an additional exception.

This does allow well-balanced chunks of XML to be emitted, but there
will be start_ and end_document events around them.  Clear this
member is you don't want to emit them, or if you want to emit them
yourself.

This is not affected by L<reset()|/reset>.

=cut

sub auto_document_events {
    my $self = shift;
    $self->{AutoDocumentEvents} = shift if @_;
    return $self->{AutoDocumentEvents};
}

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
