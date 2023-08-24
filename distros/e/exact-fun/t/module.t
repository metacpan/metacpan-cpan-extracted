use Test2::V0;
use exact -fun;

ok( lives {
    fun foo( $x, $y, $z = 5 ) {
        return $x + $y + $z;
    }
}, 'fun' ) or note $@;

is( foo( 1, 2 ), 8, 'call' );

done_testing;
