package InheritanceParent;
use warnings;
use strict;

sub foo { 23 }

use namespace::clean;

sub bar { foo() }

package Inheritance;
use warnings;
use strict;

use base 'InheritanceParent';

sub baz { shift->bar }

use namespace::clean;

sub qux { baz(shift) }

1;
