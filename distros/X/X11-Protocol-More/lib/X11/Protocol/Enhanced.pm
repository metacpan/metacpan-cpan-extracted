package X11::Protocol::Enhanced;
use X11::Protocol qw(pad padding padded make_num_hash);
use Carp;
use strict;
no warnings;
use vars '$VERSION';
$VERSION = 0.05;

=head1 NAME

X11::Protocol::Enhanced - bit mask enhancements for X11::Protocol

=head1 SYNOPSIS

 use X11::Protocol;
 use X11::Protocol::Enhanced;

 # just to define 'Rotation' type:
 my $X = X11::Protocol->new();
 $X->init_extension('RANDR') or die "Cannot initialize RANDR!";

 my $mask = $X->pack_mask(Rotation=>qw(Rotate_0 Reflect_X));
 my %mask = $X->unpack_mask(Rotation=>$mask);
 print "Bits set are: ",join(',',keys %mask),"\n";

=head1 DESCRIPTION

This module is used by a number of protocol extensions to enhance the
enumeration and bit mask handling of the L<X11::Protocol(3pm)> object.
It does this by adding or overriding a number of methods on the
L<X11::Protocol(3pm)> module when it loads.

=cut

=head1 METHODS

L<X11::Protocol(3pm)> does not provide a way to pack and unpack masks using
symbolic constants, except for event masks.
B<X11::Protocol::Ext::KEYBOARD> uses so many masks that either we needed
to define bitmap mask constants in perl, or we needed a way to pack and
unpack masks.  To provide this capability, the
B<X11::Protocol::Enhanced> module adds the following methods to the
C<X11::Protocol(3pm)> object:

=over

=item $mask = $X->B<pack_mask>(I<$typename>,\@constants)

Where, I<$typename> is a symbolic constant type name like C<Bool> or
C<XkbControl>, and C<\@constants> is a list (array ref) of symbolic
constants defined for I<$typename> or bit numbers.  B<pack_mask> returns
a numeric value representing the mask with the appropriate bits set.
When C<\@constants> is a scalar value, the value is simply returned.

This function is similar to B<pack_event_mask> with the exception that
it can be used where I<$typename> is not equal to 'EventMask'.

B<pack_mask> is called by the request functions in this module on may of
the arguments passed into the request.  Therefore, the arguments passed
to the request can either be the numeric bit mask, or can be an array or
hash of bit values.

=cut
sub pack_mask {
    my $self = shift;
    my($typename,$x) = @_;
    return $x unless ref($x) eq 'ARRAY';
    my $type = $self->{const_num}{$typename};
    $type = $self->{ext_const_num}{$typename} unless $type;
    if (not $type) {
        if ($self->{const}{$typename}) {
            $type = $self->{const_num}{$typename} =
            {make_num_hash($self->{const}{$typename})};
        }
        elsif ($self->{ext_const}{$typename}) {
            $type = $self->{ext_const_num}{$typename} =
            {make_num_hash($self->{ext_const}{$typename})};
        }
    }
    my($i, $mask);
    $mask = 0;
    for $i (@$x) {
        $i = $type->{$i} if $type and exists $type->{$i};
        if ($i =~ m{^\d+$} and $i<32) {
            $mask |= 1<<$i;
        }
    }
    return $mask;
}

*X11::Protocol::pack_mask =
\&X11::Protocol::Enhanced::pack_mask;

=item %mask = $X->B<unpack_mask>(I<$typename>,I<$mask>)

Where, I<$typename> is a symbolic constant type name like C<Bool> or
C<XkbBoolCtrl>, and I<$mask> is a numerical representation of the bit
mask.  The bit positions in the number are converted into a HASH where
the keys of the hash are the symbolic names of the bits set to 1 or the
bit number when no symbolic name for the bit appears in I<$typename>.
The value associated with the key is always 1.  The HASH is returned.

If you would prefer the ARRAY form as was passed to B<pack_mask>, this
trick will do:

  %mask = $X->unpack_mask($typename,$mask);
  @mask = keys %mask;

Masks are not automatically unpacked by the event routines, nor for
responses to requests.  You will need to unpack returned fields
yourself using this function.  Refer to the specification to see which
symbolic constant I<$typename> to use when unpacking.

=cut
sub unpack_mask($$) {
    my $self = shift;
    my($typename,$mask) = @_;
    my $type = $self->{const}{$typename};
    $type = $self->{ext_const}{$typename} unless $type;
    carp "Could not find typename '$typename'" unless $type;
    my $i = 0;
    my %h = ();
    while ($mask) {
        if ($mask & 0x1) {
            if ($type and $type->[$i]) {
                $h{$type->[$i]} = 1;
            } else {
                $h{$i} = 1;
            }
        }
        $i++;
        $mask >>= 1;
    }
    return %h;
}

*X11::Protocol::unpack_mask =
\&X11::Protocol::Enhanced::unpack_mask;

=item $mask = $X->B<interp_mask>(I<$typename>,I<$mask>)

Like B<unpack_mask>, but only interprets the mask when the
C<do_interp_mask> flag is set on C<$X>.

=cut
sub interp_mask($$) {
    my $self = shift;
    my ($typename,$mask) = @_;
    return $self->unpack_mask(@_) if $self->{do_interp_mask};
    return $mask;
}

*X11::Protocol::interp_mask =
\&X11::Protocol::Enhanced::interp_mask;

=item $num = $X->B<pack_enum>(I<$typename>,I<$nameornum>)

=item $num = $X->B<num>(I<$typename>,I<$nameornum>)

Where I<$typename> is a symbolic constant type name like C<Bool> or
C<XkbBoolCtrl>, and I<$nameornum> is a symbolic constant name under
I<$typename> or a simple number.  The number corresponding to the
symbolic constant name is returned.

B<X11::Protocol::Enhanced> also overrides the L<X11::Protocol(3pm)>
B<num> method with this method.  (The L<X11::Protocol(3pm)> B<num>
method cannot handle special names for only a few values.>

=cut
sub pack_enum($$) {
    my $self = shift;
    my ($typename,$x) = @_;
    my $type = $self->{const_num}{$typename};
    $type = $self->{ext_const_num}{$typename} unless $type;
    if (not $type) {
        if ($self->{const}{$typename}) {
            $type = $self->{const_num}{$typename} =
            {make_num_hash($self->{const}{$typename})};
        }
        elsif ($self->{ext_const}{$typename}) {
            $type = $self->{ext_const_num}{$typename} =
            {make_num_hash($self->{ext_const}{$typename})};
        }
    }
    return $self->{const_num}{$typename}{$x}
	if exists $self->{const_num}{$typename}{$x};
    return $self->{ext_const_num}{$typename}{$x}
	if exists $self->{ext_const_num}{$typename}{$x};
    return $x;
}

*X11::Protocol::pack_enum =
\&X11::Protocol::Enhanced::pack_enum;

*X11::Protocol::num =
\&X11::Protocol::Enhanced::pack_enum;

=item $nameornum = $X->B<unpack_enum>(I<$typename>,I<$num>)

=item $nameornum = $X->B<do_interp>(I<$typename>,I<$num>)

Where I<$typename> is a symbolic constnat type name like C<Bool> or
C<XkbControl>, and I<$num> is a simple number.  The name corresponding
ot the symbolic constant is returned if it is defined, and the number is
returned otherwise.

B<X11::Protocol::Enhanced> also overrides the L<X11::Protocol(3pm)>
B<do_interp> method with this method.  (The L<X11::Protocol(3pm)>
B<do_interp> method cannot handle special names for only a few values.>

=cut
sub unpack_enum {
    my $self = shift;
    my ($typename,$num) = @_;
    if ($self->{do_interp}) {
        return $num if $num < 0;
	if ($self->{const}{$typename} and
		defined($self->{const}{$typename}[$num])) {
	    $num = $self->{const}{$typename}[$num];
	}
	elsif ($self->{ext_const}{$typename} and
		defined($self->{ext_const}{$typename}[$num])) {
	    $num = $self->{ext_const}{$typename}[$num];
	}
    }
    return $num;
}

*X11::Protocol::unpack_enum =
\&X11::Protocol::Enhanced::unpack_enum;

*X11::Protocol::do_interp =
\&X11::Protocol::Enhanced::unpack_enum;

=item $nameornum = $X->B<interp_enum>(I<$typename>,I<$num>)

=item $nameornum = $X->B<interp>(I<$typename>,I<$num>)

Like B<unpack_enum>, but only unpacks the enumeration when the
C<do_interp> flag is set on C<$X>.

B<X11::Protocol::Enhanced> also overrides the L<X11::Protocol(3pm)>
B<interp> method with this method.  (The L<X11::Protocol(3pm)> method
cannot handle special names for only a few values.)

=cut
sub interp_enum {
    my $self = shift;
    my ($typename,$num) = @_;
    return $self->unpack_enum(@_) if $self->{do_interp};
    return $num;
}

*X11::Protocol::interp =
\&X11::Protocol::Enhanced::interp_enum;

=back

=cut

1;

=head1 AUTHOR

Brian Bidulock <bidulock@cpan.org>

=head1 SEE ALSO

L<X11::Protocol(3pm)>,
L<X11::Protocol::Ext::XKEYBOARD(3pm)>,
L<X11::Protocol::Ext::RANDR(3pm)>,
L<X11::Protocol::Ext::SYNC(3pm)>.

=cut

# vim: sw=4 tw=72



