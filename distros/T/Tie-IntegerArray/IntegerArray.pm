package Tie::IntegerArray;

require 5.6.0;

use strict;
use warnings;
use integer;

our $VERSION = '0.01';

use base 'Tie::Array';

use Bit::Vector;
use Carp qw(croak);

sub TIEARRAY {
  my $pkg = shift;
  my $self = {};

  croak("Tie::IntegerArray : bad call to tie - options must be specifyed as key-value pairs.")
    if (@_ % 2);
  %$self = @_;
  
  # setup defaults
  $self->{size} = 1 unless exists $self->{size};
  $self->{undef} = 0 unless exists $self->{undef};
  $self->{signed} = 1 unless exists $self->{signed};
  $self->{bits} = Bit::Vector->Word_Bits() unless exists $self->{bits};
  $self->{trace} = 0 unless exists $self->{trace};

  # calculate range
  if ($self->{signed}) {
    $self->{min} = ((2 ** ($self->{bits} - 2)) * -1);
    $self->{max} = ($self->{min} * -1) - 1;
  } else {
    $self->{min} = 0;
    $self->{max} = 2 ** $self->{bits};
  }

  # create value vector
  $self->{vec} = Bit::Vector->new($self->{bits} * $self->{size});
  croak("Tie::IntegerArray : unable to create internal Bit::Vector object")
    unless defined $self->{vec};

  # create defined vector
  if ($self->{undef}) {
    $self->{dvec} =  Bit::Vector->new($self->{size});
    croak("Tie::IntegerArray : unable to create internal defined Bit::Vector object")
      unless defined $self->{dvec};
  }

  # create scratch vector for working with individual values
  $self->{svec} = Bit::Vector->new($self->{bits});
  croak("Tie::IntegerArray : unable to create internal scratch Bit::Vector object")
    unless defined $self->{svec};

  return bless($self, $pkg);
}

sub FETCH {
  my $self = shift;
  my $vec = $self->{vec};
  my $svec = $self->{svec};
  my $dvec = $self->{dvec};
  my $index = shift;

  print STDERR "FETCH($index) called.\n" if $self->{trace};

  # get bit_index for this value
  my $bit_index = $index * $self->{bits};

  # extend if necessary
  $self->STORESIZE($index + 1)
    if ($vec->Size() <= $bit_index);

  # check for undef in dvec
  return undef if $self->{undef} and not $dvec->bit_test($index);
  
  # copy into svec and return to_Bin
  $svec->Interval_Copy($vec,0,$bit_index,$svec->Size());
  return $svec->to_Dec();
}

sub STORESIZE {
  my $self = shift;
  my $vec = $self->{vec};
  my $dvec = $self->{dvec};
  my $index = shift;
 
  print STDERR "STORESIZE($index) called.\n" if $self->{trace};

  $vec->Resize($index * $self->{bits});
  $dvec->Resize($index) if $self->{undef};
}
sub EXTEND { goto &STORESIZE; }

sub CLEAR {
  my $self = shift;
  my $vec = $self->{vec};
  my $dvec = $self->{dvec};

  print STDERR "CLEAR() called.\n" if $self->{trace};

  $vec->Resize(0);
  $dvec->Resize(0) if $self->{undef};
}

sub FETCHSIZE {
  my $self = shift;
  my $vec = $self->{vec};

  print STDERR "FETCHSIZE() called.\n" if $self->{trace};

  return $vec->Size() / $self->{bits};
}

sub STORE {
  my $self = shift;
  my $vec = $self->{vec};
  my $svec = $self->{svec};
  my $dvec = $self->{dvec};
  my $index = shift;
  my $value = shift;

  print STDERR "STORE($index, $value) called.\n" if $self->{trace};

  # get bit_index for this value
  my $bit_index = $index * $self->{bits};

  # extend if necessary
  if ($vec->Size() <= $bit_index) {
    $vec->Resize(($index + 1) * $self->{bits});
    $dvec->Resize($index + 1) if $self->{undef};
  }

  # set undef appropriately if required
  if ($self->{undef}) {
    if (defined $value) {
      $dvec->Bit_On($index);
    } else {
      $dvec->Bit_Off($index);
      return undef; # all done if set to undef now
    }
  }

  croak("Tie::IntegerArray : cannot store non-integer value '$value'!")
    unless $value =~ /^-?\d+$/;

  croak("Tie::IntegerArray : Unable to store value '$value' - out of range ($self->{min} - $self->{max})")
    if $value < $self->{min} or $value > $self->{max};

  # store the number in svec and then copy into place
  $svec->from_Dec($value);
  $vec->Interval_Substitute($svec,$bit_index,$self->{bits},0,$self->{bits});

  return $value;
}

sub EXISTS {
  my $self = shift;
  my $vec = $self->{vec};
  my $index = shift;

  print STDERR "EXISTS($index) called.\n" if $self->{trace};

  # get bit_index for this value
  my $bit_index = $index * $self->{bits};

  # does this slot exist?
  return ($bit_index < $vec->Size());
}

sub DELETE {
  my $self = shift;
  my $vec = $self->{vec};
  my $dvec = $self->{dvec};
  my $svec = $self->{svec};
  my $index = shift;

  print STDERR "DELETE($index) called.\n" if $self->{trace};

  # get bit_index for this value
  my $bit_index = $index * $self->{bits};

  # extend if necessary
  return undef if $bit_index >= $vec->Size();

  $vec->Interval_Empty($bit_index,$bit_index + $self->{bits} - 1);
  $dvec->Bit_Off($index) if $self->{undef};
  return 1;
}

1;
__END__

=pod

=head1 NAME

Tie::IntegerArray - provides a tied array of packed integers of any bit length

=head1 SYNOPSIS

  use Tie::IntegerArray;

  # an array of signed 16-bit integers with no undef support and
  # starting room for 100,000 items.  You can expect this to consume a
  # bit more than 200K of memory versus more than 800K for a normal
  # Perl array.
  my @integer_array;
  tie @integer_array, 'Tie::IntegerArray',
     bits => 16,
     signed => 1,
     undef => 0,
     size => 100_000;
  
  # put a value in
  $integer_array[0] = 10;

  # and print it out
  print "Int 0: $integer_array[0]\n";     

  # the full range of array operations are available

=head1 DESCRIPTION

This module provides an array interface to packed array of integers.  A
packed array of integers is useful in situations where you need to
store a large set of integers in as small a space as possible.  Access
to the packed array will be significantly slower than access to a
normal array but for many applications the reduction in memory usage
makes this a good trade-off.

=head1 USAGE

To create an IntegerArray you call tie with a number of optional
arguements.  These arguements let you fine-tune the storage of your
integers.  The simplest C<tie> call uses no options:

  my @integer_array;
  tie @integer_array, 'Tie::IntegerArray';

This will create an array of signed integers with the same size as
native ints on your platform.  By default the array does not support
C<undef> - values are 0 by default.  This may be ideal for many
applications - read below for other options.

=head1 OPTIONS

=over 4

=item * bits (defaults to your machine's int size)

This option specifies how many bits to use to store the integer value.
This setting determines the possible range of your integers.  If you
specify unsigned integers (see below) then the maximum range on your
integers is simply 2^bits.  For example, 8 bits provides an unsigned
range of 0 - 255.

Since the integers are stored in a packed array you can calculate the
size of your array by multiplying the number of items by the number of
bits.

Attempting to store a value into the array that is too large or too
small for the available bit size will cause an error.

=item * signed (defaults to 1)

If you set signed to 1 then your integers will be signed.  This
reduces their positive range by a power of 2 but provides equal
negative range.  For example, an 8 bit signed integer has a range from
-128 - 127.

=item * undef (defaults to 0)

By default IntegerArrays do not support undef.  This means that array
values will be 0 until they are set to some value.  Calling defined()
on an array value will return true if exists() will.  You can change
this by setting undef to 1.  This requires extra memory - 1 bit per
array entry.

=item * size (defaults to 1)

IntegerArrays grow automatically as you add items but you can specify
a size arguement to pre-allocate space.  This will improve performance
for large arrays.

=back 4

=head1 FUTURE PLANS

This module is functionally complete but not yet fully optimized.  It
relies on Tie::Array for the more advanced array functions (push, pop,
etc) and a native implementation could be faster.  If this module
proves at all popular then I will definitely move in that direction.

=head1 CREDITS

Steffen Beyer - Bit::Vector is pure magic.

=head1 AUTHOR

Sam Tregar, sam@tregar.com

=head1 LICENSE

HTML::Template : A module for using HTML Templates with Perl
Copyright (C) 2000 Sam Tregar (sam@tregar.com)

This module is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 1, or (at your option) any later version,
or

b) the "Artistic License" which comes with this module.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this
module, in the file ARTISTIC.  If not, I'll be glad to provide one.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA

=head1 SEE ALSO

Bit::Vector

=cut
