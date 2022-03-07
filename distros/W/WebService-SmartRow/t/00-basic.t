use Test2::V0;

use lib './lib';
use WebService::SmartRow;

my $sr = WebService::SmartRow->new(
    username => 'foo',
    password => 'pass',
);

is $sr->username(), 'foo',  'username';
is $sr->password(), 'pass', 'password';

can_ok( $sr, 'get_profile' );
can_ok( $sr, 'get_workouts' );

done_testing;

