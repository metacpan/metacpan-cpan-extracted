package Fitnesse::Slim::Test::DecisionTableExecuteThrows;

# Adapted from FitNesse v20251025's fitnesse.slim.test.DecisionTableExecuteThrows.
# Copyright (C) 2003-2009 by Object Mentor, Inc. All rights reserved.
# Released under the terms of the CPL Common Public License version 1.0.
# See LICENSE.CPL and THIRD-PARTY-NOTICES.md.

use strict;
use warnings;

sub new {
  my($class,$fail) = @_;
  bless { x => 1, fail => defined($fail) ? $fail : 'execute' } => $class;
}

sub set_which_methods_fail { $_[0]->{fail} = $_[1] }

sub _fails {
  my($self,$method) = @_;
  index($self->{fail}, $method) >= 0
    || lc($self->{fail}) eq 'total disaster';
}

sub _throw_if_configured {
  my($self,$method,$message) = @_;
  die "fitnesse.slim.SlimError: $message\n" if $self->_fails($method);
}

sub x {
  my($self) = @_;
  $self->_throw_if_configured('getX', 'GETX_THROWS');
  $self->{x};
}

sub set_x {
  my($self,$value) = @_;
  $self->_throw_if_configured('setX', 'SETX_THROWS');
  $self->{x} = $value;
}

sub execute    { $_[0]->_throw_if_configured('execute', 'EXECUTE_THROWS') }
sub reset      { $_[0]->_throw_if_configured('reset', 'RESET_THROWS') }
sub begin_table { $_[0]->_throw_if_configured('beginTable', 'BEGINTABLE_THROWS') }
sub end_table   { $_[0]->_throw_if_configured('endTable', 'ENDTABLE_THROWS') }
sub table       { $_[0]->_throw_if_configured('table', 'DOTABLE_THROWS') }

1;
