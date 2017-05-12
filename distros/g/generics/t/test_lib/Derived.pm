
package Derived;

use strict;
use warnings;

use Session;

use generics inherit => "Base";

use generics default_params => (
	DERIVED_TEST => [1 .. 5]
	);

@Derived::ISA = qw(Base);

1;

__DATA__