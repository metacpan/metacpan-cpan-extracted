
=head1 DESCRIPTION

This tests the Zapp::Task::Action::Confirm class.

=cut

use Mojo::Base -strict, -signatures;
use Test::Zapp;
use Test::More;
use Mojo::JSON qw( decode_json encode_json false true );
use Mojo::Loader qw( data_section );
use Zapp::Task::Action::Confirm;

my $t = Test::Zapp->new;

subtest 'input form' => sub {
    my $tmpl = data_section 'Zapp::Task::Action::Confirm', 'input.html.ep';
    $t->render_ok( inline => $tmpl )
        ->element_exists( 'input[name=prompt]', 'prompt input exists' )
        ->or( sub { diag $t->tx->res->body } )
        ->render_ok( inline => $tmpl, input => { prompt => 'Verily?' } )
        ->element_exists( 'input[name=prompt]', 'prompt input exists' )
        ->attr_is(
            'input[name=prompt]',
            value => 'Verily?',
            'existing value is populated',
        )
};

subtest 'action form' => sub {
    my $tmpl = data_section 'Zapp::Task::Action::Confirm', 'action.html.ep';
    $t->render_ok( inline => $tmpl, input => { prompt => 'Verily?' } )
      ->content_like( qr{Verily\?}, 'prompt appears in action' )
      ->element_exists( 'button[name=confirm]', 'confirm button exists' )
      ->element_exists( 'button[name=cancel]', 'cancel button exists' )
};

subtest 'run' => sub {
    my $run_id = $t->app->yancy->create(
        zapp_runs => { label => 'Confirmation' },
    );
    my $job_id = $t->app->minion->enqueue(
        'Zapp::Task::Action::Confirm',
        [
            {
                prompt => 'Verily?',
            },
        ],
    );
    my $task_id = $t->app->yancy->create(
        zapp_run_tasks => {
            name => 'Confirm',
            class => 'Zapp::Task::Action::Confirm',
            run_id => $run_id,
            job_id => $job_id,
        },
    );

    subtest 'First execute delays job and resets to inactive' => sub {
        my $w = $t->app->minion->worker->register;
        my $job = $w->dequeue( 0, { id => $job_id } );
        $job->execute;
        $w->unregister;
        is $job->info->{state}, 'inactive', 'job is still inactive';
        cmp_ok $job->info->{delayed}, '>', time(), 'job is delayed';
        my $task = $t->app->yancy->get( zapp_run_tasks => $task_id );
        is $task->{state}, 'waiting', 'zapp task state is waiting';
    };

    subtest 'Subsequent (accidental) executions do nothing' => sub {
        my $job = $t->app->minion->job( $job_id );
        $job->execute;
        is $job->info->{state}, 'inactive', 'job is still inactive';
        cmp_ok $job->info->{delayed}, '>', time(), 'job is still delayed';
        my $task = $t->app->yancy->get( zapp_run_tasks => $task_id );
        is $task->{state}, 'waiting', 'zapp task state is still waiting';
    };

    subtest 'Run after form input does the right thing' => sub {
        subtest 'success' => sub {
            my $c = $t->app->build_controller;
            my $form_input = { confirm => '' };
            my $job = $t->app->minion->job( $job_id );
            $job->action( $c, @{ $job->args }, $form_input );

            my $w = $t->app->minion->worker->register;
            $job = $w->dequeue( 0, { id => $job_id } );
            ok $job, 'job can be dequeued'
                or return;
            $job->execute;
            $w->unregister;
            is $job->info->{state}, 'finished', 'job is finished';
            my $task = $t->app->yancy->get( zapp_run_tasks => $task_id );
            is $task->{state}, 'finished', 'zapp task state is correct';
            is_deeply decode_json( $task->{output} ), { is_success => 1 }, 'confirmed';
        };
        subtest 'failure' => sub {
            my $c = $t->app->build_controller;
            my $form_input = { cancel => '' };
            my $job = $t->app->minion->job( $job_id );
            $job->action( $c, @{ $job->args }, $form_input );

            my $w = $t->app->minion->worker->register;
            $job = $w->dequeue( 0, { id => $job_id } );
            ok $job, 'job can be dequeued'
                or return;
            $job->execute;
            $w->unregister;
            is $job->info->{state}, 'failed', 'job is failed';
            my $task = $t->app->yancy->get( zapp_run_tasks => $task_id );
            is $task->{state}, 'failed', 'zapp task state is correct';
            is_deeply decode_json( $task->{output} ), { is_success => 0 }, 'cancelled';
        };
    };
};

done_testing;

