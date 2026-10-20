package Fitnesse::Slim::Test::IgnoreConstructor;

use strict;
use warnings;

sub new {
  die "fitnesse.slim.SlimIgnoreAllTestsException: constructor ignored\n";
}

1;
