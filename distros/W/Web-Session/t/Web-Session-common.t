use Test::More;

plan tests => 3;

use_ok('Web::Session::_common');

my ( $a, $b ) = ( [qw(0 1 a)], [qw(0 1 a b)] );

ok( Web::Session::_common->_tabInTab( $a, $b ) );

ok( !Web::Session::_common->_tabInTab( $b, $a ) );

