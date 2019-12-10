use strict;
use warnings;

package Local::Example::Module1;

use Test::TraceCalls;
use Scalar::Util qw(blessed);
use namespace::autoclean;

sub foo {
	blessed(1);
	__PACKAGE__ . "->foo";
}

sub bar {
	__PACKAGE__ . "->bar";
}

1;

