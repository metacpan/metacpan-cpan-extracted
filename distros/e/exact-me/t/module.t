use Test2::V0;
use exact -me, -noautoclean;

ok( lives { me() }, 'me()' ) or note $@;
ok( lives { me('../path/to/something') }, 'me("../path/to/something")' ) or note $@;
ok( lives { me('path/to/something') }, 'me("path/to/something")' ) or note $@;

done_testing;
