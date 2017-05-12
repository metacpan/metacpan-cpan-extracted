use strict;
use lib 't', 'inc';
use Test::More tests => 3;
use onlyTest;

use _Foo::Bar;
is($_Foo::Bar::VERSION, '1.00');

eval q{use only '_Foo::Bar' => '0.88'};
like($@, qr'did not satisfy');
is($_Foo::Bar::VERSION, '1.00');
