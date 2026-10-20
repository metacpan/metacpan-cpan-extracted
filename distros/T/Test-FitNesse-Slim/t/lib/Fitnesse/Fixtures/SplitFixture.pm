package Fitnesse::Fixtures::SplitFixture;

use strict;
use warnings;

sub new {
  my($class,$schema) = @_;
  bless { schema => $schema } => $class;
}

sub query {
  my($self) = @_;
  die "Cannot split null schema" unless defined $self->{schema};

  # Java's String.split returns one empty item for the empty input, but drops
  # trailing empty items for non-empty input. Perl's default split already
  # drops trailing empties.
  my @lines = $self->{schema} eq '' ? ('') : split /;/, $self->{schema};
  return [ map {
    my @cells = $_ eq '' ? ('') : split /,/, $_;
    [ map { [ '' . ($_ + 1), $cells[$_] ] } 0 .. $#cells ];
  } @lines ];
}

1;
