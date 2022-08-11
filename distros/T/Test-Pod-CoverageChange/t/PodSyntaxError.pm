package t::PodSyntaxError;

use strict;
use warnings;

=head2 bar

This pod has a syntax error. (=over has no =back to close)

=over 4

=item * C<P> a sample parameter

=cut

sub foo { }
sub bar { }
sub baz { }

1;
