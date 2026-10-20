package Fitnesse::Fixtures::DuplicateRows;

use strict;
use warnings;

sub new {
  my($class,$phase) = @_;
  bless { phase => $phase } => $class;
}

sub query {
  my($self) = @_;
  die "Cannot compare null phase" unless defined $self->{phase};

  my @rows = $self->{phase} =~ /\AA\z/i
    ? qw(
        SuiteChildOne.SuiteSetUp
        SuiteChildOne.TestOneOne
        SuiteChildOne.TestOneTwo
        SuiteChildOne.SuiteTearDown
        SuiteChildOne.SuiteSetUp
        SuiteChildOne.TestOneThree
        SuiteChildOne.SuiteTearDown
      )
    : qw(
        SuiteChildOne.SuiteSetUp
        SuiteChildOne.TestOneThree
        SuiteChildOne.SuiteTearDown
        SuiteChildOne.SuiteSetUp
        SuiteChildOne.TestOneOne
        SuiteChildOne.TestOneTwo
        SuiteChildOne.SuiteTearDown
      );

  return [ map { [['x', $_]] } @rows ];
}

1;
