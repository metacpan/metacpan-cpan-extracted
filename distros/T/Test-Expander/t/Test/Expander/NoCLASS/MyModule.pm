package t::Test::Expander::NoCLASS::MyModule;

use strict;
use warnings
  FATAL    => qw( all ),
  NONFATAL => qw( deprecated exec internal malloc newline once portable redefine recursion uninitialized );

sub my_func { return close( 1 ) }

1;
