use Test2::V0;

package Parent {
    use exact -class;
    with 'Role';
}

BEGIN {
    $INC{'Parent.pm'} = 1;
}

package Role {
    use exact -role;
    use Parent;
}

use Parent;

ok( 1, '(We still live!)' );

done_testing;
