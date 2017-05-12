package Tie::Array::Pointer;

use strict;
use vars qw($VERSION);
use base qw(Tie::Array DynaLoader);

$VERSION = '0.000059';

Tie::Array::Pointer->bootstrap($VERSION);

#
sub TIEARRAY {
  my $class = shift;
  my $opt   = shift;
  my $self  = { %$opt };
  bless($self, __PACKAGE__);

  if ($self->address) {
    $self->{allocated} = 0;
  } else {
    my $addr = tsp_malloc($self->{length} * 4);
    die('Memory could not be allocated') if (!$addr);
    $self->{address} = $addr;
    $self->{allocated} = 1;
  }

  return $self;
}

sub DESTROY {
  my $self = shift;
  if ($self->{allocated}) {
    tsp_free($self->{address});
  }
}

#
sub FETCH {
  my $self = shift;
  my $n    = shift;
  my $type = $self->{type};

  my $int;
  if ($type eq 'c' || $type eq 'C') {
    $int = tsp_r8($self->{address} + $n);
  } elsif ($type eq 's' || $type eq 'S') {
    $int = tsp_r16($self->{address} + $n * 2);
  } elsif ($type eq 'l' || $type eq 'L') {
    $int = tsp_r32($self->{address} + $n * 4);
  }

  return $int;
}

#
sub FETCHSIZE {
  return $_[0]->{length};
}

#
sub STORE {
  my $self = shift;
  my $n    = shift;
  my $val  = shift;

  my $type = $self->{type};
  my $int;
  if ($type eq 'c' || $type eq 'C') {
    $int = tsp_w8($self->{address} + $n, $val);
  } elsif ($type eq 's' || $type eq 'S') {
    $int = tsp_w16($self->{address} + $n * 2, $val);
  } elsif ($type eq 'l' || $type eq 'L') {
    $int = tsp_w32($self->{address} + $n * 4, $val);
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
  my $self = shift;
  my $n    = shift;
  $self->STORE($n, 0);
}

sub EXISTS {
  my $self = shift;
  my $n    = shift;
  if ($n < $self->{length}) {
    return 1;
  } else {
    return 0;
  }
}

# base address in memory of C array
sub address {
  return $_[0]->{address};
}

1;

__END__

=head1 NAME

Tie::Array::Pointer - ties a perl array to a C pointer

=head1 SYNOPSIS

Tie to @buffer; allocate 256 * 4 bytes for me:

  use Tie::Array::Pointer;
  my @buffer;
  tie @buffer, 'Tie::Array::Pointer', {
    length => 256,
    type   => 'L',
  };

Tie to @buffer; use memory address I've provided:

  tie @buffer, 'Tie::Array::Pointer', {
    length  => 320 * 200,
    type    => 'c',
    address => 0x000a0000,
  };

Get the memory address of the C array.

  my $addr = tied(@buffer)->address();

=head1 DESCRIPTION

L<Tie::Array::Pointer> ties a Perl array to a C pointer.
This makes it possible for Perl code and C code to share
simple integer arrays.

=head2 Options

When you tie an array to L<Tie::Array::Pointer>, you need to
pass it a hashref that tells it how big the array is and what
the simple integer type each of its elements is.

=over 2

=item length

B<(required)> :: The number of elements in the array.

=item type

B<(required)> :: This is a very small subset of C<pack>
types, which defines whether the array contains 8 bit, 16
bit, or 32 bit integers.  The valid values for this option
are:

  c   signed char      8 bit
  C   unsigned char    8 bit
  s   signed short    16 bit
  S   unsigned short  16 bit
  l   signed long     32 bit
  L   unsigned long   32 bit

=item address

B<(optional)> :: If you specify a memory address using this
option, the act of C<tie>'ing (tying?) will not allocate any
memory.  Instead, we'll trust that you know what you're
doing and that the system will allow reads and writes to
happen to this address.

=head2 Limitations

Don't treat arrays that are tied to this package as normal
Perl arrays.  When you tie arrays to this package, they
really take on the characteristics of a C array.  They
should therefore be treated with the same carefulness
that a C array would.

In future versions of this module, some of these limitations
may be lifted, but don't hold your breath.

=head3 Typical perl array ops are unavailable.

You cannot C<push>, C<pop>, C<shift>, or C<unshift> on these arrays.

=head3 You can't access indices beyond what you have allocated.

You cannot access indices beyond the memory you have allocated.
For example, consider the following code:

  tie my @buffer, 'Tie::Array::Pointer', {
    length => 32,
    type   => 's',
  };
  $buffer[235355] = 5;

Here we allocated a 32 element array, but then we tried to assign something
into the 235355th element of this array.  B<THIS WILL SEGFAULT.>

=head3 Only integer values are allowed.

Please don't try to assign anything besides an integer to an
element.  That means no strings and no references and no
floats.

=head1 METHODS

=head2 address

This method returns the address of the beginning of the
C array that the tied array represents.

B<Example>:

  my $addr = tied(@buffer)->address;

=head1 DIAGNOSTICS

=over 2

=item "not allowed (yet)"

This means that you tried to do something that we haven't
implemented.  For example, you might've tried to unshift a
value into an array.  I don't even want to think about how
I'd implement that, so it'll die on you if you try.

=back

=head1 TO DO

=over 2

=item More error checking in TIEARRAY

=item At least allow resizing of arrays?

I'll do this if someone asks.

=item shift unshift push pop

I don't really want to implement them, but....

=back

=head1 AUTHOR

John BEPPU E<lt>beppu@cpan.orgE<gt>

=head1 SEE ALSO

L<Term::Caca>

=cut
