package MyObj::Sub;

use strict;
use warnings;

my $test;

BEGIN { $test = $^X }

my $sub = sub { my $self = shift; };

sub new {
  my( $self, $args ) = @_;
}

sub do_it {
  return "It's done!\n";
}
