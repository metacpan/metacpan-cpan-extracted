package Fitnesse::Slim::Test::ProtocolMarker;

use strict;
use warnings;

sub new {
  my($class,$path) = @_;
  open my $marker,'>',$path or die "cannot create protocol test marker: $!";
  print {$marker} "executed\n" or die "cannot write protocol test marker: $!";
  close $marker or die "cannot close protocol test marker: $!";
  return bless {},$class;
}

1;
