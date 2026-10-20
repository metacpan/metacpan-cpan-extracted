package Fitnesse::Slim::Test::Library::EchoSupport;

# Adapted from FitNesse v20251025's fitnesse.slim.test.library.EchoSupport.
# Copyright (C) 2003-2009 by Object Mentor, Inc. All rights reserved.
# Released under the terms of the CPL Common Public License version 1.0.
# See LICENSE.CPL and THIRD-PARTY-NOTICES.md.

sub new {
  my($class) = @_;
  bless { echo_called => 0 } => $class;
}

sub echo {
  my($self) = @_;
  $self->{echo_called} = 1;
  return;
}

sub echo_support_called {
  my($self) = @_;
  $self->{echo_called} ? "true" : "false";
}

1;
