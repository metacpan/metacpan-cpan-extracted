package Fitnesse::Slim::Test::TestQuery;

# Adapted from FitNesse v20251025's fitnesse.slim.test.TestQuery.
# Copyright (C) 2003-2009 by Object Mentor, Inc. All rights reserved.
# Released under the terms of the CPL Common Public License version 1.0.
# See LICENSE.CPL and THIRD-PARTY-NOTICES.md.

sub new {
  my($class,$n) = @_;
  bless {n => $n} => $class;
}

sub clone_symbol {
  my($self,$symbol) = @_;
  $symbol;
}

sub free_symbol {
  my($self,$symbol) = @_;
  $symbol;
}

sub query {
  my($self) = @_;
#   [
#     [[n => 1],  ["2n" => 2]],
#     [[n => 2],  ["2n" => 4]],
#   ];
  [ map { [[n => $_], ["2n" => 2 * $_]] } 1 .. $self->{n} ];
}

1;
