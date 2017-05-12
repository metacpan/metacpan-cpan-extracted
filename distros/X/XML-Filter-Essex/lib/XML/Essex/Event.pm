package XML::Essex::Event;

$VERSION = 0.000_1;

=head1 NAME

    XML::Essex::Event - ...

=head1 SYNOPSIS

=head1 DESCRIPTION

The base event class, also used for unknown event types.
Stringifies as $event->type . "()" to indicate an
event that has no natural way to represented in XML, or for ones that
haven't been handled yet in Essex.

=cut

=head1 Methods

=over

=cut

use XML::Essex::Constants qw( debugging );

use strict;

use overload (
    '""'  => \&_stringify,
    "cmp" => sub { "$_[0]" cmp "$_[1]" },
    "=="  => sub { "$_[0]" ==  "$_[1]" },
);

=item new

    XML::Event->new( a => 1, b => 2 );
    XML::Event->new( { a => 1, b => 2 } );
    
    ## in a subclass:
    sub new {
        my $self = shift->SUPER::new( @_ );
        ...
        return $self;
    }

A generic constructor.

If a single value is passed in, a reference to it is kept.  This must
be a HASH for all builtin objects.

If an even number of parameters is passed in, treats them as key =>
value pairs and creates a HASH around them.

=cut

# $self is a blessed reference to a SCALAR containing another reference
# to the data.  This double indirection serves several purposes:
#
# 1. It allows us to overload %{} on $self and still easily get at
#    the object's data.
# 2. It allows upstream filters to send us blessed, tied or overloaded
#    objects that we operate on and pass on.
# 3. It reduces copying, at the cost of increasing the cost of
#    dereferencing.  As many SAX operations are pass through, this may
#    be a win in most cases.

sub new {
    my $proto = shift;

    my $self = @_ == 1
        ? UNIVERSAL::isa( $_[0], "XML::Essex::Event" )
            ? $_[0]->clone
            : \$_[0]
        : \{ @_ };

    bless $self, ref $proto || $proto;
}

=item isa

Accepts shorthand; if the object's class starts with
"XML::Essex::Event::", the parameter is checked against the string after
"XML::Essex::Event::".  So a XML::Essex::Event::foo->isa( "foo" ) is
true (assuming it really is true; in other words, assuming that its @ISA
is set properly).

=cut

sub isa {
    my $self = shift;
    my $class = ref $self || $self;

    return (1
        && substr( $class, 0, 19 ) eq "XML::Essex::Event::"
        && substr( $class, 19 ) eq $_[0]
        ) || $self->SUPER::isa( @_ );
}

=item clone

    my $clone = $e->clone;

Does a deep copy of an event.  Any events that require a deep copy
must overload this to provide it, the default action is to just copy the
main HASH.

=cut

sub clone {
    my $self = shift;

    bless \{ %$$self }, ref $self;
}

=item type

Strips all characters up to the "::" and returns the remainder, so, for
the XML::Essex::start_document class, this returns "start_document".

This I<must> return a valid SAX event name, it is used to figure out
how to serialize most event objects.

This is overloaded in most classes for speed and to allow subclasses to
tweak the behavior of a class and still be reported as the proper type.

=cut

sub type {
    ( my $r = ref shift ) =~ s/.*:://;
    $r
}

sub _stringify { shift->type() . "()" }

=item generate_SAX

    $e->generate_SAX( $handler );

Emits the SAX event(s) necessary to serialize this event object
and send them to $handler.  $handler will always be defined.

Uses the C<type> method to figure out what to send.  Some classes
(notably XML::Essex::characters) overload this for various reasons.

Assumes scalar context (which should not cause problems).

=cut

# scalar context is assumed in start_element::generate_SAX.

sub generate_SAX {
    my $self = shift;
    my ( $h ) = @_;

    my $method = $self->type;
    warn "Essex $self generating $method()\n" if debugging;
    return $h->$method( $$self );
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
