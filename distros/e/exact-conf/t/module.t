use Test2::V0;

use exact -conf, -noautoclean;

ok( main->can('conf'), 'can conf' );
is( conf->get('answer'), 42, 'conf->get' );

done_testing;
