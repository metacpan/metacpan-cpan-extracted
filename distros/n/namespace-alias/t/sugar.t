use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => 'not implemented yet';
}

my $imported;

{
    package Foo::Bar::Baz;

    sub fun { 'fun' }
    sub met { $_[0] }

    package Foo::Bar::Baz::Qux;

    sub fun { 'fun2' }
    sub met { $_[0] }

    package Foo::Bar::Baz::SomethingElse;
    sub import { $imported = $_[0] }
}

use namespace::alias;

namespace Foo::Bar::Baz as MyAlias;

# could we hook into here? do we even want to?
use MyAlias::SomethingElse;
is $imported, 'Foo::Bar::Baz::SomethingElse', 'use of aliased package';

is MyAlias::fun(), 'fun', 'aliased function call';
is MyAlias->met(), 'Foo::Bar::Baz', 'aliased method call';

# might this be possible?
sub giveback { $_[0] }
is giveback(MyAlias), 'Foo::Bar::Baz', 'aliased bareword';

# sub packages
is MyAlias::Qux->fun, 'fun2', 'aliased function call in sub package';
is MyAlias::Qux->met, 'Foo::Bar::Baz::Qux', 'aliased method call in sub package';

# not a function, so look for package?
is giveback(MyAlias::Qux), 'Foo::Bar::Baz::Qux', 'aliased sub package bareword';

# method name lookups
is "string"->MyAlias::Qux::met(), 'string', 'aliased method dispatch';


done_testing;
