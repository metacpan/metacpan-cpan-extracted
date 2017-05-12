package Tie::Array::Unique;

use constant DIFF => 2;
use Carp;

$VERSION = '0.01';


sub TIEARRAY {
  my $class = shift;
  my $self = bless [ {}, 0 ], $class;

  $self->[1] = shift @_
    if UNIVERSAL::isa($_[0], 'Tie::Array::Unique::How');

  $self->[0]{ $self->[1] ? $self->[1]->($_) : $_ }++ or push @$self, $_
    for @_;

  return $self;
}


sub CLEAR {
  my ($self) = @_;
  splice @$self, 2;
  $self->[0] = {};
}


sub FETCHSIZE {
  my ($self) = @_;
  return @$self - DIFF;
}


sub STORESIZE {
  croak "STORESIZE not implemented on unique arrays";
}


sub EXTEND { }


sub FETCH {
  my ($self, $idx) = @_;
  return $self->[$idx + DIFF];
}


sub STORE {
  my ($self, $idx, $value) = @_;

  # $old is true if this is not a new index to the array
  my $old = $idx < @$self - DIFF;

  # $dup is true if this value will be a duplicate
  my $dup = $self->[0]{ $self->[1] ? $self->[1]->($value) : $value };

  # if we're adding a NEW element and it's a duplicate, don't bother
  return $value if $dup and not $old;

  my $r = \$self->[$idx + DIFF];

  # remove old element
  delete $self->[0]{ $self->[1] ? $self->[1]->($$r) : $$r } if $old;

  $$r = $value;

  # add new one
  $self->[0]{ $self->[1] ? $self->[1]->($$r) : $$r } = 1;

  # if it was a duplicate, get rid of the older value
  if ($dup) {
    for (my $i = 2; $i < @$self; ++$i) {
      if (($self->[1] ? $self->[1]->($self->[$i]) : $self->[$i]) eq ($self->[1] ? $self->[1]->($value) : $value) and $i != DIFF + $idx) {
        splice @$self, $i, 1;
        last;
      }
    }
  }

  return $value;
}


sub PUSH {
  my $self = shift;

  $self->[0]{ $self->[1] ? $self->[1]->($_) : $_ }++ or push @$self, $_ for @_;
  return @$self - DIFF;
}


sub POP {
  my ($self) = @_;
  return if @$self == DIFF;

  # remove element
  delete $self->[0]{ $self->[1] ? $self->[1]->($self->[-1]) : $self->[-1] };
  return pop @$self;
}


sub UNSHIFT {
  my $self = shift;
  $self->[0]{ $self->[1] ? $self->[1]->($_) : $_ }++ 
    or splice @$self, DIFF, 0, $_ for reverse @_;
  return @$self - DIFF;
}


sub SHIFT {
  my ($self) = @_;
  return if @$self == DIFF;

  # remove element
  delete $self->[0]{ $self->[1] ? $self->[1]->($self->[DIFF]) : $self->[DIFF] };
  return splice @$self, DIFF, 1;
}


sub SPLICE {
  my $self = shift;
  my $idx = DIFF + shift;
  my $len = shift;

  my @removed = defined($len) ?
    splice(@$self, $idx, $len) :
    splice(@$self, $idx);
  delete @{$self->[0]}{map { $self->[1] ? $self->[1]->($_) : $_ } @removed};

  if (@_) {
    my %seen;
    my @replace = grep !$seen{ $self->[1] ? $self->[1]->($_) : $_ }++ && !$self->[0]{ $self->[1] ? $self->[1]->($_) : $_ }, @_;
    splice @$self, $idx, 0, @replace;
    @{$self->[0]}{map { $self->[1] ? $self->[1]->($_) : $_ } @replace} = (1) x @replace;
  }

  return @removed;
}  


sub DEFINED {
  my ($self, $idx) = @_;
  return defined $self->[$idx + DIFF];
}


sub EXISTS {
  my ($self, $idx) = @_;
  return exists $self->[$idx + DIFF];
}



package Tie::Array::Unique::How;

sub new {
  my $class = shift;
  Carp::croak("How->new() argument must be code ref")
    unless UNIVERSAL::isa($_[0], "CODE");
  bless $_[0], $class;
}
    

1;

__END__

=head1 NAME

Tie::Array::Unique - Keep array's contents unique

=head1 SYNOPSIS

  use Tie::Array::Unique;

  tie my(@array), 'Tie::Array::Unique';

  tie my(@array), 'Tie::Array::Unique',
    ("this", "this", "that");

  tie my(@array), 'Tie::Array::Unique',
    Tie::Array::Unique::How->new(sub { lc }),
    ("This", "this", "that");

=head1 ABSTRACT

This modules ensures the elements of an array will always be unique.  You
can provide a function defining how to determine uniqueness.

=head1 DESCRIPTION

This is a very simple module.  Use it as shown above, and your array will
never have a duplicate element in it.

The earliest (i.e. lowest-indexed) element has precedence, as shown in this
code sample:

  tie my(@x), 'Tie::Array::Unique';
  @x = (1, 2, 3, 4, 2, 5);  # (1, 2, 3, 4, 5)
  $x[1] = 5;                # (1, 5, 3, 4)
  $x[2] = 1;                # (1, 5, 4)

That last line causes $x[2] to be 1, but then the array is collapsed, which
results in $x[2] getting removed.

=head2 Determining uniqueness

You can provide a wrapper function that converts each element before checking
for uniqueness.  It will not alter the I<actual values> in the array, it only
determines what happens to the value before it is checked for uniqueness.

A simple example is a case-insensitive array:

  tie my(@x), 'Tie::Array::Unique',
    Tie::Array::Unique::How->new(sub { lc shift });
  @x = qw( The man said to the boy );
  # (The, man, said, to, boy)
  $x[1] = 'BOY';
  # (The, BOY, said, to)

=head1 SEE ALSO

Gabor Szabo has written Array::Unique, which is similar.

=head1 AUTHOR

Jeff C<japhy> Pinyan, E<lt>japhy@pobox.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by japhy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

