
use strict;
use warnings;
use Test::More;

use Types::Bool qw(true false is_bool to_bool);

plan tests => 10;

sub is_true ($)  { is_bool( $_[0] ) && ${ $_[0] } }
sub is_false ($) { is_bool( $_[0] ) && !${ $_[0] } }

ok( is_true( to_bool(true) ) );
ok( is_false( to_bool(false) ) );

ok( is_false( to_bool(undef) ) );
ok( is_false( to_bool(0) ) );
ok( is_false( to_bool('') ) );

ok( is_true( to_bool(1) ) );
ok( is_true( to_bool('true') ) );
ok( is_true( to_bool('xxx') ) );
ok( is_true( to_bool( [] ) ) );
ok( is_true( to_bool( {} ) ) );
