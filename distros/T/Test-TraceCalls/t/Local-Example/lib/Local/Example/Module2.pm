use strict;
use warnings;

package Local::Example::Module2;

use Local::Example::Module1;
use Test::TraceCalls;

sub xyz { 'xyz' };

sub foo {
	__PACKAGE__ . "->foo";
}

sub bar {
	Local::Example::Module1::bar();
}

1;

