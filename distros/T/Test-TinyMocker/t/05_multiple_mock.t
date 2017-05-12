use strict;
use warnings;

# this covers the exact same stuff from 01-mock.t
# but uses more than one method to override using "methods"

use Test::More;
use Test::TinyMocker;

{

    package Foo::Bar;
    sub baz {"day"}
    sub qux {"way"}
}

# original value
is Foo::Bar::baz(), "day", "first initial value is ok";
is Foo::Bar::qux(), "way", "second initial value is ok";

# basic syntax
mock( 'Foo::Bar', [ 'baz', 'qux' ], sub { return $_[0] + 1 } );
cmp_ok Foo::Bar::baz(1), '==', 2, "basic syntax for baz";
cmp_ok Foo::Bar::qux(1), '==', 2, "basic syntax for qux";

mock 'Foo::Bar' => methods [ 'baz', 'qux' ] => should {"night"};
is Foo::Bar::baz(), "night", "static mocked value for baz";
is Foo::Bar::qux(), "night", "static mocked value for qux";

my $counter = 0;

mock 'Foo::Bar' => methods [ 'baz', 'qux' ] => should { $counter++; };

cmp_ok Foo::Bar::baz(), '==', 0, "dynamic mocked value for baz";
cmp_ok Foo::Bar::qux(), '==', 1, "dynamic mocked value for qux";
cmp_ok Foo::Bar::baz(), '==', 2, "dynamic mocked value for baz";
cmp_ok Foo::Bar::qux(), '==', 3, "dynamic mocked value for qux";

mock( 'Foo::Bar::baz', sub { return $_[0] + 3 } );
mock( 'Foo::Bar::qux', sub { return $_[0] + 3 } );
cmp_ok Foo::Bar::baz(1), '==', 4, "2 args syntax for baz";
cmp_ok Foo::Bar::qux(1), '==', 4, "2 args syntax for qux";

mock [ 'Foo::Bar::baz', 'Foo::Bar::qux' ] => should { $_[0] + 2 };
is Foo::Bar::baz(1), 3, "2 args syntax with sugar for baz";
is Foo::Bar::qux(1), 3, "2 args syntax with sugar for qux";

eval {mock};
like( $@, qr{useless use of mock with one},
    "no call of mock without parameter" );

eval { mock 'Foo' };
like( $@, qr{useless use of mock with one},
    "no call of mock with one parameter" );

eval { mock [ 'Foo', 'Bar' ] };
like( $@, qr{useless use of mock with one},
    "no call of mock with one parameter" );

eval {
    mock 'Foo::Bar' => method 'faked' => should {return};
};
like( $@, qr{unknown symbol:}, "no mock non exists function" );

eval {
    mock 'Foo::Bar' => methods [ 'faked', 'baked' ] => should {return};
};
like( $@, qr{unknown symbol:}, "no mock non exists function" );

done_testing;
