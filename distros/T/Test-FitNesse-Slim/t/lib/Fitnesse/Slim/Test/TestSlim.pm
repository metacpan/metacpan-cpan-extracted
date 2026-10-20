package Fitnesse::Slim::Test::TestSlim;

# Adapted from FitNesse v20251025's fitnesse.slim.test.TestSlim.
# Copyright (C) 2003-2009 by Object Mentor, Inc. All rights reserved.
# Released under the terms of the CPL Common Public License version 1.0.
# See LICENSE.CPL and THIRD-PARTY-NOTICES.md.

use strict;
use utf8;
use warnings;
use Scalar::Util qw(refaddr);
use overload
  '""' => 'to_string',
  '==' => sub { refaddr($_[0]) == refaddr($_[1]) },
  '!=' => sub { refaddr($_[0]) != refaddr($_[1]) },
  fallback => 1;

sub new {
  my($class,@args) = @_;
  my $self = bless {
    STRING => undef,
    CTRARG => 0,
  } => $class;

  return $self unless @args;

  if (@args == 1) {
    my($n) = @args;
    $self->{CTRARG} = $n;
    return $self;
  }
  elsif (@args == 2) {
    my($n,$other) = @args;
    $self->{CTRARG} = $n;
    $self->{STRING} = ref($other) ? $other->{STRING} : undef;
    return $self;
  }

  die "unexpected number of arguments (" . scalar(@args) . ")";
}

sub create_test_slim_with_string {
  my($self,$str) = @_;
  my $testslim = ref($self)->new;
  $testslim->set_string($str);
  $testslim;
}

sub get_string_from_other {
  my($self,$other) = @_;
  $other->get_string_arg;
}

sub return_constructor_arg {
  my($self) = @_;
  $self->{CTRARG};
}

sub return_value { "arg" }

sub one_arg {
  my $args = @_ - 1;
  die "unexpected number of argments ($args)"
    unless @_ == 2;
}

# sub echo { @_[1 .. $#_] }

sub echo_int {
  my($self,$i) = @_;
  $i;
}

sub echo_string {
  my($self,$string) = @_;
  $string;
}

sub concatenate_three_args {
  shift;
  join ' ' => @_;
}

sub return_string { "string" }
*returnString = \&return_string;

sub utf8 { "Español" }

sub add { shift; join "", @_ }

sub null { undef }

sub die_inside { die "oops" }

sub throw_normal { die "java.lang.Exception: This is my exception\n" }
sub throw_stopping { die "fitnesse.slim.test.StopTestException: This is a stop test exception\n" }
sub throw_ignore_all_stopping { die "fitnesse.slim.SlimIgnoreAllTestsException: This is an ignore all script test exception\n" }
sub throw_ignore_script_stopping { die "fitnesse.slim.SlimIgnoreScriptTestException: This is an ignore script test exception\n" }
sub throw_normal_mentioning_ignore { die "java.lang.Exception: IgnoreAllTests is only mentioned here\n" }
sub throw_exception_with_message { die "java.lang.Exception: message:<<Test message>>\n" }
sub throw_stop_test_exception_with_message { die "fitnesse.slim.test.StopTestException: message:<<Stop Test>>\n" }

sub set_string {
  my($self,$string) = @_;
  $self->{STRING} = $string;
}

sub get_string_arg {
  my($self) = @_;
  $self->{STRING};
}

sub to_string {
  my($self) = @_;
  "TestSlim: $self->{CTRARG}, " . (defined $self->{STRING} ? $self->{STRING} : "null");
}

sub is_same {
  my($self,$other) = @_;
  return "false" unless ref $other;
  refaddr($other) == refaddr($self) ? "true" : "false";
}

1;
