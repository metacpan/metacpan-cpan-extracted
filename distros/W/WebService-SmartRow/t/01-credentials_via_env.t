use Test2::V0;

use WebService::SmartRow;

local %ENV = %ENV;

$ENV{SMARTROW_USERNAME} = 'bar@tree';
$ENV{SMARTROW_PASSWORD} = 'passwooo';

my $srv = WebService::SmartRow->new;
my ( $user, $pass ) = $srv->_credentials_via_env;

is $user, 'bar%40tree',
    'Username brought in from ENV (@ is escaped properly)';
is $pass, 'passwooo', 'Password brought in from ENV';

$srv = WebService::SmartRow->new(
    username => 'foo@tree',
    password => 'wordpass',
);

( $user, $pass ) = $srv->_credentials_via_env;
is $user, 'foo%40tree',
    'Username from params (ENV ignored) (@ is escaped properly)';
is $pass, 'wordpass', 'Password from params (ENV ignored)';

done_testing;
