package Zapp::Controller::Run;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::JSON qw( decode_json encode_json );
use Mojo::Loader qw( data_section );
use Time::Piece;
use Zapp::Task;
use Zapp::Util qw( build_data_from_params );

sub _get_run_tasks( $self, $run_id, $filter={} ) {
    my @run_tasks;
    my @tasks = $self->app->get_tasks( zapp_run_tasks => { %$filter, run_id => $run_id } );

    # XXX: Need to be run through type method
    my $run = $self->yancy->get( zapp_runs => $run_id ) || {};
    my $input = decode_json( $run->{input} );
    my %context = (
        (
            map { $_->{name} => decode_json( $_->{output} ) }
            grep { $_->{state} eq 'finished' } @tasks
        ),
        (
            map { $_->{name} => $_->{value} } @$input
        ),
    );

    for my $task ( @tasks ) {
        $task->{input} = decode_json( $task->{input} );
        if ( $task->{output} ) {
            $task->{output} = decode_json( $task->{output} );
        }

        if ( $task->{state} ne 'inactive' ) {
            # Instantiate the job to process the input. Can't use minion
            # as the minion job may have been deleted by now.
            my $job = $task->{class}->new(
                minion => $self->minion,
                # Pre-fill caches to avoid database lookups
                zapp_run => $run,
                zapp_task => $task,
                _context => \%context,
            );
            $task->{input} = $job->process_input( $task->{input} );
        }
    }

    return \@tasks,
}

sub _get_run( $self, $run_id ) {
    my $run = $self->yancy->get( zapp_runs => $run_id ) || {};
    if ( my $run_id = $run->{run_id} ) {
        $run->{input} = decode_json( $run->{input} );
        $run->{output} = decode_json( $run->{output} // '{}' );
        $run->{tasks} = $self->_get_run_tasks( $run_id );
    }
    return $run;
}

sub create_run( $self ) {
    my %params;
    if ( my $plan_id = $self->param( 'plan_id' ) ) {
        my $plan = $self->app->get_plan( $plan_id );
        %params = (
            name => $plan->{name},
            description => $plan->{description},
            inputs => $plan->{inputs},
            tasks => $plan->{tasks},
        );
    }
    elsif ( my $run_id = $self->param( 'run_id' ) ) {
        my $run = $self->_get_run( $run_id );
        %params = (
            name => $run->{name},
            description => $run->{description},
            inputs => $run->{input},
            tasks => $run->{tasks},
        );
    }

    $self->render( 'zapp/run/create', %params );
}

sub save_run( $self ) {
    my $input_fields = build_data_from_params( $self, 'input' );
    my @run_input;
    for my $i ( 0..$#$input_fields ) {
        my $input = $input_fields->[ $i ];
        $input->{config} &&= decode_json( $input->{config} );
        my $type = $self->app->zapp->types->{ $input->{type} }
            or die qq{Could not find type "$input->{type}"};
        push @run_input, {
            name => $input->{name},
            type => $input->{type},
            config => $input->{config},
            value => $type->process_input( $self, $input->{config}, $input->{value} ),
        };
    }

    my $run;
    if ( my $plan_id = $self->param( 'plan_id' ) ) {
        $run = $self->app->enqueue_plan( $plan_id, { map { $_->{name} => $_->{value} } @run_input } );
    }
    elsif ( my $run_id = $self->param( 'run_id' ) ) {
        my %opt;
        if ( my $task_id = $self->param( 'task_id' ) ) {
            $opt{ task_id } = $task_id;
        }
        $run = $self->app->enqueue_run( $run_id, \@run_input, %opt );
    }

    $self->redirect_to( 'zapp.get_run' => { run_id => $run->{run_id} } );
}

sub get_run( $self ) {
    my $run_id = $self->stash( 'run_id' );
    my $run = $self->_get_run( $run_id );

    if ( $run->{started} ) {
        $run->{started} = Time::Piece->new( $run->{started} )->strftime( '%Y-%m-%d %H:%M:%S' );
    }
    if ( $run->{finished} ) {
        $run->{finished} = Time::Piece->new( $run->{finished} )->strftime( '%Y-%m-%d %H:%M:%S' );
    }

    # Find any actions that are waiting
    my @actions;
    for my $task ( grep { $_->{state} eq 'waiting' } $run->{tasks}->@* ) {
        next unless $task->{class}->isa( 'Zapp::Task::Action' );
        my $job = $task->{class}->new( minion => $self->minion );
        push @actions, {
            task => $task,
            action_field => $job->action_field( $self, $task->{input} ),
        };
    }

    $self->render(
        'zapp/run/view',
        run => $run,
        actions => \@actions,
    );
}

sub save_task_action( $self ) {
    my $run_id = $self->param( 'run_id' );
    my $task_id = $self->param( 'task_id' );
    my ( $task ) = $self->_get_run_tasks( $run_id, { task_id => $task_id } )->@*;
    die "Task $task_id not found\n" if !$task;
    die "Task is not waiting for an action\n" unless $task->{state} eq 'waiting';
    my $job = $self->minion->job( $task->{job_id} );
    my $form_input = build_data_from_params( $self );
    $job->action( $self, @{ $job->args }, $form_input );
    return $self->redirect_to( 'zapp.get_run' => { run_id => $run_id } );
}

sub stop_run( $self ) {
    my $run_id = $self->stash( 'run_id' );
    my $run = $self->_get_run( $run_id ) || return $self->reply->not_found;

    if ( $self->req->method eq 'GET' ) {
        return $self->render(
            'zapp/run/note',
            heading => 'Stop Run',
            next => 'zapp.stop_run_confirm',
        );
    }

    # Add the note
    $self->yancy->create( zapp_run_notes => {
        $run->%{qw( run_id )},
        event => 'stop',
        note => $self->param( 'note' ),
    } );

    # Stop inactive jobs
    for my $task ( $run->{tasks}->@* ) {
        my $job_id = $task->{job_id};
        my $job = $self->minion->job( $job_id ) || next;
        next if $job->info->{state} ne 'inactive';
        $job->remove;
        $self->yancy->backend->set(
            zapp_run_tasks => $task->{task_id},
            {
                state => 'stopped',
            },
        );
    }

    # Stop run
    $self->yancy->backend->set(
        zapp_runs => $run_id,
        {
            state => 'stopped',
        },
    );

    return $self->redirect_to( 'zapp.get_run' => { run_id => $run_id } );
}

sub start_run( $self ) {
    my $run_id = $self->stash( 'run_id' );
    my $run = $self->_get_run( $run_id ) || return $self->reply->not_found;

    # Requeue all jobs that were stopped
    my %task_jobs;
    for my $task ( $run->{tasks}->@* ) {
        if ( $task->{state} ne 'stopped' ) {
            $task_jobs{ $task->{task_id} } = $task->{job_id};
            next;
        }

        my $old_job_id = $task->{job_id};
        my %job_opts;
        if ( my @parents = $self->yancy->list( zapp_run_task_parents => { $task->%{'task_id'} } ) ) {
            next if grep { !$task_jobs{ $_->{parent_task_id} } } @parents;
            $job_opts{ parents } = [
                map $task_jobs{ $_ }, @parents
            ];
        }

        my $args = $task->{input};
        if ( ref $args ne 'ARRAY' ) {
            $args = [ $args ];
        }

        $self->log->debug( sprintf 'Enqueuing task %s', $task->{class} );
        my $new_job_id = $self->minion->enqueue(
            $task->{class} => $args,
            \%job_opts,
        );
        $task_jobs{ $task->{ task_id } } = $new_job_id;

        $self->yancy->backend->set(
            zapp_run_tasks => $task->{task_id},
            {
                job_id => $new_job_id,
                state => 'inactive',
            },
        );
    }

    $self->yancy->backend->set(
        zapp_runs => $run_id,
        {
            state => 'active',
        },
    );

    return $self->redirect_to( 'zapp.get_run' => { run_id => $run_id } );
}

sub kill_run( $self ) {
    my $run_id = $self->stash( 'run_id' );
    my $run = $self->_get_run( $run_id ) || return $self->reply->not_found;

    if ( $self->req->method eq 'GET' ) {
        return $self->render(
            'zapp/run/note',
            heading => 'Kill Run',
            next => 'zapp.kill_run_confirm',
        );
    }

    # Add the note
    $self->yancy->create( zapp_run_notes => {
        $run->%{qw( run_id )},
        event => 'kill',
        note => $self->param( 'note' ),
    } );

    # Kill inactive and active jobs
    for my $task ( $run->{tasks}->@* ) {
        my $job_id = $task->{job_id};
        my $job = $self->minion->job( $job_id ) || next;
        next if $job->info->{state} !~ qr{inactive|active};
        if ( $job->info->{state} eq 'active' ) {
            $self->minion->broadcast( 'kill', [ TERM => $job_id ]);
        }
        else {
            $job->remove;
        }
        $self->yancy->backend->set(
            zapp_run_tasks => $task->{task_id},
            {
                state => 'killed',
            },
        );
    }

    # Kill run
    $self->yancy->backend->set(
        zapp_runs => $run_id,
        {
            state => 'killed',
            finished => Time::Piece->new->datetime,
        },
    );

    return $self->redirect_to( 'zapp.get_run' => { run_id => $run_id } );
}

sub get_run_task( $self ) {
    my $run_id = $self->stash( 'run_id' );
    my $task_id = $self->stash( 'task_id' );
    my ( $run_task ) = grep { $_->{task_id} eq $task_id } $self->_get_run_tasks( $run_id )->@*
        or return $self->reply->not_found;
    my $template = data_section( $run_task->{class}, 'output.html.ep' );
    return $self->render( inline => $template, task => $run_task );
}

sub list_runs( $self ) {
    my @runs = $self->yancy->list( zapp_runs => {}, {} );
    # XXX: Order should be:
    #   1. Jobs that have not started
    #   2. Jobs that have not finished
    #   3. Jobs by finished datetime
    #   4. Jobs by started datetime
    #   5. Jobs by created datetime
    @runs = sort {
        no warnings 'uninitialized';
        ( $b->{state} =~ /(in)?active/n ) cmp ( $a->{state} =~ /(in)?active/n )
        || $b->{finished} cmp $a->{finished}
        || $b->{started} cmp $a->{started}
        || $b->{created} cmp $a->{created}
    } @runs;
    $self->render( 'zapp/run/list', runs => \@runs );
}

sub feed_run( $self ) {
    $self->inactivity_timeout(3600);
    my $interval = int( $self->param( 'interval' ) ) || 1;

    # Establish the current state of the run and every task
    my $run_id = $self->param( 'run_id' );
    my $old_run = $self->_get_run( $run_id ) || return $self->reply->not_found;
    my @old_tasks = @{ delete $old_run->{tasks} };

    # Send the initial state in case something has changed since the
    # original HTML page was sent
    $self->send({
        json => {
            %$old_run,
            tasks => \@old_tasks,
        },
    });

    # If the run is finished or failed, we're done here: Nothing can
    # change about this run.
    if ( $old_run->{state} =~ /^(finished|failed)$/n ) {
        # See https://tools.ietf.org/html/rfc6455#section-7.4.1 for
        # websocket status codes
        $self->finish(1000);
        return;
    }

    # Poll for updates
    my $timer_id;
    $self->on( finish => sub {
        if ( $timer_id ) {
            Mojo::IOLoop->remove( $timer_id );
            $timer_id = undef;
        }
    } );
    $timer_id = Mojo::IOLoop->recurring( $interval, sub( $loop ) {
        my $new_run = $self->_get_run( $run_id );
        my @new_tasks = @{ delete $new_run->{tasks} };

        # Send any changed fields / tasks
        my %delta = (
            map { $_ => $new_run->{ $_ } }
            grep { no warnings 'uninitialized'; $old_run->{ $_ } ne $new_run->{ $_ } }
            keys %$new_run
        );
        for my $i ( 0..$#new_tasks ) {
            my ( $old_task, $new_task ) = ( $old_tasks[ $i ], $new_tasks[ $i ] );
            # XXX: What if we add new tasks?
            my %task_delta = (
                map { $_ => $new_task->{ $_ } }
                grep { no warnings 'uninitialized'; $old_task->{ $_ } ne $new_task->{ $_ } }
                keys %$new_task
            );
            if ( %task_delta ) {
                $task_delta{ task_id } = $new_task->{ task_id };
                push @{ $delta{tasks} }, \%task_delta;
            }
        }

        if ( %delta ) {
            $self->send({ json => \%delta });

            # Update the state with the new information
            $old_run = $new_run;
            @old_tasks = @new_tasks;
        }

        if ( $old_run->{state} =~ /^(finished|failed)$/n ) {
            # We're done here...
            if ( $timer_id ) {
                $loop->remove( $timer_id );
                $timer_id = undef;
            }
            # See https://tools.ietf.org/html/rfc6455#section-7.4.1 for
            # websocket status codes
            $self->finish(1000);
        }
    } );
}

1;

__END__

=pod

=head1 NAME

Zapp::Controller::Run

=head1 VERSION

version 0.004

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
