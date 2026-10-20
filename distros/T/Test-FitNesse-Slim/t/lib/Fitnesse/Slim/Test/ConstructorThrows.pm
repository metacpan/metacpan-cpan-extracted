package Fitnesse::Slim::Test::ConstructorThrows;

use strict;
use warnings;

sub new {
  my($class,$message) = @_;
  die "fitnesse.slim.test.StopTestException: $message\n"
    if defined($message) && $message eq 'stop test';
  die "fitnesse.slim.test.StopSuiteException: $message\n"
    if defined($message) && $message eq 'stop suite';
  die "java.lang.RuntimeException: " . (defined($message) ? $message : 'null') . "\n";
}

1;
