package Zapp;
our $VERSION = '0.004';
# ABSTRACT: Plan building, job creating web app

#pod =head1 SYNOPSIS
#pod
#pod     # Start the web application
#pod     zapp daemon
#pod
#pod     # Start the task runner
#pod     zapp minion worker
#pod
#pod =head1 DESCRIPTION
#pod
#pod Zapp is a graphical workflow builder that provides a UI to build and
#pod execute jobs.
#pod
#pod For documentation on running and using Zapp, see L<Zapp::Guides>.
#pod
#pod This file documents the main application class, L<Zapp>. This class can
#pod be used to L<embed Zapp into an existing Mojolicious application|https://docs.mojolicious.org/Mojolicious/Guides/Routing#Embed-applications>, or
#pod can be extended to add customizations.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Yancy>, L<Mojolicious>
#pod
#pod =cut

use v5.28;
use Mojo::Base 'Mojolicious', -signatures;
use Scalar::Util qw( blessed );
use Yancy::Util qw( load_backend );
use Mojo::JSON qw( encode_json decode_json );
use Mojo::Loader qw( find_modules load_class );
use Mojo::File qw( curfile );
use Zapp::Formula;

#pod =attr formula
#pod
#pod The formula interpreter. Usually a L<Zapp::Formula> object.
#pod
#pod =cut

has formula => sub { Zapp::Formula->new };

#pod =method startup
#pod
#pod Initialize the application. Called automatically by L<Mojolicious>.
#pod
#pod =cut

sub startup( $self ) {

    push @{ $self->renderer->paths }, curfile->sibling( 'Zapp', 'resources', 'templates' );
    push @{ $self->static->paths }, curfile->sibling( 'Zapp', 'resources', 'public' );

    # XXX: Allow configurable backends, like Minion
    $self->plugin( Config => { default => {
        backend => 'sqlite:' . $self->home->child( 'zapp.db' ),
        minion => { SQLite => 'sqlite:' . $self->home->child( 'zapp.db' ) },
    } } );

    # XXX: Add migrate() method to Yancy app base class, varying by
    # backend type. Should try to read migrations from each class in
    # $self->isa
    # XXX: Create this migrate() method in a role so it can also be used
    # by Yancy::Plugins or other plugins
    my $backend = load_backend( $self->config->{backend} );
    my ( $db_type ) = blessed( $backend ) =~ m/([^:]+)$/;
    $backend->mojodb->migrations
        ->name( 'zapp' )
        ->from_data( __PACKAGE__, 'migrations.' . lc $db_type . '.sql' )
        ->migrate;

    $self->plugin( Minion => $self->config->{ minion }->%* );

    # XXX: Allow additional task namespaces
    for my $class ( find_modules 'Zapp::Task', { recursive => 1 } ) {
        next if $class eq 'Zapp::Task';
        if ( my $e = load_class( $class ) ) {
            $self->log->error( sprintf "Could not load task class %s: %s", $class, $e );
            next;
        }
        #; say "Adding task class: $class";
        $self->minion->add_task( $class, $class );
    }

    $self->plugin( Yancy =>
        $self->config->%{qw( backend )},
        schema => {
            zapp_plan_inputs => {
                # XXX: Fix read_schema to detect compound primary keys
                'x-id-field' => [qw( plan_id name )],
            },
            zapp_plan_task_parents => {
                # XXX: Fix read_schema to detect compound primary keys
                'x-id-field' => [qw( task_id parent_task_id )],
            },
        },
    );

    # Add basic types
    my %base_types = (
        string => 'Zapp::Type::Text',
        textarea => 'Zapp::Type::Textarea',
        number => 'Zapp::Type::Text',
        integer => 'Zapp::Type::Text',
        boolean => 'Zapp::Type::Text',
        file => 'Zapp::Type::File',
        selectbox => 'Zapp::Type::SelectBox',
    );
    $self->helper( 'zapp.types' => sub( $c ) { state %types; \%types } );
    $self->helper( 'zapp.add_type' => sub( $c, $name, $type ) {
        my $obj = blessed( $type ) ? $type : undef;
        if ( !defined $obj ) {
            if ( my $e = load_class( $type ) ) {
                die "Could not load type class $type: $e\n";
            }
            $obj = $type->new( app => $c->app );
        }
        else {
            $obj->app( $c->app );
        }
        $c->zapp->types->{ $name } = $obj;
    });
    for my $type_name ( keys %base_types ) {
        $self->zapp->add_type( $type_name, $base_types{ $type_name } );
    }

    # XXX: Add config file for adding types

    # Add basic triggers
    my %base_triggers = (
        Webhook => 'Zapp::Trigger::Webhook',
    );
    $self->helper( 'zapp.triggers' => sub( $c ) { state %triggers; \%triggers } );
    $self->helper( 'zapp.add_trigger' => sub( $c, $name, $trigger ) {
        my $obj = blessed( $trigger ) ? $trigger : undef;
        if ( !defined $obj ) {
            if ( my $e = load_class( $trigger ) ) {
                die "Could not load trigger class $trigger $e\n";
            }
            $obj = $trigger->new( moniker => $name );
        }
        $obj->install( $self );
        $c->zapp->triggers->{ $name } = $obj;
    });
    for my $trigger_name ( keys %base_triggers ) {
        $self->zapp->add_trigger( $trigger_name, $base_triggers{ $trigger_name } );
    }

    # Create/edit plans
    # XXX: Make Yancy support this basic CRUD with relationships?
    # XXX: Otherwise, add custom JSON API
    $self->routes->get( '/plan/create' )
        ->to( 'plan#edit_plan' )->name( 'zapp.create_plan' );
    $self->routes->post( '/plan/create' )->to( 'plan#save_plan' );
    $self->routes->get( '/plan/:plan_id' )
        ->to( 'plan#get_plan' )->name( 'zapp.get_plan' );
    $self->routes->get( '/plan/:plan_id/edit' )
        ->to( 'plan#edit_plan' )->name( 'zapp.edit_plan' );
    $self->routes->post( '/plan/:plan_id/edit' )->to( 'plan#save_plan' );
    $self->routes->get( '/plan/:plan_id/delete' )
        ->to( 'plan#delete_plan' )->name( 'zapp.delete_plan' );
    $self->routes->post( '/plan/:plan_id/delete' )
        ->to( 'plan#delete_plan' )->name( 'zapp.delete_plan_confirm' );
    $self->routes->get( '/' )
        ->to( 'plan#list_plans' )->name( 'zapp.list_plans' );

    # Create/view runs
    $self->routes->get( '/plan/:plan_id/run', { run_id => undef } )
        ->to( 'run#create_run' )->name( 'zapp.create_run' );
    $self->routes->get( '/run/:run_id/replay' )
        ->to( 'run#create_run' )->name( 'zapp.replay_run' );
    $self->routes->post( '/run' )
        ->to( 'run#save_run' )->name( 'zapp.save_run' );
    $self->routes->get( '/run' )
        ->to( 'run#list_runs' )->name( 'zapp.list_runs' );
    $self->routes->get( '/run/:run_id' )
        ->to( 'run#get_run' )->name( 'zapp.get_run' );
    $self->routes->get( '/run/:run_id/task/:task_id' )
        ->to( 'run#get_run_task' )->name( 'zapp.get_run_task' );
    $self->routes->post( '/run/:run_id/task/:task_id/action' )
        ->to( 'run#save_task_action' )->name( 'zapp.save_task_action' );
    # $self->routes->get( '/run/:run_id/edit' )
    # ->to( 'run#edit_run' )->name( 'zapp.edit_run' );
    # $self->routes->post( '/run/:run_id/edit' )
    # ->to( 'run#save_run' )->name( 'zapp.save_run' );
    $self->routes->get( '/run/:run_id/stop' )
        ->to( 'run#stop_run' )->name( 'zapp.stop_run' );
    $self->routes->post( '/run/:run_id/stop' )
        ->to( 'run#stop_run' )->name( 'zapp.stop_run_confirm' );
    $self->routes->post( '/run/:run_id/start' )
        ->to( 'run#start_run' )->name( 'zapp.start_run_confirm' );
    $self->routes->get( '/run/:run_id/kill' )
        ->to( 'run#kill_run' )->name( 'zapp.kill_run' );
    $self->routes->post( '/run/:run_id/kill' )
        ->to( 'run#kill_run' )->name( 'zapp.kill_run_confirm' );
    $self->routes->websocket( '/run/:run_id/feed' )
        ->to( 'run#feed_run' )->name( 'zapp.feed_run' );

    $self->routes->any( [qw( GET POST )], '/plan/:plan_id/trigger/:trigger_id', { trigger_id => undef } )
        ->to( 'trigger#edit' )->name( 'zapp.edit_trigger' );
}

#pod =method create_plan
#pod
#pod Create a new plan and all related data.
#pod
#pod =cut

# XXX: Make Yancy automatically handle relationships like this
sub create_plan( $self, $plan ) {
    my @inputs = @{ delete $plan->{inputs} // [] };
    my @tasks = @{ delete $plan->{tasks} // [] };
    my $plan_id = $self->yancy->create( zapp_plans => $plan );

    for my $i ( 0..$#inputs ) {
        $inputs[$i]{plan_id} = $plan_id;
        my $input = { %{ $inputs[$i] }, rank => $i };
        $self->yancy->create( zapp_plan_inputs => $input );
    }

    my $prev_task_id;
    for my $task ( @tasks ) {
        $task->{plan_id} = $plan_id;
        my $task_id = $self->yancy->create( zapp_plan_tasks => $task );
        if ( $prev_task_id ) {
            $self->yancy->create( zapp_plan_task_parents => {
                task_id => $task_id,
                parent_task_id => $prev_task_id,
            });
        }
        $prev_task_id = $task_id;
        $task->{ task_id } = $task_id;
    }

    $plan->{plan_id} = $plan_id;
    $plan->{tasks} = \@tasks;
    $plan->{inputs} = \@inputs;

    return $plan;
}

#pod =method get_plan
#pod
#pod Get a plan and all related data (tasks, inputs).
#pod
#pod =cut

sub get_plan( $self, $plan_id ) {
    my $plan = $self->yancy->get( zapp_plans => $plan_id ) || {};
    if ( my $plan_id = $plan->{plan_id} ) {
        my $tasks = $plan->{tasks} = [
            $self->yancy->list( zapp_plan_tasks => { plan_id => $plan_id }, { order_by => 'task_id' } ),
        ];
        for my $task ( @$tasks ) {
            $task->{input} = decode_json( $task->{input} );
        }

        my $inputs = $plan->{inputs} = [
            $self->yancy->list( zapp_plan_inputs => { plan_id => $plan_id }, { order_by => 'rank' } ),
        ];
        for my $input ( @$inputs ) {
            if ( my $config = $input->{config} ) {
                $input->{config} = decode_json( $config );
            }
            if ( my $value = $input->{value} ) {
                $input->{value} = decode_json( $value );
            }
        }
    }
    return $plan;
}

#pod =method enqueue_plan
#pod
#pod Enqueue a plan.
#pod
#pod =cut

sub enqueue_plan( $self, $plan_id, $input={}, %opt ) {
    $opt{queue} ||= 'zapp';

    # Create the run in the database by copying the plan
    my $plan = $self->yancy->get( zapp_plans => $plan_id );
    # XXX: Run inputs and plan inputs should either both be tables or
    # both be JSON serialized
    my @inputs = $self->yancy->list( zapp_plan_inputs => { plan_id => $plan_id }, { order_by => 'rank' } );
    delete $plan->{created};
    my $run = {
        %$plan,
        # XXX: Auto-encode/-decode JSON fields in Yancy schema
        input => encode_json([
            map +{
                    $_->%{qw( name label type description )},
                    config => decode_json( $_->{config} // 'null' ),
                    value => $input->{ $_->{name} },
            },
            @inputs,
        ]),
    };
    my $run_id = $run->{run_id} = $self->yancy->create( zapp_runs => $run );

    my @tasks = $self->get_tasks( zapp_plan_tasks => { plan_id => $plan_id } );

    # Create the new task rows, mapping new task IDs from the old task
    # IDs for parent/child relationships.
    my %task_id_map;
    for my $task ( @tasks ) {
        delete $task->{ $_ } for qw( plan_id );
        $task->{run_id} = $run_id;
        my $parents = $task->{parents} ? delete $task->{parents} : [];
        my $old_task_id = $task->{plan_task_id} = delete $task->{task_id};
        my $new_task_id = $self->yancy->backend->create( zapp_run_tasks => $task );
        $task->{task_id} = $task_id_map{ $old_task_id } = $new_task_id;
        #$task->{task_id} = $new_task_id;
        $task->{parents} = [ map { $task_id_map{ $_ } } @$parents ];
        for my $parent_task_id ( @{ $task->{parents} } ) {
            $self->yancy->backend->create( zapp_run_task_parents => {
                $task->%{'task_id'},
                parent_task_id => $parent_task_id,
            } );
        }
    }
    $run->{tasks} = \@tasks;

    my $jobs = $self->enqueue_tasks( $input, @tasks );
    for my $i ( 0..$#$jobs ) {
        my $job = $jobs->[$i];

        my ( $task ) = grep { $_->{task_id} eq $job->{task_id} } $run->{tasks}->@*;
        $task->{$_} = $job->{$_} for keys %$job;

        $self->yancy->backend->set( zapp_run_tasks => $job->{task_id}, $job );
    }

    return $run;
}

#pod =method get_tasks
#pod
#pod Get the tasks for a plan/run from the given table.
#pod
#pod =cut

sub get_tasks( $self, $table, $search ) {
    my $parents_table = $table =~ s/s$/_parents/r;
    my @tasks = $self->yancy->list( $table => $search );

    for my $task ( @tasks ) {
        $task->{parents} = [
            map { $_->{parent_task_id} }
            $self->yancy->list( $parents_table => { $task->%{'task_id'} } )
        ];
        #; $self->log->debug( 'Got parents for task ' . $task->{task_id} . ': ' . join ', ', @{ $task->{parents} } );
    }

    # Put the tasks in an order they can be created so all parent tasks
    # are before any dependent child tasks
    my @ordered_tasks;
    TASK: while ( @tasks ) {
        my $task = shift @tasks;
        for my $parent_task_id ( @{ $task->{parents} // [] } ) {
            # If there's a parent task we haven't seen yet, try again later
            if ( grep { $_->{task_id} eq $parent_task_id } @tasks ) {
                push @tasks, $task;
                next TASK;
            }
        }
        push @ordered_tasks, $task;
    }

    return @ordered_tasks;
}

#pod =method enqueue_run
#pod
#pod Re-enqueue a run.
#pod
#pod =cut

sub enqueue_run( $self, $old_run_id, $input=[], %opt ) {
    $opt{queue} ||= 'zapp';

    # Create the new run in the database by copying the old run
    my $old_run = $self->yancy->get( zapp_runs => $old_run_id );
    # XXX: Delete more from the old run
    delete $old_run->{ $_ } for qw( run_id created started finished state );
    my $new_run = {
        %$old_run,
        state => 'inactive',
        # XXX: Auto-encode/-decode JSON fields in Yancy schema
        input => encode_json( $input ),
    };
    my $new_run_id = $new_run->{run_id} = $self->yancy->create( zapp_runs => $new_run );

    my @tasks = $self->get_tasks( zapp_run_tasks => { run_id => $old_run_id } );
    for my $task ( @tasks ) {
        delete $task->{ $_ } for qw( job_id started finished );
        $task->{ run_id } = $new_run_id;
        $task->{ state } = 'inactive';
    }

    if ( my $start_task_id = $opt{task_id} ) {
        #; $self->log->debug( "Starting from task: $start_task_id" );
        # Mark which jobs should be re-run and which should be copied.
        # Since we know @tasks is ordered with parents before children,
        # we can reverse it to make sure we hit children before their
        # parents.
        # Start with the parents of the starting task
        my %to_copy = (
            map { $_ => 1 } map { $_->{parents}->@* }
            grep { $_->{task_id} eq $start_task_id }
            @tasks
        );
        #; $self->log->debug( "Copying " . %to_copy );
        for my $task ( reverse @tasks ) {
            # Remove parents that we aren't creating from the list we give
            # to Minion
            $task->{parents} = [ grep { !$to_copy{ $_ } } @{ $task->{parents} // [] } ];

            next unless $to_copy{ $task->{task_id} };
            #; $self->log->debug( "Copying $task->{task_id}" );
            $task->{state} = 'copied';
            $to_copy{ $_ }++ for @{ $task->{parents} // [] };
        }
    }

    # Create the new task rows, mapping new task IDs from the old task
    # IDs for parent/child relationships.
    my %task_id_map;
    for my $task ( @tasks ) {
        my $parents = $task->{parents} ? delete $task->{parents} : [];
        my $old_task_id = delete $task->{task_id};
        my $new_task_id = $self->yancy->backend->create( zapp_run_tasks => $task );
        $task->{task_id} = $task_id_map{ $old_task_id } = $new_task_id;
        #$task->{task_id} = $new_task_id;
        $task->{parents} = [ map { $task_id_map{ $_ } } @$parents ];
        for my $parent_task_id ( @{ $task->{parents} } ) {
            $self->yancy->backend->create( zapp_run_task_parents => {
                $task->%{'task_id'},
                parent_task_id => $parent_task_id,
            } );
        }
    }
    $new_run->{tasks} = \@tasks;

    # Enqueue any tasks we are not copying
    my $jobs = $self->enqueue_tasks( $input, grep $_->{state} eq 'inactive', @tasks );
    for my $i ( 0..$#$jobs ) {
        my $job = $jobs->[$i];

        my ( $task ) = grep { $_->{task_id} eq $job->{task_id} } $new_run->{tasks}->@*;
        $task->{$_} = $job->{$_} for keys %$job;

        #; $self->log->debug( "Setting job id for task $job->{task_id} -> $job->{job_id}" );
        $self->yancy->backend->set( zapp_run_tasks => $job->{task_id}, $job );
    }

    return $new_run;
}

#pod =method
#pod
#pod Create L<Minion> jobs for a run using L<Minion/enqueue>.
#pod
#pod =cut

sub enqueue_tasks( $self, $input, @tasks ) {
    my @jobs;
    # Create Minion jobs for this run
    my %task_jobs;
    # Loop over tasks, making the job if the task's parents are made.
    # Stop the loop once all tasks have jobs.
    my $loops = @tasks * @tasks;
    while ( @tasks != keys %task_jobs ) {
        # Loop over any tasks that aren't made yet
        for my $task ( grep !$task_jobs{ $_->{task_id} }, @tasks ) {
            my $task_id = $task->{task_id};
            # Skip if we haven't created all parents
            #; $self->log->debug( "Task $task_id has parents @{ $task->{parents} // [] }" );
            next if @{ $task->{parents} // [] } && grep { !$task_jobs{ $_ } } $task->{parents}->@*;

            # XXX: Expose more Minion job configuration
            my %job_opts;
            if ( my @parents = @{ $task->{parents} // [] } ) {
                $job_opts{ parents } = [
                    map $task_jobs{ $_ }, @parents
                ];
            }

            my $args = decode_json( $task->{input} );
            if ( ref $args ne 'ARRAY' ) {
                $args = [ $args ];
            }

            $self->log->debug( sprintf 'Enqueuing task %s', $task->{class} );
            my $job_id = $self->minion->enqueue(
                $task->{class} => $args,
                \%job_opts,
            );
            $task_jobs{ $task_id } = $job_id;

            push @jobs, {
                task_id => $task_id,
                job_id => $job_id,
            };
        }
        last if !$loops--;
    }
    if ( @tasks != keys %task_jobs ) {
        $self->log->error( 'Could not create jobs: Infinite loop' );
        return undef;
    }

    return \@jobs;
}

#pod =method list_tasks
#pod
#pod List tasks for a run.
#pod
#pod =cut

sub list_tasks( $self, $run_id, $opt={} ) {
    my @tasks = $self->yancy->list(
        zapp_run_tasks => { run_id => $run_id }, $opt,
    );
    for my $task ( @tasks ) {
        for my $field ( qw( input output ) ) {
            $task->{ $field } &&= decode_json( $task->{ $field } );
        }
    }
    return @tasks;
}

1;

=pod

=head1 NAME

Zapp - Plan building, job creating web app

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    # Start the web application
    zapp daemon

    # Start the task runner
    zapp minion worker

=head1 DESCRIPTION

Zapp is a graphical workflow builder that provides a UI to build and
execute jobs.

For documentation on running and using Zapp, see L<Zapp::Guides>.

This file documents the main application class, L<Zapp>. This class can
be used to L<embed Zapp into an existing Mojolicious application|https://docs.mojolicious.org/Mojolicious/Guides/Routing#Embed-applications>, or
can be extended to add customizations.

=head1 ATTRIBUTES

=head2 formula

The formula interpreter. Usually a L<Zapp::Formula> object.

=head1 METHODS

=head2 startup

Initialize the application. Called automatically by L<Mojolicious>.

=head2 create_plan

Create a new plan and all related data.

=head2 get_plan

Get a plan and all related data (tasks, inputs).

=head2 enqueue_plan

Enqueue a plan.

=head2 get_tasks

Get the tasks for a plan/run from the given table.

=head2 enqueue_run

Re-enqueue a run.

=head2

Create L<Minion> jobs for a run using L<Minion/enqueue>.

=head2 list_tasks

List tasks for a run.

=head1 SEE ALSO

L<Yancy>, L<Mojolicious>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
@@ migrations.mysql.sql

-- 1 up
CREATE TABLE zapp_plans (
    plan_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    label VARCHAR(255) NOT NULL,
    description TEXT,
    created DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE zapp_plan_tasks (
    task_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    plan_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    label VARCHAR(255),
    description TEXT,
    class VARCHAR(255) NOT NULL,
    input JSON,
    CONSTRAINT FOREIGN KEY ( plan_id ) REFERENCES zapp_plans ( plan_id ) ON DELETE CASCADE,
    UNIQUE ( plan_id, name )
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE zapp_plan_task_parents (
    task_id BIGINT REFERENCES zapp_plan_tasks ( task_id ) ON DELETE CASCADE,
    parent_task_id BIGINT REFERENCES zapp_plan_tasks ( task_id ) ON DELETE RESTRICT,
    PRIMARY KEY ( task_id, parent_task_id ),
    CONSTRAINT FOREIGN KEY ( task_id ) REFERENCES zapp_plan_tasks ( task_id ) ON DELETE CASCADE,
    CONSTRAINT FOREIGN KEY ( parent_task_id ) REFERENCES zapp_plan_tasks ( task_id ) ON DELETE CASCADE
);

CREATE TABLE zapp_plan_inputs (
    plan_id BIGINT NOT NULL,
    name VARCHAR(255) NOT NULL,
    `rank` INTEGER NOT NULL,
    type VARCHAR(255) NOT NULL,
    label VARCHAR(255),
    description TEXT,
    config JSON,
    value JSON,
    PRIMARY KEY ( plan_id, name ),
    CONSTRAINT FOREIGN KEY ( plan_id ) REFERENCES zapp_plans ( plan_id ) ON DELETE CASCADE
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE zapp_runs (
    run_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    plan_id BIGINT NULL,
    label VARCHAR(255) NOT NULL,
    description TEXT,
    input JSON,
    created DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    started DATETIME NULL,
    finished DATETIME NULL,
    state VARCHAR(20) NOT NULL DEFAULT 'inactive',
    CONSTRAINT FOREIGN KEY ( plan_id ) REFERENCES zapp_plans ( plan_id ) ON DELETE SET NULL
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE zapp_run_tasks (
    task_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    run_id BIGINT NOT NULL,
    plan_task_id BIGINT NULL,
    name VARCHAR(255) NOT NULL,
    label VARCHAR(255),
    description TEXT,
    class VARCHAR(255) NOT NULL,
    input JSON,
    output JSON,
    state VARCHAR(20) NOT NULL DEFAULT 'inactive',
    job_id BIGINT,
    CONSTRAINT FOREIGN KEY ( run_id ) REFERENCES zapp_runs ( run_id ) ON DELETE CASCADE,
    CONSTRAINT FOREIGN KEY ( plan_task_id ) REFERENCES zapp_plan_tasks ( task_id ) ON DELETE SET NULL,
    UNIQUE ( run_id, name )
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE TABLE zapp_run_task_parents (
    task_id BIGINT REFERENCES zapp_run_tasks ( task_id ) ON DELETE CASCADE,
    parent_task_id BIGINT REFERENCES zapp_run_tasks ( task_id ) ON DELETE RESTRICT,
    PRIMARY KEY ( task_id, parent_task_id ),
    CONSTRAINT FOREIGN KEY ( task_id ) REFERENCES zapp_run_tasks ( task_id ) ON DELETE CASCADE,
    CONSTRAINT FOREIGN KEY ( parent_task_id ) REFERENCES zapp_run_tasks ( task_id ) ON DELETE CASCADE
);

CREATE TABLE zapp_run_notes (
    note_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    run_id BIGINT NOT NULL,
    created DATETIME DEFAULT CURRENT_TIMESTAMP,
    event VARCHAR(20) NOT NULL,
    note TEXT NOT NULL,
    CONSTRAINT FOREIGN KEY ( run_id ) REFERENCES zapp_runs ( run_id ) ON DELETE CASCADE
);

-- 2 up
CREATE TABLE zapp_triggers (
    trigger_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    type VARCHAR(255) NOT NULL,
    label VARCHAR(255),
    description TEXT,
    plan_id BIGINT NOT NULL,
    config JSON,
    input JSON,
    state VARCHAR(20) DEFAULT 'inactive',
    CONSTRAINT FOREIGN KEY ( plan_id ) REFERENCES zapp_plans ( plan_id ) ON DELETE CASCADE
);
CREATE TABLE zapp_trigger_runs (
    trigger_id BIGINT NOT NULL,
    run_id BIGINT NOT NULL,
    context JSON,
    PRIMARY KEY ( trigger_id, run_id ),
    CONSTRAINT FOREIGN KEY ( trigger_id ) REFERENCES zapp_triggers ( trigger_id ) ON DELETE CASCADE,
    CONSTRAINT FOREIGN KEY ( run_id ) REFERENCES zapp_runs ( run_id ) ON DELETE CASCADE
);

@@ migrations.sqlite.sql

-- 1 up
CREATE TABLE zapp_plans (
    plan_id INTEGER PRIMARY KEY AUTOINCREMENT,
    label VARCHAR(255) NOT NULL,
    description TEXT,
    created DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE zapp_plan_tasks (
    task_id INTEGER PRIMARY KEY AUTOINCREMENT,
    plan_id BIGINT REFERENCES zapp_plans ( plan_id ) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    label VARCHAR(255),
    description TEXT,
    class VARCHAR(255) NOT NULL,
    input JSON,
    UNIQUE ( plan_id, name )
);

CREATE TABLE zapp_plan_task_parents (
    task_id BIGINT REFERENCES zapp_plan_tasks ( task_id ) ON DELETE CASCADE,
    parent_task_id BIGINT REFERENCES zapp_plan_tasks ( task_id ) ON DELETE RESTRICT,
    PRIMARY KEY ( task_id, parent_task_id )
);

CREATE TABLE zapp_plan_inputs (
    plan_id BIGINT REFERENCES zapp_plans ( plan_id ) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    rank INTEGER NOT NULL,
    type VARCHAR(255) NOT NULL,
    label VARCHAR(255),
    description TEXT,
    config JSON,
    value JSON,
    PRIMARY KEY ( plan_id, name )
);

CREATE TABLE zapp_runs (
    run_id INTEGER PRIMARY KEY AUTOINCREMENT,
    plan_id BIGINT REFERENCES zapp_plans ( plan_id ) ON DELETE SET NULL,
    label VARCHAR(255) NOT NULL,
    description TEXT,
    input JSON,
    created DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    started DATETIME NULL,
    finished DATETIME NULL,
    state VARCHAR(20) NOT NULL DEFAULT 'inactive'
);

CREATE TABLE zapp_run_tasks (
    task_id INTEGER PRIMARY KEY AUTOINCREMENT,
    run_id BIGINT NOT NULL REFERENCES zapp_runs ( run_id ) ON DELETE CASCADE,
    plan_task_id BIGINT NULL REFERENCES zapp_plan_tasks ( task_id ) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    label VARCHAR(255),
    description TEXT,
    class VARCHAR(255) NOT NULL,
    input JSON,
    output JSON,
    state VARCHAR(20) NOT NULL DEFAULT 'inactive',
    job_id BIGINT,
    UNIQUE ( run_id, name )
);

CREATE TABLE zapp_run_task_parents (
    task_id BIGINT REFERENCES zapp_run_tasks ( task_id ) ON DELETE CASCADE,
    parent_task_id BIGINT REFERENCES zapp_run_tasks ( task_id ) ON DELETE RESTRICT,
    PRIMARY KEY ( task_id, parent_task_id )
);

CREATE TABLE zapp_run_notes (
    note_id INTEGER PRIMARY KEY AUTOINCREMENT,
    run_id BIGINT NOT NULL REFERENCES zapp_runs ( run_id ) ON DELETE CASCADE,
    created DATETIME DEFAULT CURRENT_TIMESTAMP,
    event VARCHAR(20) NOT NULL,
    note TEXT NOT NULL
);

-- 2 up

CREATE TABLE zapp_triggers (
    trigger_id INTEGER PRIMARY KEY AUTOINCREMENT,
    type VARCHAR(255) NOT NULL,
    label VARCHAR(255),
    description TEXT,
    plan_id INTEGER NOT NULL REFERENCES zapp_plans ( plan_id ) ON DELETE CASCADE,
    config JSON,
    input JSON,
    state VARCHAR(20) DEFAULT 'inactive'
);
CREATE TABLE zapp_trigger_runs (
    trigger_id INTEGER NOT NULL REFERENCES zapp_triggers ( trigger_id ) ON DELETE CASCADE,
    run_id INTEGER NOT NULL REFERENCES zapp_runs ( run_id ) ON DELETE CASCADE,
    context JSON,
    PRIMARY KEY ( trigger_id, run_id )
);

