package UnimportTarget;
use warnings;
use strict;

sub foo { 23 }

use namespace::clean::xs;

sub bar { foo() }

package Foo;
no namespace::clean::xs -cleanee => 'UnimportTarget';

package UnimportTarget;
sub baz { bar() }

use namespace::clean::xs;

sub qux { baz() }

1;
