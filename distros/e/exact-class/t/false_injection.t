use exact;
use Test::Most;

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

use_ok('Parent');

done_testing();
