package t::Utils;

use strict;
use warnings;

sub import {
    strict->import;
    warnings->import;
}

1;

package t::Foo;
sub new { bless {}, shift }
sub bar { return 'bar' }
sub baz { return 'baz' }

package t::Bar;
sub new { bless {}, shift }
sub foo { return 'foo' }
sub baz { return 'baz' }

1;
