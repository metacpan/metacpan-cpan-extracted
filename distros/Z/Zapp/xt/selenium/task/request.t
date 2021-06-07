
=head1 DESCRIPTION

To run this test, you must install Test::Mojo::Role::Selenium and
Selenium::Chrome. Then you must set the C<TEST_SELENIUM> environment
variable to C<1>.

Additionally, setting C<TEST_SELENIUM_CAPTURE=1> in the environment
will add screenshots to the C<t/selenium> directory. Each screenshot
begins with a counter so you can see the application state as the test
runs.

=cut

use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use Mojo::JSON qw( encode_json decode_json );

BEGIN {
    $ENV{TEST_SELENIUM} && eval "use Test::Mojo::Role::Selenium 0.16; 1"
        or plan skip_all => 'Test::Mojo::Role::Selenium >= 0.16 required to run this test';
};

use Test::mysqld;
my $mysqld = Test::mysqld->new or plan skip_all => $Test::mysqld::errstr;

$ENV{MOJO_SELENIUM_DRIVER} ||= 'Selenium::Chrome';
$ENV{TEST_SELENIUM_CAPTURE} ||= 0; # Disable screenshots by default

my $t = Test::Mojo->with_roles('+Selenium')->new( 'Zapp', {
    backend => {
        mysql => { dsn => $mysqld->dsn( dbname => 'test' ) },
    },
    minion => {
        mysql => { dsn => $mysqld->dsn( dbname => 'test' ) },
    },
} );
$t->setup_or_skip_all;

subtest 'auth type: bearer' => sub {
    $t->navigate_ok( '/plan' )
        ->status_is( 200 )
        ->click_ok( 'select.add-task' )
        ->click_ok( 'select.add-task option[value="Zapp::Task::Request"]' )
        ->wait_for( '[name="task[0].name"]' )

        ->live_element_exists(
            '[name="task[0].input.auth.type"]',
            'auth type select box exists',
        )
        ->live_element_exists_not(
            '.zapp-visible [name="task[0].input.auth.token"]',
            'auth token input is not visible',
        )
        ->click_ok( '[name="task[0].input.auth.type"]' )
        ->click_ok( '[name="task[0].input.auth.type"] option[value="bearer"]' )
        ->wait_for( '.zapp-visible > [name="task[0].input.auth.token"]' )
        ->send_keys_ok( '[name="task[0].input.auth.token"]', 'AUTHTOKEN' )
        ->click_ok( '[name="task[0].input.auth.type"]' )
        ->click_ok( '[name="task[0].input.auth.type"] option[value=""]' )
        ->wait_for( ':not(.zapp-visible) > [name="task[0].input.auth.token"]' )
};

done_testing;
