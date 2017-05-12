package TestModule;

use strict;
use warnings;


sub new {
  my $package = shift;
  my $class = ref($package) || $package;

  my $self = {@_};
  bless($self, $class);

  return $self;
}

sub one     { return 1;                   }
sub two     { return 2;                   }
sub three   { return 3;                   }
sub rooster { return 'cock-a-doodle-doo'; }

1;
