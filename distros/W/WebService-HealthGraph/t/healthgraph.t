use Test2::Bundle::Extended;

use Test::RequiresInternet ( 'api.runkeeper.com' => 443 );
use WebService::HealthGraph;

my $runkeeper = WebService::HealthGraph->new(
    auto_pagination => 0,
    debug           => 1,
    url_map         => { foo => 'bar' }
);

ok( $runkeeper,           'compiles' );
ok( $runkeeper->ua,       'ua' );
ok( $runkeeper->base_url, 'base_url' );
is( $runkeeper->uri_for('foo'), 'bar', 'uri_for' );

my $user_response = $runkeeper->user;
ok( $user_response, 'get_user' );
is( $user_response->code, 401, '401 response with missing token' );

done_testing;
