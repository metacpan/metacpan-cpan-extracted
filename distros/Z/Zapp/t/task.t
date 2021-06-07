
=head1 DESCRIPTION

This tests the base Zapp::Task class.

=cut

use Mojo::Base -strict, -signatures;
use Test::Zapp;
use Test::More;
use Mojo::JSON qw( decode_json encode_json );
use Zapp::Task;

my $t = Test::Zapp->new;

subtest 'execute' => sub {
    my $plan = $t->app->create_plan({
        label => 'Deliver a package',
        description => 'To a dangerous place',
        tasks => [
            {
                label => 'Plan trip',
                name => 'Plan',
                class => 'Zapp::Task::Script',
                input => encode_json({
                    vars => [
                        { name => 'dest', value => '=destination' },
                    ],
                    script => 'echo $dest',
                }),
            },
            {
                label => 'Deliver package',
                name => 'Deliver',
                class => 'Zapp::Task::Script',
                input => encode_json({
                    vars => [
                        { name => 'dest', value => '=destination' },
                    ],
                    script => 'echo Certain Doom on $dest',
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

    subtest 'success' => sub {
        my $input = {
            destination => 'Nude Beach Planet',
        };

        my $run = $t->app->enqueue_plan( $plan->{plan_id}, $input );
        my @tasks = @{ $run->{tasks} };

        $run = $t->app->yancy->get( zapp_runs => $run->{run_id} );
        is_deeply
            {
                %$run,
                input => decode_json( $run->{input} ),
            },
            {
                $run->%{qw( run_id created )},
                $plan->%{qw( plan_id label description )},
                input => [
                    {
                        $plan->{inputs}[0]->%{qw( description label name type )},
                        value => 'Nude Beach Planet',
                        config => 'Chapek 9',
                    },
                ],
                started => undef,
                finished => undef,
                state => 'inactive',
            },
            'database run is correct'
                or diag explain $run, $plan;

        # Check jobs created correctly
        my @got_tasks = $t->app->yancy->list( zapp_run_tasks => { $run->%{'run_id'} }, { order_by => 'task_id' } );
        is_deeply
            {
                $got_tasks[0]->%*,
                input => decode_json( $got_tasks[0]{input} ),
            },
            {
                $got_tasks[0]->%{qw( job_id task_id )},
                input => decode_json( $plan->{tasks}[0]{input} ),
                plan_task_id => $plan->{tasks}[0]{task_id},
                $plan->{tasks}[0]->%{qw( label name description class )},
                run_id => $run->{run_id},
                state => 'inactive',
                output => undef,
            },
            'first job run entry is correct';
        is_deeply
            {
                $got_tasks[1]->%*,
                input => decode_json( $got_tasks[1]{input} ),
            },
            {
                $got_tasks[1]->%{qw( job_id task_id )},
                plan_task_id => $plan->{tasks}[1]{task_id},
                $plan->{tasks}[1]->%{qw( name label description class )},
                input => decode_json( $plan->{tasks}[1]{input} ),
                run_id => $run->{run_id},
                state => 'inactive',
                output => undef,
            },
            'second job run entry is correct';

        subtest 'run first job' => sub {
            my $worker = $t->app->minion->worker->register;
            my $job = $worker->dequeue;
            my $e = $job->execute;
            ok !$e, 'job executed successfully' or diag "Job error: ", explain $e;
            is_deeply $job->args,
                [
                    {
                        vars => [
                            { name => 'dest', value => 'Nude Beach Planet' },
                        ],
                        script => 'echo $dest',
                    },
                ],
                'minion job args are interpolated input';

            $run = $t->app->yancy->get( zapp_runs => $run->{run_id} );
            is_deeply
                {
                    %$run,
                    input => decode_json( $run->{input} ),
                },
                {
                    $run->%{qw( run_id created started )},
                    $plan->%{qw( plan_id label description )},
                    input => [
                        {
                            $plan->{inputs}[0]->%{qw( description label name type )},
                            value => 'Nude Beach Planet',
                            config => 'Chapek 9',
                        },
                    ],
                    finished => undef,
                    state => 'active',
                },
                'database run is correct';

            my @got_tasks = $t->app->list_tasks( $run->{run_id}, { order_by => 'task_id' } );
            is_deeply
                $got_tasks[0],
                {
                    $got_tasks[0]->%{qw( job_id task_id )},
                    plan_task_id => $plan->{tasks}[0]{task_id},
                    $plan->{tasks}[0]->%{qw( name label description class )},
                    input => decode_json( $plan->{tasks}[0]{input} ),
                    run_id => $run->{run_id},
                    state => 'finished',
                    output => {
                        pid => $got_tasks[0]{output}{pid},
                        exit => 0,
                        output => "Nude Beach Planet\n",
                        error_output => "",
                        info => "Script exited with value: 0",
                    },
                },
                'first job run entry is correct';
            is_deeply
                $got_tasks[1],
                {
                    $got_tasks[1]->%{qw( job_id task_id )},
                    plan_task_id => $plan->{tasks}[1]{task_id},
                    $plan->{tasks}[1]->%{qw( name label description class )},
                    input => decode_json( $plan->{tasks}[1]{input} ),
                    run_id => $run->{run_id},
                    state => 'inactive',
                    output => undef,
                },
                'second job run entry is correct';
        };

        subtest 'run second job' => sub {
            my $worker = $t->app->minion->worker->register;
            my $job = $worker->dequeue;
            my $e = $job->execute;
            ok !$e, 'job executed successfully' or diag "Job error: ", explain $e;
            is_deeply $job->args,
                [
                    {
                        vars => [
                            { name => 'dest', value => 'Nude Beach Planet' },
                        ],
                        script => 'echo Certain Doom on $dest',
                    },
                ],
                'minion job args are interpolated input';

            $run = $t->app->yancy->get( zapp_runs => $run->{run_id} );
            is_deeply
                {
                    %$run,
                    input => decode_json( $run->{input} ),
                },
                {
                    $run->%{qw( run_id created started finished )},
                    $plan->%{qw( plan_id label description )},
                    input => [
                        {
                            $plan->{inputs}[0]->%{qw( description label name type )},
                            value => 'Nude Beach Planet',
                            config => 'Chapek 9',
                        },
                    ],
                    state => 'finished',
                },
                'database run is correct';

            my @got_tasks = $t->app->list_tasks( $run->{run_id}, { order_by => 'task_id' } );
            is_deeply
                $got_tasks[0],
                {
                    $got_tasks[0]->%{qw( job_id task_id )},
                    plan_task_id => $plan->{tasks}[0]{task_id},
                    $plan->{tasks}[0]->%{qw( name label description class )},
                    input => decode_json( $plan->{tasks}[0]{input} ),
                    run_id => $run->{run_id},
                    state => 'finished',
                    output => {
                        pid => $got_tasks[0]{output}{pid},
                        exit => 0,
                        output => "Nude Beach Planet\n",
                        error_output => "",
                        info => "Script exited with value: 0",
                    },
                },
                'first job run entry is correct';
            is_deeply
                $got_tasks[1],
                {
                    $got_tasks[1]->%{qw( job_id task_id )},
                    plan_task_id => $plan->{tasks}[1]{task_id},
                    $plan->{tasks}[1]->%{qw( name label description class )},
                    input => decode_json( $plan->{tasks}[1]{input} ),
                    run_id => $run->{run_id},
                    state => 'finished',
                    output => {
                        pid => $got_tasks[1]{output}{pid},
                        exit => 0,
                        output => "Certain Doom on Nude Beach Planet\n",
                        error_output => "",
                        info => "Script exited with value: 0",
                    },
                },
                'second job run entry is correct';
        };
    };
};

done_testing;

