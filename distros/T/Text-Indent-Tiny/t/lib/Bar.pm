package Bar;

use strict;
use warnings;

use Text::Indent::Tiny;

# Return the own name using indent-1
sub me {
	Text::Indent::Tiny->instance->back->item(__PACKAGE__);
}

1;
