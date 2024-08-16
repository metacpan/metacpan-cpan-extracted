package
  MyBackendFOOBAR;
use strict;
use warnings;

if (eval { require MissingUnknownModuleFooBarBaz }) {
  # use it
} else {
  # do fallback
}

sub never_reached {"here"}

1;
