package Tie::Array::Pack;
#
# $Id: Pack.pm,v 0.2 2006/12/22 03:20:22 dankogai Exp $
#
use 5.008001;
use strict;
use warnings;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.2 $ =~ /(\d+)/g;
use Carp;

# we don't need Tie::Array anymore -- all methods implemented!
# use base 'Tie::Array';
use bytes ();

our $DEBUG = 0;

sub DESTROY { }    # no-op

sub TIEARRAY {
    my $class = shift;
    my $fmt   = shift;
    my $empty = shift || 0;
    my $size  = eval { bytes::length( pack( $fmt, $empty ) ) };
    croak $@ if $@;
    bless {
        str   => '',
        fmt   => $fmt,
        size  => $size,
        empty => $empty
    };
}

sub FETCH {
    $DEBUG and warn sprintf "%s->FETCH(%d)", @_;
    unpack( $_[0]->{fmt},
        substr( $_[0]->{str}, $_[0]->{size} * $_[1], $_[0]->{size} ) );
}

sub FETCHSIZE {
    $DEBUG and warn sprintf( "%s->FETCHSIZE", $_[0] );
    use integer;
    bytes::length( $_[0]->{str} ) / $_[0]->{size};
}

sub STORE {
    my ( $this, $index, $value ) = @_;
    $DEBUG and warn "$this->STORE($index, $value)";
    my $retval =
        $this->FETCHSIZE - $index < 1
      ? $this->STORESIZE( $index + 1 )
      : $value;
    substr(
        $this->{str}, $this->{size} * $index,
        $this->{size}, pack( $this->{fmt}, $value )
    );
}

sub STORESIZE {
    my ( $this, $count ) = @_;
    $DEBUG and warn "$this->STORESIZE($count)";
    return $this->EXTEND($count) if $this->FETCHSIZE < $count;
    if ( $this->FETCHSIZE > $count ) {
        substr( $this->{str}, $this->{size} * $count, $this->{size}, '' );
    }
    return $count;
}

sub EXISTS {
    my ( $this, $key ) = @_;
    $DEBUG and warn "$this->EXISTS($key)";
    return $this->FETCHSIZE > $key;
}

sub EXTEND {
    my ( $this, $count ) = @_;
    $DEBUG and warn "$this->EXTEND($count)";
    my $extend = $count - $this->FETCHSIZE;
    if ( $extend > 0 ) {
        $this->{str} .= pack( $this->{fmt}, $this->{empty} ) x $extend;
        $this->STORESIZE($count);
    }
    return undef;
}

sub DELETE {
    my ( $this, $index ) = @_;
    $DEBUG and warn "$this->DELETE($index)";
    substr( $this->{str}, $this->{size} * $index, $this->{size}, '' );
}

sub CLEAR {
    my ( $this, $index ) = @_;
    $DEBUG and warn "$this->CLEAR";
    $this->{str} = '';
}

sub PUSH {    # append
    my $this = shift;
    if ($DEBUG) {
        local ($") = ",";
        warn "$this->PUSH(@_)";
    }
    $this->{str} .= pack( $this->{fmt} x @_, @_ );
}

sub UNSHIFT {    # prepend
    my $this = shift;
    if ($DEBUG) {
        local ($") = ",";
        warn "$this->UNSHIFT(@_)";
    }
    $this->{str} = pack( $this->{fmt} x @_, @_ ) . $this->{str};
}

sub POP {
    my $this = shift;
    $DEBUG and warn "$this->POP";
    my $val;
    my $newsize = $this->FETCHSIZE - 1;
    if ( $newsize >= 0 ) {
        $val = $this->FETCH($newsize);
        $this->STORESIZE($newsize);
    }
    $val;
}

sub SHIFT {
    my $this = shift;
    $DEBUG and warn "$this->SHIFT";
    my $val;
    my $newsize = $this->FETCHSIZE - 1;
    if ( $newsize >= 0 ) {
        $val = $this->FETCH(0);
        $this->DELETE(0);
    }
    $val;
}

sub SPLICE {
    my $this = shift;
    if ($DEBUG) {
        local ($") = ",";
        warn "$this->SPLICE(@_)";
    }
    my $off = (@_) ? shift: 0;
    $off += $this->FETCHSIZE if ( $off < 0 );
    my $len = (@_) ? shift: $this->FETCHSIZE - $off;
    $len += $this->FETCHSIZE - $off if $len < 0;
    my @result = unpack(
        $this->{fmt} . $len,
        substr( $this->{str}, $off * $this->{size}, $len * $this->{size} )
    );
    substr(
        $this->{str},
        $off * $this->{size},
        $len * $this->{size},
        pack( $this->{fmt} x @_, @_ )
    );
    return wantarray ? @result : pop @result;
}

1;
__END__

=head1 NAME

Tie::Array::Pack - An array implemented as a packed string

=head1 SYNOPSIS

  use Tie::Array::Pack
  tie @array, Tie::Array::Pack => 'd';
  $array[$_] = rand() for (1..1e6); # slow but memory-efficient

=head1 INSTALLATION

To install this module type the following as usual.

   perl Makefile.PL
   make
   make test
   make install

=head1 DESCRIPTION

One of the drawbacks for using Perl's native array is that it is a
memory-hog.  Normally it takes 20 bytes a scalar (16 bytes for scalar
+ overhead).  This can be a problem when you need to handle millions
of numbers in-memory.  This module saves memory in exchange for speed.

With this module all you have to do is

  tie @array, Tie::Array::Pack => $fmt

where $fmt is one of the following that is supported by pack().

    c   A signed char value.
    C   An unsigned char value.
    s   A signed short value.
    S   An unsigned short value.
    i   A signed integer value.
    I   An unsigned integer value.
    l   A signed long value.
    L   An unsigned long value.
    n   An unsigned short in "network" (big-endian) order.
    N   An unsigned long in "network" (big-endian) order.
    v   An unsigned short in "VAX" (little-endian) order.
    V   An unsigned long in "VAX" (little-endian) order.
    q   A signed quad (64-bit) value.
    Q   An unsigned quad value.
    j   A signed integer value (a Perl internal integer, IV).
    J   An unsigned integer value (a Perl internal unsigned integer, UV).
    f   A single-precision float in the native format.
    d   A double-precision float in the native format.
    F   A floating point value in the native native format
    D   A long double-precision float in the native format.

If the format is not supported, it simply croaks.

=head2 EXPORT

None.

=head2 EMPTY ELEMENT

You can optionally specify the value which spefies the empty element
as follows;

  tie @array, Tie::Array::Pack => l, -1; # -1 represents an empty value;

The default value is 0.  Since this stores data in the packed string,
the array is never sparse.  To illustrate the issue, try the
following;

  tie @array, Tie::Array::Pack => d;
  $array[4] = 2;
  print join(",", @array), "\n" # 0,0,0,0,2;

=head2 PICK THE RIGHT FORMAT

Another issue is that you need to pick the right format or you will
get an unexpected result.

  tie @array, Tie::Array::Pack => C;
  @array = (251..260);
  print join(",", @array), "\n" # 251,252,253,254,255,0,1,2,3,4

In this case, the warning is issued.

=head2 HOW SLOW IS IT?

Since this module has to pack() for each STORE and unpack() for each
FETCH, it is much slower than the native array.  Still it is as fast
as in-memory DB_File (with $DB_RECNO) and much, much faster than
Tie::File.  Below is the result on my MacBook Pro.

=over 2

=item n = 1000

           Rate    T::F DB_File T::A::P  native
 T::F    3.80/s      --    -98%    -98%   -100%
 DB_File  158/s   4049%      --     -4%    -92%
 T::A::P  164/s   4209%      4%      --    -92%
 native  2058/s  54016%   1204%   1156%      --

=item n = 10000

           Rate    T::F DB_File T::A::P  native
 T::F    1.06/s      --    -93%    -93%    -99%
 DB_File 15.8/s   1393%      --     -1%    -92%
 T::A::P 15.9/s   1409%      1%      --    -92%
 native   194/s  18248%   1129%   1116%      --

=back

=head1 SEE ALSO

=over 2

=item In Perl Core:

L<perltie>, L<perlpacktut>, L<Tie::Array>, L<Tie::File>, L<DB_File>

=item On CPAN

L<Tie::Array::Packed> and L<Tie::Array::PackedC> - Almost identical
except for the interfaces.  This module is simpler and pure-perl only.

=back

=head1 AUTHOR

Dan Kogai, E<lt>dankogai@dan.co.jp<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dan Kogai

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
