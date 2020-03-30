package ExampleClass;

use strict;
use warnings;

sub new {
  my ($class, %args) = @_;
  bless \%args, $class;
}

sub foo { return "foo" }

sub bar { return join(' ', ("bar") x ($_[0]->{bars}||1)) }

1;
