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

# mock new comportement
mock( 'Foo::Bar', 'baz', sub { return 'night' } );

# unmock
unmock( 'Foo::Bar', 'baz' );
is Foo::Bar::baz(), "day", "original value";

# mock new comportement
mock( 'Foo::Bar', 'baz', sub { return 'night' } );

# unmock
unmock('Foo::Bar::baz');
is Foo::Bar::baz(), "day", "original value";

# mock new comportement
mock( 'Foo::Bar', 'baz', sub { return 'night' } );

# unmock
unmock 'Foo::Bar' => method 'baz';
is Foo::Bar::baz(), "day", "original value";

done_testing;
