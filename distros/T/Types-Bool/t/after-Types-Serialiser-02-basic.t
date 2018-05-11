
use Test::More;

# From MLEHMANN/Types-Serialiser-1.0/t/51_types.t

use Types::Bool;
eval { require Types::Serialiser };
plan skip_all => "Types::Serialiser needed for this test" if $@;

plan tests => 16;

{
    my $dec = Types::Bool::false;
    ok( !$dec, 'false() is false' );

    ok( Types::Bool::is_bool($dec), 'false() is_bool()' );

    cmp_ok( $dec,     '==', 0, 'false() == 0' );
    cmp_ok( !$dec,    '==', 1, '!false() == 1' );
    cmp_ok( $dec,     'eq', 0, 'false() eq 0' );
    cmp_ok( $dec - 1, '<',  0, 'false()-1 < 0' );
    cmp_ok( $dec + 1, '>',  0, 'false()+1 > 0' );
    cmp_ok( $dec * 2, '==', 0, 'false()*2 == 0' );
}
{
    my $dec = Types::Bool::true;
    ok( $dec, 'true() is true' );

    ok( Types::Bool::is_bool($dec), 'true() is_bool()' );

    cmp_ok( $dec,     '==', 1, 'true() == 1' );
    cmp_ok( !$dec,    '==', 0, '!true() == 0' );
    cmp_ok( $dec,     'eq', 1, 'true() eq 1' );
    cmp_ok( $dec - 1, '<=', 0, 'true()-1 <= 0' );
    cmp_ok( $dec - 2, '<',  0, 'true()-2 < 0' );
    cmp_ok( $dec * 2, '==', 2, 'true()*2 == 2' );
}
