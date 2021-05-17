#!perl

use strict;

my ( $dothis, $code ) = @ARGV;

if ( $dothis eq 'die' ) {
  die 'Instructed to DIE!';
} elsif ( $dothis eq 'fail' ) {
  print STDERR "Exit: $code\n";
  exit( $code );
} else {
  print STDOUT "I lived\n";
  exit(0);
}
