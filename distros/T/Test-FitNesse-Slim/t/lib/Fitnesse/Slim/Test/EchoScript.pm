package Fitnesse::Slim::Test::EchoScript;

# Adapted from FitNesse v20251025's fitnesse.slim.test.EchoScript.
# Copyright (C) 2003-2009 by Object Mentor, Inc. All rights reserved.
# Released under the terms of the CPL Common Public License version 1.0.
# See LICENSE.CPL and THIRD-PARTY-NOTICES.md.

use strict;
use warnings;
use Encode qw(encode_utf8);

sub new {
  my($class) = @_;
  bless {} => $class;
}

sub echo {
  my($self,$s) = @_;
  $s;
}

sub echo_to_stdout {
  my($self,$s) = @_;
  print encode_utf8($s), "\n";
  return $s;
}

sub echo_to_stderr {
  my($self,$s) = @_;
  print STDERR encode_utf8($s), "\n";
  return $s;
}

1;
