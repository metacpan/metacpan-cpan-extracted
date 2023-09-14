use Test2::V0;
use Test2::Plugin::NoWarnings;

BEGIN {
    $INC{'TestExactParentClass.pm'} = 1;
    $INC{'TestExactClass.pm'}       = 1;
}

package TestExactParentClass {}

ok(
    lives {
        package TestExactClass {
            use exact 'TestExactParentClass';
        }
    },
    'package parent',
) or note $@;

done_testing;
