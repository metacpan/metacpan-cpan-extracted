use strict;
use lib 't', 'inc';
use Test::More tests => 5;
use onlyTest;

use only '_Foo::Bar' => '0.60';
is($_Foo::Bar::VERSION, '0.60');
require _Foo::Baz;
is($_Foo::Baz::VERSION, '0.60');
like($INC[0], qr'^only:_Foo::Bar:');
like($INC[0], qr'version');
like($INC[0], qr'0.60');
