#!/usr/bin/perl

use strict;
use warnings;


my $num = 3;
my $add = 4;

sub addnum {
  my $num = shift;
  my $add = shift;
  return $num + $add;
}
