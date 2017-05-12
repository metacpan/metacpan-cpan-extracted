package Tie::NumRange;

$VERSION = '0.021';


sub TIESCALAR {
  my $class = shift;
  my $self = bless [ @_ ], $class;
  $self->STORE($_[0]);  # just in case
  return $self;
}


sub STORE {
  my ($self,$val) = @_;

  return $self->[0] = $self->[1] if
    defined($self->[1]) and
    $self->[1] > $val;

  return $self->[0] = $self->[2] if
    defined($self->[2]) and
    $self->[2] < $val;

  return $self->[0] = $val;
}


sub FETCH { $_[0][0] }



package Tie::NumRange::Wrap;

sub TIESCALAR {
  my $class = shift;
  die "tie()ing to $class requires a lower and upper bound" if
    grep !defined, @_[1,2];
  my $self = bless [ @_ ], $class;
  $self->STORE($_[0]);  # just in case
  return $self;
}


sub STORE {
  my ($self,$val) = @_;

  $val += $self->[2] - $self->[1] while $val < $self->[1];
  $val -= $self->[2] - $self->[1] while $val > $self->[2];

  return $self->[0] = $val;
}


sub FETCH { $_[0][0] }


1;

__END__

=head1 NAME

Tie::NumRange - Keeps a number within a range of values.

=head1 SYNOPSIS

  use Tie::NumRange;
  
  tie my($chr), Tie::NumRange => (
    100,  # initial
    0,    # min
    255,  # max
  );
  
  $chr *= 3;  # $chr is 255
  $chr = -5;  # $chr is 0
  
  tie my($positive), Tie::NumRange => (
    1,
    1,
    undef
  );
  
  $positive = 2**16;  # ok
  $positive = 0;      # $pos is 1
  
  
  tie my($wrap), Tie::NumRange::Wrap => (
    0,   # initial
    0,   # min
    10,  # max
  );
  
  while ($wrap < 10) {
    # 0, 3, 6, 9, 2, 5, 8, 1, 4, 7
    $wrap += 3;
  }

=head1 DESCRIPTION

This module institutes a range of values for a number.  The lower and upper
bounds can be unlimited by passing C<undef> in their place.

=head2 C<Tie::NumRange> Constructor

  tie $number, Tie::NumRange => ($init, $min, $max);

If C<$min> is C<undef>, the number has no lower bound.  Likewise for C<$max>.

=head2 C<Tie::NumRange::Wrap> Constructor

  tie $number, Tie::NumRange::Wrap => ($init, $min, $max);

Neither range can be C<undef>.  The value will wrap around when it goes
outside the stated bounds.

=head1 AUTHOR

  Jeff "japhy" Pinyan
  CPAN ID: PINYAN
  japhy@pobox.com
  http://www.pobox.com/~japhy/

=cut
