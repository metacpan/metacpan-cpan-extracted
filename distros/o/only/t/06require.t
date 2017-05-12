use strict;
use lib 't', 'inc';
use Test::More tests => 2;
use onlyTest;

use only '_Foo::Bar' => '0.60';
is($_Foo::Bar::VERSION, '0.60');
require _Foo::Baz;
is($_Foo::Baz::VERSION, '0.60');
