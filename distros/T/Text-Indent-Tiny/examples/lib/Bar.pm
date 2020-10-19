package Bar;

use strict;
use warnings;

use Text::Indent::Tiny;

sub greet {
	Text::Indent::Tiny->instance->item(__PACKAGE__ . ": Hello, main!");
}

1;
