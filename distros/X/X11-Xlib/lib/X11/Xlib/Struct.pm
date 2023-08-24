package X11::Xlib::Struct;
use strict;
use warnings;
use X11::Xlib ();
use Carp ();

our $VERSION = '0.25';

=head1 NAME

X11::Xlib::Struct - Base class for X11 packed structures

=head1 DESCRIPTION

Base class for the various exposed C-structs of Xlib, which are represented
as a blessed scalar-ref of the raw bytes of the struct.  This makes them more
efficient than fully inflating/deflating perl hashrefs for every Xlib call.

All attribute accessors are defined in XS.

=head1 ATTRIBUTES

=head2 display

A reference to an L<X11::Xlib> instance, automatically set by various functions
that populate structs.  Many times a struct will have pointers that are related
to a particular display, so it is desirable to pair the struct with its display
pointer in order to be able to inflate those other pointers into objects and be
able to call methods on them.

This attribute is implemented "inside-out", so it can't be seen in a dump of the
perl data, and requires help from DESTROY to clean up.  (handled by this class's
destructor)

=cut

*display= *X11::Xlib::Opaque::display;

=head1 METHODS

=head2 new

  my $struct= X11::Xlib::....->new( %optional_fields );

The constructor sets all fields to their initial value (i.e. zero)
and then applies the list of key/value pairs.  Warns on unknown
field names.

=cut

sub new {
    my $class= shift;
    $class= ref $class if ref $class;
    my $self= bless \(my $buffer), $class;
    $self->_initialize;
    $self->apply(@_) if @_; # If arguments, then initialize using apply
    $self;
}

=head2 initialize

Set all struct fields to a sensible initial value (like zero)

=cut

sub initialize {
    shift->_initialize;
}

=head2 pack

  $struct->pack( \%fields, $consume, $warn );

Pack field values into the bytes of the struct.  Only C<%fields> is required.

If C<$consume> is true, then remove any key of C<%fields> that was processed.

If C<$warn> is true, then emit a warning if any unrecognized field was given.

=cut

sub pack {
    my ($self, $fields, $consume, $warn)= @_;
    $fields= { %$fields } unless $consume;
    $self->_pack($fields, 1);
    Carp::carp("Unused parameters passed to pack: ".join(',', keys %$fields))
        if $warn && keys %$fields;
    return $self;
}

=head2 apply

  $struct->apply( \%fields );
  $struct->apply( field => $val, ... );

Alias for C< pack(\%fields, 1, 1) >.
For each given field, update that member of the struct.
Emits a warning if the hash contains unknown fields.

=cut

sub apply {
    my $self= shift;
    Carp::croak("Expected hashref or even-length list")
        unless 1 == @_ && ref($_[0]) eq 'HASH' or !(1 & @_);
    my %args= @_ == 1? %{ shift() } : @_;
    
    $self->pack(\%args, 1, 1);
}

=head2 unpack

  my $hashref= $struct->unpack();

Extract all fields as Perl data.

=cut

sub unpack {
    my $self= shift;
    $self->_unpack(my $ret= {});
    if ($self->can('display') && defined (my $dpy= $self->display)) {
        # tag all objects returned as belonging to this display
        for (values %$ret) {
            $_->display($dpy) if ref $_ && ref($_)->can('display');
        }
    }
    $ret;
}

=head2 bytes

Access the scalar holding the bytes of the struct.

=for Pod::Coverage buffer

=cut

sub bytes { ${$_[0]} }
*buffer= *bytes; # back-compat alias, not official API anymore

# The struct code is all in XS, so all we need to do is declare the package
# inheritence.  Except for XEvent, which is complicated.

require X11::Xlib::XEvent;
@X11::Xlib::XVisualInfo::ISA= ( __PACKAGE__ );
$X11::Xlib::XVisualInfo::VERSION= $VERSION;
@X11::Xlib::XWindowChanges::ISA= ( __PACKAGE__ );
$X11::Xlib::XWindowChanges::VERSION= $VERSION;
@X11::Xlib::XWindowAttributes::ISA= ( __PACKAGE__ );
$X11::Xlib::XWindowAttributes::VERSION= $VERSION;
@X11::Xlib::XSetWindowAttributes::ISA= ( __PACKAGE__ );
$X11::Xlib::XSetWindowAttributes::VERSION= $VERSION;
@X11::Xlib::XSizeHints::ISA= ( __PACKAGE__ );
$X11::Xlib::XSizeHints::VERSION= $VERSION;
@X11::Xlib::XRectangle::ISA= ( __PACKAGE__ );
$X11::Xlib::XRectangle::VERSION= $VERSION;
@X11::Xlib::XRenderPictFormat::ISA= ( __PACKAGE__ );
$X11::Xlib::XRenderPictFormat::VERSION= $VERSION;
@X11::Xlib::XKeyboardState::ISA= ( __PACKAGE__ );
$X11::Xlib::XKeyboardState::VERSION= $VERSION;

1;

__END__

=head1 AUTHOR

Olivier Thauvin, E<lt>nanardon@nanardon.zarb.orgE<gt>

Michael Conrad, E<lt>mike@nrdvana.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2010 by Olivier Thauvin

Copyright (C) 2017-2023 by Michael Conrad

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
