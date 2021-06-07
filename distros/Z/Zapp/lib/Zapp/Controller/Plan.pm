package Zapp::Controller::Plan;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::JSON qw( decode_json encode_json );
use List::Util qw( uniqstr );
use Zapp::Util qw( build_data_from_params );

# Zapp: Now, like all great plans, my strategy is so simple an idiot
# could have devised it.

sub edit_plan( $self ) {
    my @tasks =
        sort grep { !ref $_ && eval { $_->isa('Zapp::Task') } }
        values $self->minion->tasks->%*;
    my $plan = $self->stash( 'plan' ) || $self->app->get_plan( $self->stash( 'plan_id' ) );
    return $self->render(
        'zapp/plan/edit',
        plan => $plan,
        tasks => \@tasks,
    );
}

sub save_plan( $self ) {

    my $plan_id = $self->stash( 'plan_id' );
    my $plan = {
        map { $_ => $self->param( $_ ) }
        qw( label description ),
    };
    my $tasks = build_data_from_params( $self, 'task' );
    my $form_inputs = build_data_from_params( $self, 'input' );

    # XXX: Create transaction routine for Yancy::Backend
    if ( $plan_id ) {
        $self->yancy->backend->set( zapp_plans => $plan_id, $plan );
    }
    else {
        $plan_id = $self->yancy->backend->create( zapp_plans => $plan );
    }
    $plan->{plan_id} = $plan_id;

    # Validate all incoming data.
    my @errors;
    for my $i ( 0..$#$form_inputs ) {
        my $input = $form_inputs->[ $i ];
        if ( $input->{name} =~ /\P{Word}/ ) {
            my @chars = uniqstr sort $input->{name} =~ /\P{Word}/g;
            push @errors, {
                name => "input[$i].name",
                error => qq{Input name "$input->{name}" has invalid characters: }
                    . join( '', map { "<kbd>$_</kbd>" } @chars ),
            };
        }
        my $type = $self->app->zapp->types->{ $input->{type} }
            or die qq{Could not find type "$input->{type}"};
        eval {
            $input->{config} = $type->process_config( $self, $input->{config} );
        };
        if ( $@ ) {
            push @errors, {
                name => "input[$i].name",
                error => qq{Error validating input config "$input->{name}" type "$input->{type}": $@},
            };
        }
    }

    for my $i ( 0..$#$tasks ) {
        my $task = $tasks->[ $i ];
        if ( $task->{name} =~ /\P{Word}/ ) {
            my @chars = uniqstr sort $task->{name} =~ /\P{Word}/g;
            push @errors, {
                name => "task[$i].name",
                error => qq{Task name "$task->{name}" has invalid characters: }
                    . join( '', map { "<kbd>$_</kbd>" } @chars ),
            };
        }
    }

    my $f = $self->app->formula;
    for my $name ( grep /^task\[\d+\]\.input/, $self->req->params->names->@* ) {
        my ( $value ) = $self->param( $name ) =~ /^=(.+)/;
        next unless $value;
        local $@;
        eval { $f->parse( $value ) };
        if ( $@ ) {
            push @errors, {
                name => $name,
                error => qq{Failed to parse formula: $@},
            };
        }
    }

    if ( @errors ) {
        $self->log->error( "Error saving plan: " . $self->dumper( \@errors ) );
        $self->stash(
            status => 400,
            plan => {
                %$plan,
                tasks => $tasks,
                inputs => $form_inputs,
            },
            errors => \@errors,
        );
        return $self->edit_plan;
    }

    # XXX: Create sync routine for Yancy::Backend that takes a set of
    # items and updates the schema to look exactly like that (deleting,
    # updating, inserting as needed)
    my %tasks_to_delete
        = map { $_->{task_id} => 1 }
        $self->yancy->list( zapp_plan_tasks => { plan_id => $plan_id } );
    my $parent_task_id;
    for my $task ( @$tasks ) {
        my $task_id = $task->{task_id};

        # XXX: Auto-encode/-decode JSON fields in Yancy schema
        for my $json_field ( qw( input ) ) {
            $task->{ $json_field } = encode_json( $task->{ $json_field } );
        }

        if ( $task_id ) {
            delete $tasks_to_delete{ $task_id };
            $self->yancy->backend->set( zapp_plan_tasks => $task_id, $task );
        }
        else {
            delete $task->{task_id};
            $task_id = $task->{task_id} = $self->yancy->backend->create( zapp_plan_tasks => {
                %$task, plan_id => $plan_id,
            } );
        }

        if ( $parent_task_id ) {
            my ( @existing_parents ) = $self->yancy->list( zapp_plan_task_parents => { task_id => $task_id } );
            for my $parent ( @existing_parents ) {
                # We're supposed to have this row, so ignore it
                next if grep { $parent->{parent_task_id} eq $_ } ( $parent_task_id );
                # We're not supposed to have this row, so delete it
                $self->yancy->backend->delete( zapp_plan_task_parents => { $parent->%{qw( task_id parent_task_id )} } );
            }
            for my $new_parent ( $parent_task_id ) {
                # We already have this row, so ignore it
                next if grep { $new_parent eq $_->{parent_task_id} } @existing_parents;
                # We don't have this row, so create it
                $self->yancy->backend->create( zapp_plan_task_parents => {
                    task_id => $task_id,
                    parent_task_id => $parent_task_id,
                });
            }
        }
        $parent_task_id = $task_id;

    }

    for my $task_id ( keys %tasks_to_delete ) {
        $self->yancy->delete( zapp_plan_tasks => $task_id );
        my ( @existing_parents ) = $self->yancy->list( zapp_plan_task_parents => { task_id => $task_id } );
        for my $parent ( @existing_parents ) {
            $self->yancy->backend->delete( zapp_plan_task_parents => { $parent->%{qw( task_id parent_task_id )} } );
        }
    }

    my %input_to_delete = map { $_->{name} => $_ } $self->yancy->list( zapp_plan_inputs => { plan_id => $plan_id } );
    for my $i ( 0 .. $#$form_inputs ) {
        my $form_input = $form_inputs->[ $i ];
        $form_input->{rank} = $i;
        # XXX: Auto-encode/-decode JSON fields in Yancy schema
        for my $json_field ( qw( value config ) ) {
            $form_input->{ $json_field } = encode_json( $form_input->{ $json_field } );
        }

        my $name = $form_input->{name};
        if ( $input_to_delete{ $name } ) {
            delete $input_to_delete{ $name };
            $self->yancy->backend->set(
                zapp_plan_inputs => { plan_id => $plan_id, $form_input->%{'name'} }, $form_input,
            );
        }
        else {
            $self->yancy->backend->create(
                zapp_plan_inputs => { %$form_input, plan_id => $plan_id },
            );
        }
    }
    for my $name ( keys %input_to_delete ) {
        # XXX: Fix yancy backend composite keys to allow arrayref of
        # ordered columns
        $self->yancy->backend->delete( zapp_plan_inputs => { plan_id => $plan_id, name => $name } );
    }

    $self->redirect_to( 'zapp.edit_plan' => { plan_id => $plan_id } );
}

sub delete_plan( $self ) {
    my $plan_id = $self->stash( 'plan_id' );
    my $plan = $self->yancy->get( zapp_plans => $plan_id );
    if ( $self->req->method eq 'GET' ) {
        return $self->render(
            'zapp/plan/delete',
            plan => $plan,
        );
    }
    $self->yancy->delete( zapp_plans => $plan_id );
    # Clean up if foreign keys are disabled...
    # XXX: This can be removed when Yancy fixes the SQLite backend to
    # always enable foreign keys
    # XXX: Yancy should allow a query to the delete() function
    for my $task ( $self->yancy->list( zapp_plan_tasks => { plan_id => $plan_id } ) ) {
        for my $parent ( $self->yancy->list( zapp_plan_task_parents => { task_id => $task->{task_id} } ) ) {
            $self->yancy->delete( zapp_plan_task_parents => { $parent->%{qw( task_id parent_task_id )} } );
        }
        $self->yancy->delete( zapp_plan_tasks => $task->{task_id} );
    }
    for my $input ( $self->yancy->list( zapp_plan_inputs => { plan_id => $plan_id } ) ) {
        $self->yancy->delete( zapp_plan_inputs => { $input->%{qw( plan_id name )} } );
    }
    for my $run ( $self->yancy->list( zapp_runs => { plan_id => $plan_id } ) ) {
        $self->yancy->backend->set( zapp_runs => $run->{run_id}, { plan_id => undef } );
    }

    $self->redirect_to( 'zapp.list_plans' );
}

sub list_plans( $self ) {
    my @plans = $self->yancy->list( zapp_plans => {}, {} );
    for my $plan ( @plans ) {
        my ( $last_run ) = $self->yancy->list(
            zapp_runs => {
                $plan->%{'plan_id'},
            },
            { order_by => { -desc => [qw( created started finished )] } },
        );
        next if !$last_run;

        $plan->{ last_run } = $last_run;
    }
    # XXX: Order should be:
    #   1. Jobs that have no started
    #   2. Jobs that have no finished
    #   3. Jobs by finished datetime
    #   4. Jobs by started datetime
    #   5. Jobs by created datetime
    #   6. Plans by created datetime
    @plans = sort {
        !!( $b->{last_run} // '' ) cmp !!( $a->{last_run} // '' )
        || (
            defined $a->{last_run} && (
                ( $b->{last_run}{state} =~ /(in)?active/n ) cmp ( $a->{last_run}{state} =~ /(in)?active/n )
                || ($b->{last_run}{finished}//'') cmp ($a->{last_run}{finished}//'')
                || ($b->{last_run}{started}//'') cmp ($a->{last_run}{started}//'')
            )
        )
        || $b->{created} cmp $a->{created}
    } @plans;
    $self->render( 'zapp/plan/list', plans => \@plans );
}

sub get_plan( $self ) {
    my $plan = $self->app->get_plan( $self->param( 'plan_id' ) ) // return $self->reply->not_found;
    my @runs = $self->yancy->list( zapp_runs => { plan_id => $plan->{plan_id} }, { limit => 10 } );
    my @triggers = $self->yancy->list( zapp_triggers => { plan_id => $plan->{plan_id} } );
    return $self->render(
        'zapp/plan/view',
        plan => $plan,
        runs => \@runs,
        triggers => \@triggers,
    );
}

1;

__END__

=pod

=head1 NAME

Zapp::Controller::Plan

=head1 VERSION

version 0.004

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
