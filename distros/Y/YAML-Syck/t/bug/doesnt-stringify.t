use Test::More;
use JSON::Syck qw(Dump);

plan( tests => 2 );

$v = 42;
is( Dump($v), "42" );
is( Dump($v), "42" );

