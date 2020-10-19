package Foo;

use strict;
use warnings;

use Text::Indent::Tiny;

sub greet {
	Text::Indent::Tiny->instance->item(__PACKAGE__ . ": Hi, main!");
}

1;
