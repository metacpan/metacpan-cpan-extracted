
package Base;

use strict;
use warnings;

use generics default_params => (
	TEST => 100,
	TEST_2 => sub { "Hello World" }
	);

sub new {
	return bless {} => ref($_[0]) || $_[0];
}

1;

__DATA__