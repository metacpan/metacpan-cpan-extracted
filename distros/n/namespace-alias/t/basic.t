use strict;
use warnings;

use Test::More;

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

use namespace::alias 'Foo::Bar::Baz', 'MyAlias';
use namespace::alias 'Foo::Bar::Baz';

my $x = '';
is 'MyAlias', "My${x}Alias", 'leave strings alone';

# could we hook into here? do we even want to?
#use MyAlias::SomethingElse;
#is $imported, 'Foo::Bar::Baz::SomethingElse', 'use of aliased package';

is MyAlias::fun(), 'fun', 'aliased function call';
is MyAlias->met(), 'Foo::Bar::Baz', 'aliased method call';

is Baz::fun(), 'fun', 'default aliased function call';
is Baz->met(), 'Foo::Bar::Baz', 'default aliased method call';

SKIP: {
    skip "no-paren sub calls are unaliasable on this perl", 6
        unless "$]" >= 5.011002;
    eval q{
        use namespace::alias 'Foo::Bar::Baz', 'MyAlias';
        use namespace::alias 'Foo::Bar::Baz';
        is MyAlias::fun, 'fun', 'aliased no-paren function call';
        is Baz::fun, 'fun', 'default aliased no-paren function call';
    };
    is $@, "";
    eval q{
        use namespace::alias 'Foo::Bar::Baz', 'MyAlias';
        use namespace::alias 'Foo::Bar::Baz';
        my $x = MyAlias::fun 1;
        is $x, 'fun', 'aliased no-paren with-arg function call';
        my $y = Baz::fun 1;
        is $y, 'fun', 'default aliased no-paren with-arg function call';
    };
    is $@, "";
}

# might this be possible?
sub giveback { $_[0] }
is giveback(MyAlias), 'Foo::Bar::Baz', 'aliased bareword';
is giveback(Baz),     'Foo::Bar::Baz', 'default aliased bareword';

# sub packages
is MyAlias::Qux->fun, 'fun2', 'aliased function call in sub package';
is MyAlias::Qux->met, 'Foo::Bar::Baz::Qux', 'aliased method call in sub package';

is Baz::Qux->fun, 'fun2', 'default aliased function call in sub package';
is Baz::Qux->met, 'Foo::Bar::Baz::Qux', 'default aliased method call in sub package';

# not a function, so look for package?
is giveback(MyAlias::Qux), 'Foo::Bar::Baz::Qux', 'aliased sub package bareword';
is giveback(Baz::Qux), 'Foo::Bar::Baz::Qux', 'aliased sub package bareword';

# method name lookups
is "string"->MyAlias::Qux::met(), 'string', 'aliased method dispatch';

is_deeply { MyAlias => 42 }, { 'MyAlias', 42 }, 'no mangling of fat commas';

is_deeply { MyAlias
=> 42 }, { 'MyAlias', 42 }, 'no mangling of fat commas, even not directly following the bareword';

is_deeply { MyAlias=>
42 }, { 'MyAlias', 42 }, 'another fat comma corner case';

done_testing;
