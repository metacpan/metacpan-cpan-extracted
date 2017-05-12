use strict;
use warnings;

# this covers the exact same stuff from 02-unmock.t
# but uses more than one method to override using "methods"

use Test::More;
use Test::TinyMocker;

{

    package Foo::Bar;
    sub baz {"day"}
    sub qux {"way"}
}

# original value
is Foo::Bar::baz(), "day", "initial value for baz is ok";
is Foo::Bar::qux(), "way", "initial value for qux is ok";

# mock new comportement
mock( 'Foo::Bar', [ 'baz', 'qux' ], sub { return 'night' } );

# unmock
unmock( 'Foo::Bar', [ 'baz', 'qux' ] );
is Foo::Bar::baz(), "day", "original value for baz";
is Foo::Bar::qux(), "way", "original value for qux";

# mock new comportement
mock( 'Foo::Bar', [ 'baz', 'qux' ], sub { return 'night' } );

# unmock
unmock( [ 'Foo::Bar::baz', 'Foo::Bar::qux' ] );
is Foo::Bar::baz(), "day", "original value for baz";
is Foo::Bar::qux(), "way", "original value for qux";

# mock new comportement
mock( 'Foo::Bar', [ 'baz', 'qux' ], sub { return 'night' } );

# unmock
unmock 'Foo::Bar' => methods [ 'baz', 'qux' ];
is Foo::Bar::baz(), "day", "original value for baz";
is Foo::Bar::qux(), "way", "original value for qux";

done_testing;
