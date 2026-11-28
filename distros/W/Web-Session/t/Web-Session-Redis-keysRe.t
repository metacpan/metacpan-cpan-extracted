use strict;
use warnings;
use Test::More;

my $class = 'Web::Session::Redis';

plan skip_all => 'Redis module is needed' unless eval "require $class";

# Each call uses its own keysRe, not the first one seen by the process
my $sid = 'a' x 64;
ok( $class->isLlngKey( {},  $sid ),      'default keysRe: session id' );
ok( !$class->isLlngKey( {}, 'cart:42' ), 'default keysRe: other key' );
ok( $class->isLlngKey( { keysRe => '^cart:' }, 'cart:42' ),
    'custom keysRe: matching key' );
ok( !$class->isLlngKey( { keysRe => '^cart:' }, $sid ),
    'custom keysRe: session id rejected' );
ok( $class->isLlngKey( {},  $sid ),      'default keysRe again' );
ok( !$class->isLlngKey( {}, 'cart:42' ), 'default keysRe again: other key' );

done_testing();
