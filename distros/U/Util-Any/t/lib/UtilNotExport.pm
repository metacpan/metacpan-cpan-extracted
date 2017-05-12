package UtilNotExport;

use strict;
use warnings;

use Util::Any -Base;
our $Utils = {
  '-test' => [
    [
      'strict',
      '',
      {
        '-select' => [],
        '.' => sub {
            my($pkg, $class, $func, $args, $kind_args) = @_;
	    Test::More::is($pkg, "UtilNotExport");
	    Test::More::is($class, "strict");
        }
      }
    ]
  ],
};

1;

