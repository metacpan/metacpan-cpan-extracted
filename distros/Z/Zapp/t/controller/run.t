
=head1 DESCRIPTION

This tests Zapp::Controller::Plan (except for the JavaScript involved).

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

subtest 'run a plan' => sub {
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

    subtest 'create run form' => sub {
        $t->get_ok( "/plan/$plan_id/run" )->status_is( 200 )
            ->element_exists( "main form[action=/run]", 'form exists' )
            ->attr_is( "main form[action=/run]", enctype => 'multipart/form-data', 'form allows uploads' )
            ->element_exists( "[name=plan_id]", 'plan_id field exists' )
            ->attr_is( "[name=plan_id]", value => $plan_id, 'plan_id value is correct' )
            ->text_is( '[data-input=0] [data-input-name]', 'destination', 'input label correct' )
            ->element_exists( '[name="input[0].value"]', 'input field exists' )
            ->attr_is( '[name="input[0].value"]', value => 'Chapek 9', 'input default value is correct' )
            ->element_exists( '[name="input[0].name"]', 'input name exists' )
            ->attr_is( '[name="input[0].name"]', value => 'destination', 'input name is correct' )
            ->element_exists( '[name="input[0].type"]', 'input type exists' )
            ->attr_is( '[name="input[0].type"]', value => 'string', 'input type is correct' )
            ->element_exists( '[name="input[0].config"]', 'input config exists' )
            ->attr_is( '[name="input[0].config"]', value => '"Chapek 9"', 'input config is correct' )
            ;
    };

    subtest 'create a new run from a plan' => sub {
        $t->post_ok(
            "/run",
            form => {
                plan_id => $plan_id,
                'input[0].name' => 'destination',
                'input[0].type' => 'string',
                'input[0].value' => 'Galaxy of Terror',
                'input[0].config' => encode_json( 'Chapek 9' ),
            } )
            ->status_is( 302 )->or( $dump_debug )
            ->header_like( Location => qr{/run/\d+} )
            ;
        my ( $run_id ) = $t->tx->res->headers->location =~ m{/run/(\d+)};

        # Recorded in Zapp
        my $run = $t->app->yancy->get( zapp_runs => $run_id );
        is $run->{plan_id}, $plan_id, 'run plan_id is correct';
        is_deeply decode_json( $run->{input} ),
            [
                {
                    $plan->{inputs}[0]->%{qw( name label type description )},
                    value => 'Galaxy of Terror',
                    config => 'Chapek 9',
                },
            ],
            'run input is correct';

        # Record all enqueued tasks so we can keep track of which Minion
        # tasks were triggered by which Zapp run
        my @tasks = $t->app->yancy->list(
            zapp_run_tasks => { run_id => $run_id },
            { order_by => { -asc => 'job_id' } },
        );
        is scalar @tasks, 2, 'two run tasks created';
        is_deeply
            {
                $tasks[0]->%*,
                input => decode_json( $tasks[0]{input} ),
            },
            {
                $tasks[0]->%{qw( job_id task_id )},
                $plan->{tasks}[0]->%{qw( name label description class )},
                input => decode_json( $plan->{tasks}[0]{input} ),
                run_id => $run_id,
                plan_task_id => $plan->{tasks}[0]{task_id},
                state => 'inactive',
                output => undef,
            },
            'first job is correct'
                or diag explain $tasks[0];
        is_deeply
            {
                $tasks[1]->%*,
                input => decode_json( $tasks[1]{input} ),
            },
            {
                $tasks[1]->%{qw( job_id task_id )},
                $plan->{tasks}[1]->%{qw( name label description class )},
                input => decode_json( $plan->{tasks}[1]{input} ),
                run_id => $run_id,
                plan_task_id => $plan->{tasks}[1]{task_id},
                state => 'inactive',
                output => undef,
            },
            'second job is correct'
                or diag explain $tasks[1];

        # Enqueued in Minion
        my $mjob = $t->app->minion->job( $tasks[0]{job_id} );
        ok $mjob, 'minion job 1 exists';
        # XXX: Test job attributes

        $mjob = $t->app->minion->job( $tasks[1]{job_id} );
        ok $mjob, 'minion job 2 exists';
        # XXX: Test job attributes
    };

};

subtest 'replay a run' => sub {
    $t->clear_backend;
    my $plan = $t->app->create_plan({
        label => 'Meanwhile',
        description => 'Wanna go around again?',
        tasks => [
            {
                name => 'Climb',
                label => 'Climb Vampire State Building',
                class => 'Zapp::Task::Script',
                input => encode_json({
                    script => 'echo Climbing',
                }),
            },
            {
                name => 'CheckTime',
                label => 'Check time',
                class => 'Zapp::Task::Script',
                input => encode_json({
                    script => 'echo 7:02pm',
                }),
            },
            {
                name => 'Jump',
                label => 'Jump off',
                class => 'Zapp::Task::Script',
                input => encode_json({
                    script => 'echo Life without Leela is no life at all',
                }),
            },
        ],
        inputs => [
            {
                name => 'Champagne',
                type => 'string',
                description => 'The champagne to order for the announcement',
                config => encode_json( 'Snootie' ),
            },
        ],
    });
    my $plan_id = $plan->{plan_id};

    # Create a run to replay
    my $run = $t->app->enqueue_plan( $plan_id, {} );

    subtest 'replay run form' => sub {
        $t->get_ok( "/run/$run->{run_id}/replay" )->status_is( 200 )
            ->element_exists( "main form[action=/run]", 'form exists' )
            ->attr_is( "main form[action=/run]", enctype => 'multipart/form-data', 'form allows uploads' )
            ->element_exists( "[name=run_id]", 'run_id field exists' )
            ->attr_is( "[name=run_id]", value => $run->{run_id}, 'run_id value is correct' )
            ->text_is( '[data-input=0] [data-input-name]', 'Champagne', 'input label correct' )
            ->or( sub { diag $t->tx->res->dom->at( 'main form[action=/run]' ) } )
            ->element_exists( '[name="input[0].value"]', 'input field exists' )
            ->attr_is( '[name="input[0].value"]', value => 'Snootie', 'input default value is correct' )
            ->element_exists( '[name="input[0].name"]', 'input name exists' )
            ->attr_is( '[name="input[0].name"]', value => 'Champagne', 'input name is correct' )
            ->element_exists( '[name="input[0].type"]', 'input type exists' )
            ->attr_is( '[name="input[0].type"]', value => 'string', 'input type is correct' )
            ;
    };

    subtest 'create a new run from a run' => sub {
        $t->post_ok(
            "/run",
            form => {
                run_id => $run->{run_id},
                'input[0].name' => 'Champagne',
                'input[0].type' => 'string',
                'input[0].value' => 'Cheap',
                'input[0].config' => encode_json( 'Snootie' ),
            } )
            ->status_is( 302 )->or( $dump_debug )
            ->header_like( Location => qr{/run/\d+} )
            ;
        my ( $new_run_id ) = $t->tx->res->headers->location =~ m{/run/(\d+)};
        isnt $new_run_id, $run->{run_id}, 'a new run is created';

        # Recorded in Zapp
        my $run = $t->app->yancy->get( zapp_runs => $new_run_id );
        is_deeply decode_json( $run->{input} ),
            [
                {
                    name => 'Champagne',
                    type => 'string',
                    value => 'Cheap',
                    config => 'Snootie',
                },
            ],
            'run input is correct';

        # Record all enqueued tasks so we can keep track of which Minion
        # tasks were triggered by which Zapp run
        my @tasks = $t->app->yancy->list(
            zapp_run_tasks => { run_id => $new_run_id },
            { order_by => { -asc => 'job_id' } },
        );
        is scalar @tasks, 3, 'three run tasks created';
        is_deeply
            {
                $tasks[0]->%*,
                input => decode_json( $tasks[0]{input} ),
            },
            {
                $tasks[0]->%{qw( job_id task_id )},
                $plan->{tasks}[0]->%{qw( name label description class )},
                input => decode_json( $plan->{tasks}[0]{input} ),
                run_id => $new_run_id,
                plan_task_id => $plan->{tasks}[0]{task_id},
                state => 'inactive',
                output => undef,
            },
            'first job is correct'
                or diag explain $tasks[0];
        is_deeply
            {
                $tasks[1]->%*,
                input => decode_json( $tasks[1]{input} ),
            },
            {
                $tasks[1]->%{qw( job_id task_id )},
                $plan->{tasks}[1]->%{qw( name label description class )},
                input => decode_json( $plan->{tasks}[1]{input} ),
                run_id => $new_run_id,
                plan_task_id => $plan->{tasks}[1]{task_id},
                state => 'inactive',
                output => undef,
            },
            'second job is correct'
                or diag explain $tasks[1];
        is_deeply
            {
                $tasks[2]->%*,
                input => decode_json( $tasks[2]{input} ),
            },
            {
                $tasks[2]->%{qw( job_id task_id )},
                $plan->{tasks}[2]->%{qw( name label description class )},
                input => decode_json( $plan->{tasks}[2]{input} ),
                run_id => $new_run_id,
                plan_task_id => $plan->{tasks}[2]{task_id},
                state => 'inactive',
                output => undef,
            },
            'third job is correct'
                or diag explain $tasks[2];

        # Enqueued in Minion
        my $mjob = $t->app->minion->job( $tasks[0]{job_id} );
        ok $mjob, 'minion job 1 exists';
        # XXX: Test job attributes

        $mjob = $t->app->minion->job( $tasks[1]{job_id} );
        ok $mjob, 'minion job 2 exists';
        # XXX: Test job attributes

        $mjob = $t->app->minion->job( $tasks[2]{job_id} );
        ok $mjob, 'minion job 3 exists';
        # XXX: Test job attributes
    };

    subtest 'replay only some tasks' => sub {
        $t->post_ok(
            "/run",
            form => {
                run_id => $run->{run_id},
                task_id => $run->{tasks}[1]{task_id},
                'input[0].name' => 'Champagne',
                'input[0].type' => 'string',
                'input[0].value' => 'Cheap',
                'input[0].config' => encode_json( 'Snootie' ),
            } )
            ->status_is( 302 )->or( $dump_debug )
            ->header_like( Location => qr{/run/\d+} )
            ;
        my ( $new_run_id ) = $t->tx->res->headers->location =~ m{/run/(\d+)};
        isnt $new_run_id, $run->{run_id}, 'a new run is created';

        # Recorded in Zapp
        my $run = $t->app->yancy->get( zapp_runs => $new_run_id );
        is_deeply decode_json( $run->{input} ),
            [
                {
                    name => 'Champagne',
                    type => 'string',
                    value => 'Cheap',
                    config => 'Snootie',
                },
            ],
            'run input is correct';

        # Record all enqueued tasks so we can keep track of which Minion
        # tasks were triggered by which Zapp run
        my @tasks = $t->app->yancy->list(
            zapp_run_tasks => { run_id => $new_run_id },
            { order_by => { -asc => 'job_id' } },
        );
        is scalar @tasks, 3, 'three run tasks created';
        is_deeply
            {
                $tasks[0]->%*,
                input => decode_json( $tasks[0]{input} ),
            },
            {
                $tasks[0]->%{qw( task_id )},
                $plan->{tasks}[0]->%{qw( name label description class )},
                input => decode_json( $plan->{tasks}[0]{input} ),
                run_id => $new_run_id,
                plan_task_id => $plan->{tasks}[0]{task_id},
                state => 'copied',
                output => undef,
                job_id => undef,
            },
            'first job is correctly copied from previous run and has no minion job'
                or diag explain $tasks[0];
        is_deeply
            {
                $tasks[1]->%*,
                input => decode_json( $tasks[1]{input} ),
            },
            {
                $tasks[1]->%{qw( job_id task_id )},
                $plan->{tasks}[1]->%{qw( name label description class )},
                input => decode_json( $plan->{tasks}[1]{input} ),
                run_id => $new_run_id,
                plan_task_id => $plan->{tasks}[1]{task_id},
                state => 'inactive',
                output => undef,
            },
            'second job is correct'
                or diag explain $tasks[1];
        is_deeply
            {
                $tasks[2]->%*,
                input => decode_json( $tasks[2]{input} ),
            },
            {
                $tasks[2]->%{qw( job_id task_id )},
                $plan->{tasks}[2]->%{qw( name label description class )},
                input => decode_json( $plan->{tasks}[2]{input} ),
                run_id => $new_run_id,
                plan_task_id => $plan->{tasks}[2]{task_id},
                state => 'inactive',
                output => undef,
            },
            'third job is correct'
                or diag explain $tasks[2];

        # Enqueued in Minion
        my $mjob = $t->app->minion->job( $tasks[0]{job_id} );
        ok !$mjob, 'minion job 1 does not exist';

        $mjob = $t->app->minion->job( $tasks[1]{job_id} );
        ok $mjob, 'minion job for task 2 exists';
        # XXX: Test job attributes

        $mjob = $t->app->minion->job( $tasks[2]{job_id} );
        ok $mjob, 'minion job for task 3 exists';
        # XXX: Test job attributes
    };
};

subtest 'view run status' => sub {
    my $plan = $t->app->create_plan({
        label => 'Watch the What If Machine',
        tasks => [
            {
                name => 'Watch',
                class => 'Zapp::Task::Script',
                input => encode_json({
                    vars => [
                        { name => 'Character', value => '=Character', },
                    ],
                    script => 'echo $Character',
                }),
            },
            {
                name => 'Consequences',
                label => 'Experience Ironic Consequences',
                class => 'Zapp::Task::Script',
                input => encode_json({
                    vars => [
                        { name => 'Character', value => '=Character', },
                    ],
                    script => 'echo $Character',
                }),
            },
        ],
        inputs => [
            {
                name => 'Character',
                type => 'string',
                description => 'Which character should ask the question?',
                config => encode_json( 'Leela' ),
            },
        ],
    });
    my $plan_id = $plan->{plan_id};
    my $run = $t->app->enqueue_plan(
        $plan_id,
        {
            Character => 'Zanthor',
        },
    );

    subtest 'from plan' => sub {

        subtest 'before execution' => sub {
            $t->get_ok( '/run/' . $run->{run_id} )->status_is( 200 )
                ->element_exists( "[href=/plan/$plan_id]", 'link back to plan exists' )
                ->element_exists_not( "main [href=/run]", 'link back to run list does not exist' )
                ->or(sub { diag shift->tx->res->dom->at( '[href=/run]' ) })
                ->attr_like( '.task-tabs .active', id => qr/tab-info-label/, 'info tab is selected for inactive tasks' )
                ->text_is( '[data-run=state]', 'inactive', 'run state is correct' )
                ->text_is( '[data-run=started]', 'N/A', 'run started is correct' )
                ->text_is( '[data-run=finished]', 'N/A', 'run finished is correct' )
                ->attr_like( "#tab-task-$run->{tasks}[0]{task_id}-label", class => qr/disabled/, 'first task is disabled' )
                ->text_like( "[data-task-output=$run->{tasks}[0]{task_id}] dd", qr/^=Character/, 'first task input are not yet interpolated' )
                ->attr_like( "#tab-task-$run->{tasks}[1]{task_id}-label", class => qr/disabled/, 'second task is disabled' )
                ->text_like( "[data-task-output=$run->{tasks}[1]{task_id}] dd", qr/^=Character/, 'second task input are not yet interpolated' )
                ->or( sub { diag $t->tx->res->dom( "[data-task=$run->{tasks}[1]{task_id}]" )->each } )
                ;

            $t->get_ok( '/run/' . $run->{run_id} . '/task/' . $run->{tasks}[0]{task_id} )
                ->status_is( 200 )
                ->element_exists_not( 'body', 'not inside layout' )
                ->text_like( "dd", qr/^=Character/, 'first task input are not yet interpolated' )
                ;

            $t->get_ok( '/run/' . $run->{run_id} . '/task/' . $run->{tasks}[1]{task_id} )
                ->status_is( 200 )
                ->element_exists_not( 'body', 'not inside layout' )
                ->text_like( "dd", qr/^=Character/, 'second task input are not interpolated' )
                ;
        };

        # Subscribe to websocket feed
        $t->websocket_ok( '/run/' . $run->{run_id} . '/feed?interval=1' )
            # Initial message
            ->message_ok;

        $t->run_queue;

        subtest 'feed message with deltas' => sub {
            $t->message_ok
                ->json_message_is( '/state' => 'finished' )
                ->json_message_has( '/started' )
                ->json_message_has( '/finished' )
                ->json_message_hasnt( '/created', 'created did not change' )
                ->json_message_has( '/tasks', 'tasks changed' )
                ->json_message_is( '/tasks/0/state' => 'finished' )
                ->json_message_is( '/tasks/1/state' => 'finished' )
                ->finished_ok(1000)
                ;
        };

        subtest 'after execution' => sub {
            $t->get_ok( '/run/' . $run->{run_id} )->status_is( 200 )
                ->element_exists( "[href=/plan/$plan_id]", 'link back to plan exists' )
                ->element_exists_not( "main [href=/run]", 'link back to run list does not exist' )
                ->text_like( '.task-tabs .active', qr/Experience Ironic Consequences/, 'final tab is selected for finished tasks' )
                ->text_is( '[data-run=state]', 'finished', 'run state is correct' )
                ->text_like( '[data-run=started]', qr{\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}}, 'run started is formatted correctly' )
                ->text_like( '[data-run=finished]',  qr{\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}}, 'run finished is formatted correctly' )
                ->attr_unlike( "#tab-task-$run->{tasks}[0]{task_id}-label", class => qr/disabled/, 'first task is not disabled' )
                ->attr_unlike( "#tab-task-$run->{tasks}[1]{task_id}-label", class => qr/disabled/, 'second task is not disabled' )
                ->attr_like( "#tab-task-$run->{tasks}[0]{task_id}-label", class => qr/success/, 'first task is success' )
                ->attr_like( "#tab-task-$run->{tasks}[1]{task_id}-label", class => qr/success/, 'second task is success' )
                ->text_like( "[data-task-output=$run->{tasks}[0]{task_id}] dd", qr/Zanthor/, 'first task input are interpolated' )
                ->text_like( "[data-task-output=$run->{tasks}[1]{task_id}] dd", qr/Zanthor/, 'second task input are interpolated' )
                ;

            $t->get_ok( '/run/' . $run->{run_id} . '/task/' . $run->{tasks}[0]{task_id} )
                ->status_is( 200 )
                ->element_exists_not( 'body', 'not inside layout' )
                ->text_like( "dd", qr/Zanthor/, 'first task input are interpolated' )
                ;

            $t->get_ok( '/run/' . $run->{run_id} . '/task/' . $run->{tasks}[1]{task_id} )
                ->status_is( 200 )
                ->element_exists_not( 'body', 'not inside layout' )
                ->text_like( "dd", qr/Zanthor/, 'second task input are interpolated' )
                ;
        };
    };

};

subtest 'task actions' => sub {
    my $plan = $t->app->create_plan({
        label => 'Fire Diamondium Cannon!',
        tasks => [
            {
                name => 'Confirm',
                class => 'Zapp::Task::Action::Confirm',
                input => encode_json({
                    prompt => 'Are you sure?',
                }),
            },
        ],
    });
    my $run = $t->app->enqueue_plan( $plan->{plan_id}, {} );

    subtest 'before prepare' => sub {
        $t->get_ok( '/run/' . $run->{run_id} )->status_is( 200 )
            ->element_exists_not(
                "[action=/run/$run->{run_id}/task/$run->{tasks}[0]{task_id}/action]",
                'action field not displaying before preparation',
            );
    };

    subtest 'after prepare' => sub {
        $t->run_queue;
        $t->get_ok( '/run/' . $run->{run_id} )->status_is( 200 )
            ->element_exists(
                "[action=/run/$run->{run_id}/task/$run->{tasks}[0]{task_id}/action]",
                'action field displaying after preparation',
            );
    };

    subtest 'submit action' => sub {
        $t->post_ok(
            '/run/' . $run->{run_id} . '/task/' . $run->{tasks}[0]{task_id} . '/action',
            form => { confirm => 'Confirm' },
        )
            ->status_is( 302 )
            ->header_is( Location => '/run/' . $run->{run_id} )
            ;

        my $after_task = $t->app->yancy->get( zapp_run_tasks => $run->{tasks}[0]{task_id} );
        is $after_task->{state}, 'inactive', 'task is now inactive';
    };

    # XXX: Make sure task can be run
    $t->run_queue;
};

subtest 'stop/kill run' => sub {
    my $plan = $t->app->create_plan({
        label => 'Open the Scary Door',
        tasks => [
            {
                name => 'Open',
                class => 'Zapp::Task::Script',
                input => encode_json({
                    script => 'echo The door creaks spookily',
                }),
            },
            {
                label => 'Twist Ending',
                name => 'Twist',
                class => 'Zapp::Task::Script',
                input => encode_json({
                    script => 'echo Saw it coming',
                }),
            },
        ],
    });
    my $plan_id = $plan->{plan_id};

    subtest 'stop run' => sub {
        my $run = $t->app->enqueue_plan( $plan_id, {} );

        # Run view screen shows start/stop buttons
        $t->get_ok( "/run/$run->{run_id}" )->status_is( 200 )
            ->element_exists( "[action=/run/$run->{run_id}/stop]", 'stop form exists' )
            ->element_exists_not( "[action=/run/$run->{run_id}/stop] button[disabled]", 'stop form button not disabled' )
            ->element_exists( "form[action=/run/$run->{run_id}/start]", 'start form exists' )
            ->element_exists( "form[action=/run/$run->{run_id}/start] button[disabled]", 'start form button disabled' )
            ->element_exists( "[action=/run/$run->{run_id}/kill]", 'kill form exists' )
            ->element_exists_not( "[action=/run/$run->{run_id}/kill] button[disabled]", 'kill form button not disabled' )
            ;

        # Do one job before stopping
        my $worker = $t->app->minion->worker->register;
        my $job = $worker->dequeue;
        my $e = $job->execute;
        $worker->unregister;

        # Show stop run form
        $t->get_ok( "/run/$run->{run_id}/stop" )->status_is( 200 )
            ->element_exists( 'main form' )
            ->attr_is( 'main form', action => "/run/$run->{run_id}/stop" )
            ->attr_like( 'main form', method => qr{post}i )
            ->element_exists( 'textarea' )
            ->attr_is( 'textarea', name => 'note' )
            ->element_exists( 'button' )
            ;

        # Stop the run
        $t->post_ok( "/run/$run->{run_id}/stop",
                form => {
                    note => 'You only stamped it four times!',
                },
            )
            ->status_is( 302 )
            ->header_is( Location => "/run/$run->{run_id}" )
            ;

        # Run note is added
        my @notes = $t->app->yancy->list( zapp_run_notes => { $run->%{'run_id'} } );
        is scalar @notes, 1, 'one note found';
        like $notes[0]{created}, qr{\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}};
        is $notes[0]{event}, 'stop';
        is $notes[0]{note}, 'You only stamped it four times!';

        # Run state "stopped"
        my $set_run = $t->app->yancy->get( zapp_runs => $run->{run_id} );
        is $set_run->{state}, 'stopped', 'run state is correct';

        # Zapp job state "stopped"
        my $task = $t->app->yancy->get( zapp_run_tasks => $run->{tasks}[1]{task_id} );
        is $task->{state}, 'stopped', 'zapp job state is correct'
            or diag explain [ $run->{tasks}[1], $task ];

        # Minion job removed
        ok !$t->app->minion->job( $run->{task}[1]{job_id} ), 'minion job removed';

        # Job cannot be dequeued
        $worker = $t->app->minion->worker->register;
        ok !$worker->dequeue(0), 'no job to dequeue';
        $worker->unregister;

        # Job view screen shows Start button
        $t->get_ok( "/run/$run->{run_id}" )->status_is( 200 )
            ->element_exists( "[action=/run/$run->{run_id}/stop]", 'stop form exists' )
            ->element_exists( "[action=/run/$run->{run_id}/stop] button[disabled]", 'stop form button disabled' )
            ->element_exists( "form[action=/run/$run->{run_id}/start]", 'start form exists' )
            ->element_exists_not( "form[action=/run/$run->{run_id}/start] button[disabled]", 'start form button not disabled' )
            ->element_exists( "[action=/run/$run->{run_id}/kill]", 'kill form exists' )
            ->element_exists_not( "[action=/run/$run->{run_id}/kill] button[disabled]", 'kill form button not disabled' )
            ;

        # Start the run
        $t->post_ok( "/run/$run->{run_id}/start" )->status_is( 302 )
            ->header_is( Location => "/run/$run->{run_id}" )
            ;

        # Zapp job state "inactive"
        $task = $t->app->yancy->get( zapp_run_tasks => $run->{tasks}[1]{task_id} );
        is $task->{state}, 'inactive', 'zapp run task state is correct';

        # Minion job state "inactive"
        $job = $t->app->minion->job( $task->{job_id} );
        is $job->info->{state}, 'inactive', 'minion job state is correct';

        # Job can be dequeued
        $worker = $t->app->minion->worker->register;
        $job = $worker->dequeue(0);
        ok $job, 'job dequeued';
        $job->execute;
        $worker->unregister;

        # Run screen shows stop/start buttons both disabled
        $t->get_ok( "/run/$run->{run_id}" )->status_is( 200 )
            ->element_exists( "[action=/run/$run->{run_id}/stop]", 'stop form exists' )
            ->element_exists( "[action=/run/$run->{run_id}/stop] button[disabled]", 'stop form button disabled' )
            ->element_exists( "form[action=/run/$run->{run_id}/start]", 'start form exists' )
            ->element_exists( "form[action=/run/$run->{run_id}/start] button[disabled]", 'start form button disabled' )
            ->element_exists( "[action=/run/$run->{run_id}/kill]", 'kill form exists' )
            ->element_exists( "[action=/run/$run->{run_id}/kill] button[disabled]", 'kill form button disabled' )
            ;

    };

    subtest 'kill run' => sub {
        my @signals;
        local $SIG{TERM} = sub { push @signals, 'TERM' };

        my $run = $t->app->enqueue_plan( $plan_id );

        # Run view screen shows kill button
        $t->get_ok( "/run/$run->{run_id}" )->status_is( 200 )
            ->element_exists( "[action=/run/$run->{run_id}/stop]", 'stop form exists' )
            ->element_exists_not( "[action=/run/$run->{run_id}/stop] button[disabled]", 'stop form button not disabled' )
            ->element_exists( "form[action=/run/$run->{run_id}/start]", 'start form exists' )
            ->element_exists( "form[action=/run/$run->{run_id}/start] button[disabled]", 'start form button disabled' )
            ->element_exists( "[action=/run/$run->{run_id}/kill]", 'kill form exists' )
            ->element_exists_not( "[action=/run/$run->{run_id}/kill] button[disabled]", 'kill form button not disabled' )
            ;

        # Do one job before killing
        my $worker = $t->app->minion->worker->register;
        my $job = $worker->dequeue;
        my $e = $job->execute;
        $worker->unregister;

        # Show kill run form
        $t->get_ok( "/run/$run->{run_id}/kill" )->status_is( 200 )
            ->element_exists( 'main form' )
            ->attr_is( 'main form', action => "/run/$run->{run_id}/kill" )
            ->attr_like( 'main form', method => qr{post}i )
            ->element_exists( 'textarea' )
            ->attr_is( 'textarea', name => 'note' )
            ->element_exists( 'button' )
            ;

        # Kill the run
        $t->post_ok( "/run/$run->{run_id}/kill",
                form => {
                    note => 'I was young, and reckless!',
                },
            )
            ->status_is( 302 )
            ->header_is( Location => "/run/$run->{run_id}" )
            ;

        # Run note is added
        my @notes = $t->app->yancy->list( zapp_run_notes => { $run->%{'run_id'} } );
        is scalar @notes, 1, 'one note found';
        like $notes[0]{created}, qr{\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}};
        is $notes[0]{event}, 'kill';
        is $notes[0]{note}, 'I was young, and reckless!';

        # Run state "killed"
        my $set_run = $t->app->yancy->get( zapp_runs => $run->{run_id} );
        is $set_run->{state}, 'killed', 'run state is correct';
        like $set_run->{finished}, qr{\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}}, 'run finished is set';

        # Zapp job state "killed"
        my $task = $t->app->yancy->get( zapp_run_tasks => $run->{tasks}[1]{task_id} );
        is $task->{state}, 'killed', 'zapp run task state is correct';
        ok !$task->{finished}, 'task finished is not set';

        # Minion job removed
        ok !$t->app->minion->job( $task->{job_id} ), 'minion job removed';

        # Job cannot be started again
        $worker = $t->app->minion->worker->register;
        $job = $worker->dequeue(0);
        $worker->unregister;
        ok !$job, 'no job dequeued' or diag explain $job->info;

        # Job view screen shows disabled buttons
        $t->get_ok( "/run/$run->{run_id}" )->status_is( 200 )
            ->element_exists( "[action=/run/$run->{run_id}/stop]", 'stop form exists' )
            ->element_exists( "[action=/run/$run->{run_id}/stop] button[disabled]", 'stop form button disabled' )
            ->element_exists( "form[action=/run/$run->{run_id}/start]", 'start form exists' )
            ->element_exists( "form[action=/run/$run->{run_id}/start] button[disabled]", 'start form button disabled' )
            ->element_exists( "[action=/run/$run->{run_id}/kill]", 'kill form exists' )
            ->element_exists( "[action=/run/$run->{run_id}/kill] button[disabled]", 'kill form button disabled' )
            ;

    };
};

subtest 'list runs' => sub {
    $t->clear_backend;
    my @runs = (
        {
            label => 'Cannibalon',
            description => q{Food's good},
            state => 'inactive',
            created => '2021-02-01 00:00:00',
        },
        {
            label => 'Nude Beach Planet',
            description => 'Bar stool softener',
            state => 'active',
            created => '2021-01-01 00:00:00',
            started => '2021-02-01 01:00:00',
        },
    );
    $_->{run_id} = $t->app->yancy->create( zapp_runs => $_ ) for @runs;

    $t->get_ok( '/run' )->status_is( 200 );

    subtest 'run list and items are displayed' => sub {
        $t->element_exists( '[data-runs]', 'run list exist' );
        $t->element_exists( "[data-run-id=$runs[0]{run_id}]", 'first run is in list' );
        $t->element_exists( "[data-run-id=$runs[1]{run_id}]", 'second run is in list' );
    };

    subtest 'run item data is correct' => sub {
        $t->attr_is(
            "[data-run-id=$runs[0]{run_id}]",
            href => "/run/$runs[0]{run_id}",
            'first run link is correct',
        );
        $t->attr_is(
            "[data-run-id=$runs[1]{run_id}]",
            href => "/run/$runs[1]{run_id}",
            'second run link is correct',
        );
    };

    subtest 'run list is in correct order' => sub {
        $t->attr_is(
            '[data-runs] > :nth-child(1)',
            'data-run-id' => $runs[1]{run_id},
            'active run is shown first',
        )->or( sub { diag $t->tx->res->dom->at( '[data-runs]' ) } );
        $t->attr_is(
            '[data-runs] > :nth-child(2)',
            'data-run-id' => $runs[0]{run_id},
            'inactive run is shown after active runs',
        )->or( sub { diag $t->tx->res->dom->at( '[data-runs]' ) } );
    };
};

done_testing;

