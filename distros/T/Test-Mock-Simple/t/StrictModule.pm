package StrictModule;

use strict;
use warnings;

sub new {
  my $package = shift;
  my $class = ref($package) || $package;

  my $self = {@_};
  bless($self, $class);

  return $self;
}

1;
