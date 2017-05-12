package Tie::VecArray;

use strict;
use vars qw($VERSION);
$VERSION = '0.03';

use POSIX qw(ceil);

use constant BITS => 0;
use constant VEC  => 1;
use constant SIZE => 2;
use base qw(Tie::Array);

# Let's not require Filter::cpp.
BEGIN { eval 'use Filter::cpp' }
sub _IDX2BYTES {
    my Tie::VecArray $self = shift;
    my $idx = shift;
#define _IDX2BYTES($self, $idx) \
    ceil($idx * ($self->[BITS]/8))
}

sub _BYTES2IDX {
    my Tie::VecArray $self = shift;
    my $bytes = shift;
#define _BYES2IDX($self, $bytes) \
    ceil($bytes * 8 / $self->[BITS])
}


=pod

=head1 NAME

  Tie::VecArray - An array interface to a bit vector.


=head1 SYNOPSIS

  require Tie::VecArray;
  
  $vector = '';
  vec($vector, 0, 32) = 33488897;

  # Tie the vector to an array as 8 bits.
  $obj = tie @array, 'Tie::VecArray', 8, $vector;

  @array[0..3] = qw(1 255 256 -1);

  # SURPRISE!  Its 1, 255, 0, 255!
  print @array[0..3];

  # Look at the same vector as a 32 bit vector.
  $obj->bits(32);

  # Back to 33488897
  print $array[0];


=head1 DESCRIPTION

This module implements an array interface to a bit vector.

=head2 Method

=over 4

=item B<tie>

  $vec_obj = tie(@array, 'Tie::VecArray', $bits);
  $vec_obj = tie(@array, 'Tie::VecArray', $bits, $vec);

Creates a new @array tied to a bit vector.  $bits is the number of
bits which will be passed to C<vec()> to interpret the vector.

If $vec is given that will be used as the bit vector, otherwise the
vector will start out empty.

=cut


sub TIEARRAY {
    my($class, $bits, $vec) = @_;

    no strict 'refs';
    my Tie::VecArray $self = bless [], $class;

    $vec = '' unless defined $vec;

    $self->[BITS] = $bits;
    $self->[VEC]  = $vec;
    $self->[SIZE] = _BYTES2IDX($self, length $vec);

    return $self;
}


=pod

=item B<bits>

  $bits = $vec_obj->bits;
  $vec_obj->bits($bits);

Get/set the bit size we'll use to interpret the vector.  

When setting the bit size the length of the array might be ambiguous.
(For instance, going from a one bit vector with five entries to a two
bit vector... do you have two or three entries?)  The length of the
array will always round up.  This can cause odd things to happen.
Consider:

    $vec_obj = tie @vec, 'Tie::VecArray', 1;

    # A one bit vector with 5 entries.
    @vec[0..4] = (1) x 5;

    # prints a size of 5, as expected.
    print scalar @vec;

    # Switch to two bit interpretation.
    $vec_obj->bits(2);

    # This returns 3 since it will round up.
    print scalar @vec;

    # Switch back to one bit.
    $vec_obj->bits(1);

    # Whoops, 6!
    print scalar @vec;

=cut

sub bits {
    my Tie::VecArray $self = shift;
    if(@_) {
        my $bits = shift;
        $self->[SIZE] = ceil($self->[SIZE] * $self->[BITS] / $bits);
        $self->[BITS] = $bits;
    }
    return $self->[BITS];
}


#'#

sub FETCH {
    my Tie::VecArray $self = shift;
    return vec($self->[VEC], $_[0], $self->[BITS]);
}

sub STORE {
    my Tie::VecArray $self = shift;
    $self->[SIZE] = $_[0] + 1 if $self->[SIZE] < $_[0] + 1;
    return vec($self->[VEC], $_[0], $self->[BITS]) = $_[1];
}

sub FETCHSIZE {
    my Tie::VecArray $self = shift;
    return $self->[SIZE];
}

sub STORESIZE {
    my Tie::VecArray $self = shift;
    my $new_size = shift;
    if( $self->[SIZE] > $new_size ) {
        # clip the vector down to size.
        my $new_length = _IDX2BYTES($self, $new_size);
        substr($self->[VEC], $new_length) = '' if 
          $new_length < length $self->[VEC];
    }
        
    $self->[SIZE] = $new_size;
}

sub CLEAR {
    my Tie::VecArray $self = shift;
    $self->[VEC]  = '';
    $self->[SIZE] = 0;
}


=back    

=pod

=head1 CAVEATS

=over 4

=item B<Its slow>

Due to the sluggishness of perl's tie interface, this module is about
8 times slower than using direct calls with C<vec()>.  Suck.  If you
care alot about speed, don't use this module.  If you care about easy
bit vector access or low memory usage, use this module.

=item B<No multidimentional arrays>

$vec_array[$i][$j] = $num; isn't going to work.  A future class will
cover this possibility.

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com>


=head1 SEE ALSO

L<perlfunc/vec>, L<Tie::Array>

=cut

1;
