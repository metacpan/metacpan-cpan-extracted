package t::Test::Expander::Boilerplate;

use v5.14;
use warnings
  FATAL    => qw(all),
  NONFATAL => qw(deprecated exec internal malloc newline once portable redefine recursion uninitialized);

sub new {
  my ($class, @args) = @_;

  return bless([\@args], $class);
}

1;
