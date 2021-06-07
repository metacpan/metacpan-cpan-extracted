
=head1 DESCRIPTION

Test the Zapp::Trigger::Webhook class.

=cut

use Mojo::Base -strict, -signatures;
use Test::More;
use Mojo::JSON qw( encode_json decode_json );
use Test::Zapp;

# subtest 'config form' => sub {
# };

subtest 'fire trigger' => sub {
    my $t = Test::Zapp->new;
    my $plan = $t->app->create_plan({
        label => 'Good News Everyone',
        inputs => [
            {
                name => 'Danger',
                type => 'text',
                config => encode_json( 'Extreme' ),
            },
        ],
        tasks => [
            {
                label => 'Deliver News',
                name => 'Deliver',
                class => 'Zapp::Task::Script',
                input => encode_json({
                    script => 'echo Good News Everyone! The danger level is only $DANGER today!',
                    environment => {
                        DANGER => '=Danger',
                    },
                }),
            },
        ],
    });

    my $trigger_id = $t->app->yancy->create(
        zapp_triggers => {
            type => 'Webhook',
            plan_id => $plan->{plan_id},
            config => encode_json({
                slug => 'good_news_everyone',
                method => 'POST',
            }),
            input => encode_json({
                Danger => {
                    value => '=params.danger',
                },
            }),
        },
    );

    $t->post_ok( '/webhook/good_news_everyone', form => { danger => 'Certain Death' } )
        ->status_is( 204 )
        ;

    my ( $trigger_run ) = $t->app->yancy->list( zapp_trigger_runs => { trigger_id => $trigger_id } );
    ok $trigger_run, 'trigger has a run';
    my ( $run ) = $t->app->yancy->get( zapp_runs => $trigger_run->{run_id} );
    ok $run, 'run exists';
    my $input = decode_json( $run->{input} );
    is_deeply $input,
        [
            {
                name => 'Danger',
                type => 'text',
                config => 'Extreme',
                value => 'Certain Death',
                description => undef,
                label => undef,
            },
        ],
        'run input is correct';
};

done_testing;
