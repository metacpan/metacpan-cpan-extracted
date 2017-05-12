package Tie::Array::Packed;

our $VERSION = '0.13';

use strict;
use warnings;
use Carp;

require XSLoader;
XSLoader::load('Tie::Array::Packed', $VERSION);

my @short = qw(c C F f d i I j J s! S! l! L! n N v V q Q e E);

my %map = ( Char => 'c',
            UnsignedChar => 'C',
            Hex => 'h',
            NV => 'F',
            Number => 'F',
            FloatNative => 'f',
            DoubleNative => 'd',
            Integer => 'j',
            UnsignedInteger => 'J',
            IntegerPerl => 'j',
            IV => 'j',
            UnsignedIntegerPerl => 'J',
            UV => 'J',
            IntegerNative => 'i',
            UnsignedIntegerNative => 'I',
            ShortNative => 's!',
            UnsignedShortNative => 'S!',
            LongNative => 'l!',
            UnsignedLongNative => 'L!',
            UnsignedShortNet => 'n',
            UnsignedShortBE => 'n',
            UnsignedLongNet => 'N',
            UnsignedLongBE => 'N',
            UnsignedShortVax => 'v',
            UnsignedShortLE => 'v',
            UnsignedLongVax => 'V',
            UnsignedLongLE => 'V',
            Quad => 'q',
            UnsignedQuad => 'Q',
            LongLong => 'q',
            UnsignedLongLong => 'Q',
            Int64 => 'q',
            UInt64 => 'Q',
            Int128 => 'e',
            UInt128 => 'E',
          );


@map{@short} = @short;

for my $name (keys %map) {
    my $type = $map{$name};

    no strict 'refs';
    @{"Tie::Array::Packed::${name}::ISA"} = __PACKAGE__;
    *{"Tie::Array::Packed::${name}::TIEARRAY"} =
        sub {
            my $class = shift;
            my $self;
            $self = TIEARRAY($class, $type, defined $_[0] ? $_[0] : '');
            if (@_ > 1) {
                shift;
                $self->SPLICE(0, scalar(@_), @_);
            }
            $self;
        };
}

sub make {
    my $class = shift;
    tie my(@self), $class, '', @_;
    return \@self
}

sub make_with_packed {
    my $class = shift;
    tie my(@self), $class, @_;
    return \@self
}

sub make_clone {
    my $self = shift;
    tie my(@clone), ref($self), $$self;
    return \@clone;
}

sub string {
    my $self = shift;
    $$self;
}

my $sort_packed_loaded;

sub _load_sort_packed {
    eval { require Sort::Packed };
    croak __PACKAGE__ ."::sort requires package Sort::Packed"
        if ($@ or !$Sort::Packed::VERSION);
    $sort_packed_loaded++
}

sub sort {
    @_ > 2 and croak 'Usage: tied(@parray)->sort([sub { CMP($a, $b) }])';
    $sort_packed_loaded or _load_sort_packed;

    my $self = shift;
    my $packer = $self->packer;
    if (@_) {
        my $cmp = shift;
        &Sort::Packed::sort_packed_custom($cmp, $packer, $$self);
    }
    else {
        &Sort::Packed::sort_packed($packer, $$self);
    }
}


sub shuffle {
    @_ != 1 and croak 'Usage: tied(@parray)->shuffle';
    $sort_packed_loaded or _load_sort_packed;

    my $self = shift;
    Sort::Packed::shuffle_packed($self->packer, $$self)
}

sub grep {
    @_ != 2 and croak 'Usage: tied(@parray)->grep(sub { SELECT($_) })';

    my $self = shift;
    my $select = shift;

    my $last = $self->FETCHSIZE - 1;
    my $slow = 0;
    for my $i (0..$last) {
        for ($self->FETCH($i)) {
            my $cp = $_;
            if (&$select) {
                $self->STORE($slow, $cp) if $slow < $i;
                $slow++
            }
        }
    }
    $self->STORESIZE($slow);
    $slow;
}

1;
__END__

=head1 NAME

Tie::Array::Packed - store arrays in memory efficiently as packed strings

=head1 SYNOPSIS

  use Tie::Array::Packed;

  my (@foo, @bar);
  tie @foo, Tie::Array::Packed::Integer;
  tie @bar, Tie::Array::Packed::DoubleNative;

  $foo[12] = 13;
  $bar[1] = 4.56;

  pop @foo;
  @some = splice @bar, 1, 3, @foo;

=head1 DESCRIPTION

This module provides an implementation for tied arrays that uses as
storage a Perl scalar where all the values are packed as if the
C<pack> builtin had been used.

All the values on a Tie::Array::Packed array are of the same value
(integers, shorts, doubles, etc.)

The module is written in XS for speed. Tie::Array::Packed arrays are
approximately 15 times slower than native ones (for comparison to a
pure Perl implementation, arrays tied with L<Tie::Array::PackedC> are
around 60 times slower than native arrays).

On the other hand, packed arrays use between 4 and 12 times less
memory that the native ones.

=head1 USAGE

Tie::Array::Packed defines a set of classes that can be used to tie
arrays. The classes have names of the form:

  Tie::Array::Packed::<Type>

and are as follows:

                                           pack      C
            class name                    pattern   type
  --------------------------------------------------------------------
  Tie::Array::Packed::Char                   c     char
  Tie::Array::Packed::UnsignedChar           C     unsigned char
  Tie::Array::Packed::NV                     F     NV
  Tie::Array::Packed::Number                 F     NV
  Tie::Array::Packed::FloatNative            f     float
  Tie::Array::Packed::DoubleNative           d     double
  Tie::Array::Packed::Integer                j     IV
  Tie::Array::Packed::UnsignedInteger        J     UV
  Tie::Array::Packed::IntegerNative          i     int
  Tie::Array::Packed::UnsignedIntegerNative  I     unsigned int
  Tie::Array::Packed::ShortNative            s!    short
  Tie::Array::Packed::UnsignedShortNative    S!    unsigned short
  Tie::Array::Packed::LongNative             l!    long
  Tie::Array::Packed::UnsignedLongNative     L!    unsigned long
  Tie::Array::Packed::UnsignedShortNet       n     -
  Tie::Array::Packed::UnsignedShortBE        n     -
  Tie::Array::Packed::UnsignedLongNet        N     -
  Tie::Array::Packed::UnsignedLongBE         N     -
  Tie::Array::Packed::UnsignedShortVax       v     -
  Tie::Array::Packed::UnsignedShortLE        v     -
  Tie::Array::Packed::UnsignedLongVax        V     -
  Tie::Array::Packed::UnsignedLongLE         V     -

If your Perl was compiled with 64bit support or the module
L<Math::Int64> is installed, then the following two classes are also
available:

                                          pack      C
            class name                    pattern   type
  --------------------------------------------------------------------
  Tie::Array::Packed::Quad                   q     int64_t
  Tie::Array::Packed::UnsignedQuad           Q     uint64_t

If your C compiler supports 128bit integers and the module
L<Math::Int128> is installed, then the following two classes are also
available:

                                          pack      C
            class name                    pattern   type
  --------------------------------------------------------------------
  Tie::Array::Packed::Int128                 e     int128_t
  Tie::Array::Packed::UInt128                E     uint128_t



The tie interface for all these classes is as follows
(Tie::Array::Packed::Integer is used as an example):

  tie @foo, Tie::Array::Packed::Integer;
  tie @foo, Tie::Array::Packed::Integer, $init_string, @values


When a scalar value C<$init_string> is passed as an argument
it is used as the initial value for the storage scalar.

Additional arguments are used to initialize the array, for instance:

  tie @foo, Tie::Array::Packed::Char, '', 1, 2, 3;
  print "@foo"; # prints "1 2 3"

  tie @bar, Tie::Array::Packed::Char, 'hello';
  print "@bar"; # prints "104 101 108 108 111"

  tie @doz, Tie::Array::Packed::Char, 'hello', 1, 2, 3;
  print "@doz"; # prints "1 2 3 108 111";

The underlying storage scalar can be accessed dereferencing the
object returned by tie:

  my $obj = tied(@foo);
  print "storage: ", $$obj;

=head2 METHODS

Those are the methods provided by the classes defined on the module:

=over 4

=item Tie::Array::Packed::Integer->make()

=item Tie::Array::Packed::Integer->make(@init_values)

This class method returns a reference to and array tied to the
class.

Note that the returned array is not blessed into any package.

=item Tie::Array::Packed::Integer->make_with_packed($init_string)

=item Tie::Array::Packed::Integer->make_with_packed($init_string, @init_values)

similar to the method before but gets an additional argument to
initialize the storage scalar.

=item tied(@array)->make_clone;

returns a reference to a tied array that is a clone of C<@array>.

Alternatively, to clone a tied array this idiom can be used:

  my $tied = tied(@array);
  tie my (@clone), ref($tied), $$tied;


=item tied(@foo)->packer

returns the pack template in use for the elements of the tied array
C<@foo>.

=item tied(@foo)->grep(sub { ...})

in-place filter elements that comply with some condition.

=item tied(@foo)->reverse()

reverses the order of the elements packed into the array

=item tied(@foo)->rotate($places)

=item tied(@foo)->sort()

=item tied(@foo)->sort(sub { ...})

=item tied(@foo)->shuffle

See L<Sort::Packed> for the details about these methods.

=item tied(@foo)->bsearch($v)

When called on a sorted packed array, this method uses the binary
search algorithm to find and return the index of the given value.

Returns undef if the value is not found.

Note that the method does not check if the array is ordered.

=item tied(@foo)->bsearch_le($v)

Similar to C<bsearch>, returns the index of the biggest
element equal to the given value or lesser.

Returns undef when all the values on the packed array are bigger than
the given value.

=item tied(@foo)->bsearch_ge($v)

Similar to C<bsearch>, returns the index of the smallest
element equal to the given value or greater.

Returns undef when all the values on the packed array are smaller than
the given value.

=back

=head1 BUGS AND SUPPORT

In order to report bugs you can send me and email to the address that
appears below or use the CPAN RT bugtracking system available at
L<http://rt.cpan.org>.

The source for the development version of the module is hosted at
GitHub: L<https://github.com/salva/p5-Tie-Array-Packed>.

=head2 My wishlist

If you like this module and you're feeling generous, take a look at my
Amazon Wish List: L<http://amzn.com/w/1WU1P6IR5QZ42>

=head1 SEE ALSO

Documentation for Perl builtins L<pack> and L<vec>.

L<Tie::Array::PackedC> offers very similar functionality, but it is
implemented in pure Perl and so it is slower.

L<Tie::Array::Packed::Auto> is a wrapper module that loads
Tie::Array::Packed when available, otherwise it uses
Tie::Array::PackedC to provide an identical API.

L<Array::Packed> is implemented in C but only supports integer values.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2008, 2011-2013 by Salvador FandiE<ntilde>o
(sfandino@yahoo.com).

Some parts copied from Tie::Array::PackedC (C) 2003-2006 by Yves
Orton.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
