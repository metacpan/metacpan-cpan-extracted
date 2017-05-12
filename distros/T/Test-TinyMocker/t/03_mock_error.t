use strict;
use warnings;

use Test::More;
use Test::TinyMocker;

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

done_testing;
