package Tie::Array::Atomic;

use warnings;
use strict;
use vars qw($VERSION);
use base qw(Tie::Array);
use Devel::Malloc;

$VERSION = '0.01';

my %type_sizes = ( 'C'=>1, 'c'=>1, 'S'=>2, 's'=>2, 'L'=>4, 'l'=>4, 'Q'=>8, 'q'=>8 );

sub TIEARRAY {
  my ($class, $opt) = @_;
  my $self  = { %$opt };

  my $myelement_size = ($self->{type} =~ /^a(\d+)$/) ? $1 : $type_sizes{$self->{type}};
  return if (!defined $myelement_size) || ($myelement_size < 1) || ($myelement_size > 8);
  my $element_size = $myelement_size;
  $element_size = 4 if $element_size == 3;
  $element_size = 8 if ($element_size >= 5) && ($element_size <= 7);
  my $address = _malloc($self->{length} * $element_size) or return;
  $self->{address} = $address;
  $self->{element_size} = $element_size;
  $self->{myelement_size} = $myelement_size;
  $self->{numeric} = (length($self->{type}) == 1);
  $self->{signed} = ($self->{numeric} && (lc($self->{type}) eq $self->{type}));

  bless($self, __PACKAGE__);
  return $self;
}

sub DESTROY {
  my ($self) = @_;

  _free($self->{address}) if $self->{address};
}

#
sub FETCH {
  my ($self, $n) = @_;  

  my $address = $self->{address} + $n * $self->{element_size};
  my $val;
  if ($self->{numeric})
  {
      $val = __sync_fetch_and_or($address, 0, $self->{element_size});
      if (($self->{signed}) && ($val > 0) && ($val >> (8 * $self->{element_size} - 1))) # is negative
      {
        $val = -((~abs($val)&(2**(8*$self->{element_size})-1)) + 1); # 2-way conversion
      }
  } else {
      $val = __sync_load_sv($address, $self->{myelement_size});
  }
  return $val;
}

sub FETCHSIZE {
  return $_[0]->{length};
}

#
sub STORE {
  my ($self, $n, $val) = @_;

  my $address = $self->{address} + $n * $self->{element_size};
  if ($self->{numeric})
  {
     if (($self->{signed}) && ($val < 0)) # is negative
     {
         $val = ~abs($val) + 1; # 2-way conversion
     }
     __sync_lock_test_and_set($address, $val, $self->{element_size});
  } else {
     __sync_store_sv($address, $val, $self->{myelement_size});
  }
  return $val;
}

#
sub STORESIZE {
  die('not allowed (yet)');
}

sub PUSH {
  die('not allowed (yet)');
}

sub POP {
  die('not allowed (yet)');
}

sub SHIFT {
  die('not allowed (yet)');
}

sub UNSHIFT {
  die('not allowed (yet)');
}

sub DELETE {
  die('not allowed (yet)');
}

sub EXISTS {
  my ($self, $n) = @_;  
  
  return ($n < $self->{length});
}

sub add {
  my ($self, $element, $n) = @_;

  __sync_add_and_fetch($self->{address} + $element * $self->{element_size}, $n, $self->{element_size});
}

sub sub {
  my ($self, $element, $n) = @_;

  __sync_sub_and_fetch($self->{address} + $element * $self->{element_size}, $n, $self->{element_size});
}

sub or {
  my ($self, $element, $n) = @_;

  __sync_or_and_fetch($self->{address} + $element * $self->{element_size}, $n, $self->{element_size});
}

sub and {
  my ($self, $element, $n) = @_;

  __sync_and_and_fetch($self->{address} + $element * $self->{element_size}, $n, $self->{element_size});
}

sub xor {
  my ($self, $element, $n) = @_;

  __sync_xor_and_fetch($self->{address} + $element * $self->{element_size}, $n, $self->{element_size});
}

sub nand {
  my ($self, $element, $n) = @_;

  __sync_nand_and_fetch($self->{address} + $element * $self->{element_size}, $n, $self->{element_size});
}


1;

__END__

=head1 NAME

Tie::Array::Atomic - ties a Perl array to a static atomic lock-free C-array

=head1 SYNOPSIS

  # 256 x (unsigned long)
  use Tie::Array::Atomic;
  my @buffer;
  tie @buffer, 'Tie::Array::Atomic', {
    length => 256,
    type   => 'L',
  };

  # 512 x (signed char)
  use Tie::Array::Atomic;
  my @buffer;
  tie @buffer, 'Tie::Array::Atomic', {
    length => 512,
    type   => 'c',
  };

  # 1024 x (char[5]);
  use Tie::Array::Atomic;
  my @buffer;
  tie @buffer, 'Tie::Array::Atomic', {
    length => 1024,
    type   => 'a5',
  };


=head1 DESCRIPTION

L<Tie::Array::Atomic> ties a Perl array to static-sized C-array. Array stored in virtual memory and can be shared between threads.
All operations for array elements are atomic, so no mutexes needed for array synchronization.

=head2 Options

=item length

B<(required)> :: The number of elements in the array.

=item type

B<(required)> :: This is a very small subset of C<pack>
types, which defines whether the array contains 8 bit, 16
bit, 32 bit, 64 bit integers, or byte array up to 8 bytes.
The valid values for this option

are:

  c   signed char      8 bit
  C   unsigned char    8 bit
  s   signed short    16 bit
  S   unsigned short  16 bit
  l   signed long     32 bit
  L   unsigned long   32 bit
  q   signed quad     64 bit
  Q   unsigned quad   64 bit
  a\d  byte array      \d bytes (ex. "a8" will 8 bytes array)
  

=head3 Typical perl array ops are unavailable.

You cannot C<push>, C<pop>, C<shift>, or C<unshift> on these arrays.

=head3 You can't access indices beyond what you have allocated.

You cannot access indices beyond the memory you have allocated.
For example, consider the following code:

  tie my @buffer, 'Tie::Array::Atomic', {
    length => 32,
    type   => 's',
  };
  $buffer[235355] = 5;

Here we allocated a 32 element array, but then we tried to assign something
into the 235355th element of this array.  B<THIS WILL SEGFAULT.>

=head3 Only integer values or short byte arrays are allowed.

Please don't try to assign anything besides an integer or short byte arrays 
to an element.  That means no floats and no references and no long strings.

=head1 METHODS

=head2 add, sub, and, or, xor, nand

This methods returns the result of atomic operation for array element

B<Example>:

  tied(@buffer)->add(5, 1); # atomic increment for $buffer[5]

=head1 AUTHOR

Yury Kotlyarov E<lt>yury@cpan.orgE<gt>

=head1 SEE ALSO

L<Devel::Malloc> L<Tie::Array::Pointer> L<Tie::Array>
