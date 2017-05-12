package Text::Decorator::Filter::Test;

use base 'Text::Decorator::Filter';

use strict;

=head2 filter_text

This is a simple filter that will only really be used in tests.

=cut

sub filter_text {
	s/\S/x/g;
}

1;
