use warnings;
use strict;

use Test::More tests => 4;
use lib 't/lib';

BEGIN {

#line 1
#!/usr/bin/perl -d:_NC_TEST_DashD
#line 12

}

{
    package Foo;

    BEGIN { *baz = sub { 42 } }
    sub foo { 22 }

    use namespace::clean;

    sub bar {
        ::is(baz(), 42);
        ::is(foo(), 22);
    }
}

ok( !Foo->can("foo"), "foo cleaned up" );
ok( !Foo->can("baz"), "baz cleaned up" );

Foo->bar();
