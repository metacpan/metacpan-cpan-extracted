use strict;
use warnings;

package Local::Example;

use Local::Example::Module1;
use Local::Example::Module2;
use Test::TraceCalls;

sub quux {
	__PACKAGE__ . "->quux";
}

1;

