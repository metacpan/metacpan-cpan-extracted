package FunctionWipeout;
use warnings;
use strict;

use ExporterTest qw( foo qux $foo );

sub bar { foo() }

use namespace::clean::xs -except => [qw( qux )];

sub baz { bar() }

1;
