
=head1 DESCRIPTION

This tests Zapp::Controller::Trigger

=cut

use Mojo::Base -strict, -signatures;
use Test::Zapp;
use Test::More;
use Mojo::JSON qw( decode_json encode_json );

my $t = Test::Zapp->new;

my $dump_debug = sub( $t ) {
    diag $t->tx->res->dom->find(
        '#error,#context,#insight,#trace,#log',
    )->map('to_string')->each;
};

subtest 'create/edit a trigger' => sub {
    $t->clear_backend;
    my $plan = $t->app->create_plan({
        label => 'Deliver a package',
        description => 'To a dangerous place',
        tasks => [
            {
                label => 'Plan trip',
                name => 'Plan',
                class => 'Zapp::Task::Script',
                input => encode_json({
                    script => 'echo Chapek 9',
                }),
            },
            {
                label => 'Deliver package',
                name => 'Deliver',
                class => 'Zapp::Task::Script',
                input => encode_json({
                    script => 'echo Certain Doom',
                }),
            },
        ],
        inputs => [
            {
                name => 'destination',
                type => 'string',
                description => 'Where to send the crew to their doom',
                config => encode_json( 'Chapek 9' ),
            },
        ],
    });
    my $plan_id = $plan->{plan_id};

    subtest 'create trigger form' => sub {
        $t->get_ok( "/plan/$plan_id/trigger", form => { type => 'Webhook' } )
            ->status_is( 200 )
            ->element_exists( 'main form' )
            ->attr_is( 'main form' => action => "/plan/$plan_id/trigger/" )
            ->attr_is( 'main form' => method => 'POST' )
            ->element_exists( 'input[name=type]' )
            ->attr_is( 'input[name=type]', value => 'Webhook' )
            ->element_exists( 'input[name=plan_id]' )
            ->attr_is( 'input[name=plan_id]', value => $plan_id )
            ->element_exists( 'input[name=label]' )
            ->element_exists( '[name=description]' )
            ->element_exists( 'main form button' )
            ;

        # Trigger input form
        $t->element_exists( '[name="config.method"]' )
            ->or( sub { diag shift->tx->res->dom->at( '#trigger-config' ) } )
            ->element_exists( '[name="config.slug"]' )
            ;

        # Plan input form
        $t->element_exists( '[name="input.destination.value"]' )
            ;
    };

    my $trigger_id;
    subtest 'create trigger' => sub {
        $t->post_ok(
            "/plan/$plan_id/trigger",
            form => {
                label => 'Return to Sender',
                description => 'Return to whence it came',
                type => 'Webhook',
                plan_id => $plan_id,
                'config.method' => 'POST',
                'config.slug' => 'received',
                'input.destination' => '=params.return_address',
            },
        )
            ->status_is( 302 )
            ;

        my ( $trigger ) = $t->app->yancy->list( zapp_triggers => { plan_id => $plan_id } );
        ok $trigger, 'trigger exists';
        $trigger_id = $trigger->{trigger_id};
        is $trigger->{label}, 'Return to Sender', 'label is correct';
        is $trigger->{description}, 'Return to whence it came', 'description is correct';
        is $trigger->{type}, 'Webhook', 'type is correct';
        is_deeply decode_json( $trigger->{config} ),
            { method => 'POST', slug => 'received' },
            'config is correct';
        is_deeply decode_json( $trigger->{input} ),
            { destination => '=params.return_address' },
            'input is correct';
    };

    subtest 'edit trigger' => sub {
        $t->post_ok(
            "/plan/$plan_id/trigger/$trigger_id",
            form => {
                label => 'Return to Us',
                description => 'Return to whence it went',
                type => 'Webhook',
                plan_id => $plan_id,
                'config.method' => 'POST',
                'config.slug' => 'sent',
                'input.destination' => '=params.delivery_address',
            },
        )
            ->status_is( 302 )
            ;

        my ( $trigger ) = $t->app->yancy->get( zapp_triggers => $trigger_id );
        ok $trigger, 'trigger exists';
        is $trigger->{label}, 'Return to Us', 'label is correct';
        is $trigger->{description}, 'Return to whence it went', 'description is correct';
        is $trigger->{type}, 'Webhook', 'type is correct';
        is_deeply decode_json( $trigger->{config} ),
            { method => 'POST', slug => 'sent' },
            'config is correct';
        is_deeply decode_json( $trigger->{input} ),
            { destination => '=params.delivery_address' },
            'input is correct';
    };

};

done_testing;

