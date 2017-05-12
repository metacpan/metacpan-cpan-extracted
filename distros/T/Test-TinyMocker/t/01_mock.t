use strict;
use warnings;

use Test::More;
use Test::TinyMocker;

{

    package Foo::Bar;
    sub baz {"day"}
}

# original value
is Foo::Bar::baz(), "day", "initial value is ok";

# basic syntax
mock( 'Foo::Bar', 'baz', sub { return $_[0] + 1 } );
is Foo::Bar::baz(1), 2, "basic syntax";

mock 'Foo::Bar' => method 'baz' => should {"night"};
is Foo::Bar::baz(), "night", "static mocked value";

my $counter = 0;

mock 'Foo::Bar' => method 'baz' => should { $counter++; };

is Foo::Bar::baz(), 0, "dynamic mocked value";
is Foo::Bar::baz(), 1, "dynamic mocked value";

mock( 'Foo::Bar::baz', sub { return $_[0] + 3 } );
is Foo::Bar::baz(1), 4, "2 args syntax";

mock 'Foo::Bar::baz' => should { $_[0] + 2 };
is Foo::Bar::baz(1), 3, "2 args syntax with sugar";

eval {mock};
like( $@, qr{useless use of mock with one},
    "no call of mock without parameter" );

eval { mock 'Foo' };
like( $@, qr{useless use of mock with one},
    "no call of mock with one parameter" );

eval {
    mock 'Foo::Bar' => method 'faked' => should {return};
};
like( $@, qr{unknown symbol:}, "no mock non exists function" );

mock 'Foo::Bar' => method 'newly' => should {42}, { ignore_unknown => 1 };
is Foo::Bar::newly(), 42, "mocked an unknown symbol";

done_testing;
