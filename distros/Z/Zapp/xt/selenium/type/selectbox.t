
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
use Test::Zapp;
use Mojo::JSON qw( encode_json decode_json );

BEGIN {
    $ENV{TEST_SELENIUM} && eval "use Test::Mojo::Role::Selenium 0.16; 1"
        or plan skip_all => 'Test::Mojo::Role::Selenium >= 0.16 required to run this test';
};

use Test::mysqld;
my $mysqld = Test::mysqld->new or plan skip_all => $Test::mysqld::errstr;

$ENV{MOJO_SELENIUM_DRIVER} ||= 'Selenium::Chrome';
$ENV{TEST_SELENIUM_CAPTURE} ||= 0; # Disable screenshots by default

my $t = Test::Zapp->with_roles('Test::Mojo::Role::Selenium')->new( 'Zapp', {
    backend => {
        mysql => { dsn => $mysqld->dsn( dbname => 'test' ) },
    },
    minion => {
        mysql => { dsn => $mysqld->dsn( dbname => 'test' ) },
    },
} );
$t->setup_or_skip_all;

subtest 'config' => sub {
    $t->navigate_ok( '/plan' )->status_is( 200 )
        # Required plan information
        ->send_keys_ok( '[name=name]', 'Enum test' )

        # Add selectbox field
        ->click_ok( 'select.add-input' )
        ->click_ok( 'select.add-input option[value=selectbox]' )
        ->wait_for( '[name="input[0].name"]' )

        ->send_keys_ok( '[name="input[0].name"]', 'Beer_Name' )

        ->live_element_exists( '[name="input[0].config.options[0].label"]' )
        ->live_element_exists( '[name="input[0].config.options[0].value"]' )
        ->live_element_exists( '[name="input[0].config.selected_index' )

        ->send_keys_ok(
            '[name="input[0].config.options[0].label"]',
            'Benderbrau',
        )
        ->send_keys_ok(
            '[name="input[0].config.options[0].value"]',
            'ale',
        )

        ->click_ok( '#all-inputs > :nth-child(1) button[data-zapp-array-add]' )
        ->wait_for( '[name="input[0].config.options[1].label"]' )

        ->send_keys_ok(
            '[name="input[0].config.options[1].label"]',
            'Botweiser',
        )
        ->send_keys_ok(
            '[name="input[0].config.options[1].value"]',
            'lager',
        )

        ->click_ok( '#all-inputs > :nth-child(1) button[data-zapp-array-add]' )
        ->wait_for( '[name="input[0].config.options[2].label"]' )

        ->send_keys_ok(
            '[name="input[0].config.options[2].label"]',
            'Löbrau',
        )
        ->send_keys_ok(
            '[name="input[0].config.options[2].value"]',
            'stillborn',
        )

        ->click_ok( 'button[name=save-plan]' )
        ->wait_until( sub { $_->get_current_url =~ m{plan/(\d+)} } )
        ;

    my ( $plan_id ) = $t->driver->get_current_url =~ m{plan/(\d+)};

    my @got_inputs = $t->app->yancy->list(
        zapp_plan_inputs =>
        {
            plan_id => $plan_id,
        },
        {
            order_by => 'name',
        },
    );
    is scalar @got_inputs, 1, 'got 1 input for plan';
    is_deeply
        {
            %{ $got_inputs[0] },
            config => decode_json( $got_inputs[0]{config} ),
            value => decode_json( $got_inputs[0]{value} ),
        },
        {
            plan_id => $plan_id,
            name => 'Beer_Name',
            rank => 0,
            description => '',
            type => 'selectbox',
            value => undef,
            config => {
                options => [
                    { label => 'Benderbrau', value => 'ale' },
                    { label => 'Botweiser', value => 'lager' },
                    { label => 'Löbrau', value => 'stillborn' },
                ],
                selected_index => 0,
            },
        },
        'input config is correct';
};

done_testing;
