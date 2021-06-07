package Zapp::Task;
# ABSTRACT: Base class for individual steps in a job

#pod =head1 SYNOPSIS
#pod
#pod     package My::Task::Greet;
#pod     use Mojo::Base 'Zapp::Task', -signatures;
#pod
#pod     # Perform the task
#pod     sub run( $self, $input ) {
#pod         return $self->fail( 'No-one to greet' ) if !$input->{who};
#pod         return $self->finish({
#pod             greeting => "Hello, $input->{who}!",
#pod         });
#pod     }
#pod
#pod     1;
#pod
#pod     __DATA__
#pod     @@ input.html.ep
#pod     %# Display the form to configure this task
#pod     %= text_field 'who', value => $input->{who}
#pod
#pod     @@ output.html.ep
#pod     %# Show the result of this task
#pod     %# XXX: Switch to $task->{error} if it's an actual error
#pod     % if ( !ref $task->{output} ) {
#pod         <p>I couldn't send a greeting: <%= $task->{output} %></p>
#pod     % }
#pod     % else {
#pod         <p>I sent a greeting of <q><%= $task->{output}{greeting} %></q></p>
#pod     % }
#pod
#pod =head1 DESCRIPTION
#pod
#pod L<Zapp::Task> is the base class for all tasks. Tasks are the individual
#pod steps of a job. Each task has an input template to configure its input
#pod and an output template to display its output. Task input and output are
#pod declared with JSON Schema (see the L</schema> method), and input will be
#pod processed with L<Zapp::Formula> before being given to L</run>.
#pod
#pod =head2 Creating a Task
#pod
#pod To create a task, start by extending this class. Create a C<run> method
#pod that takes one argument, C<$input>.  Inside this method, do the work you
#pod want to do. Then, in the C<DATA> section of your module, create two
#pod templates: C<input.html.ep> for the input form, and C<output.html.ep>
#pod for the output display.
#pod
#pod The input form should have a set of fields. Field names will be used as
#pod the keys to the C<$input> hash reference given to the C<run> method. You
#pod can build complex data structures using C<[\d]> to make arrays and C<.>
#pod to nest hashes (see L<Zapp::Util/build_data_from_params>).
#pod
#pod     <!-- { name => 'Planet Express', loc => { city => 'New New York' } } -->
#pod     <input name="name" value="Planet Express">
#pod     <input name="loc.city" value="New New York">
#pod
#pod Input forms can also use special C<data-zapp-*> attributes to add
#pod dynamic features without writing the JavaScript yourself. See
#pod L<Mojo::Util/parse_zapp_attrs>.
#pod
#pod Your C<run> method should do the actual work, and then call either
#pod C<finish> (for success) or C<fail> (for failure) with the output data.
#pod This data will be given to the C<output.html.ep> template for display.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Zapp::Task::Action>, L<Minion::Job>, L<Zapp>
#pod
#pod =cut

use Mojo::Base 'Minion::Job', -signatures;
use List::Util qw( uniq );
use Time::Piece;
use Mojo::JSON qw( decode_json encode_json );
use Zapp::Util qw( get_path_from_data get_path_from_schema );
use Yancy::Util qw( currym );

has zapp_task => sub( $self ) {
    my ( $task ) = $self->app->yancy->list( zapp_run_tasks => { job_id => $self->id } );
    return $task;
};

has zapp_run => sub( $self ) {
    my $task = $self->zapp_task;
    return $self->app->yancy->get( zapp_runs => $task->{run_id} );
};

# Cached lookups of output from run input and output from other tasks in
# this run. Run input is added here. Task output is filled-in by context()
# XXX: Make a Zapp::Run class to put this code, accessible from
# $self->app->zapp->run()
has _context => sub( $self ) {
    my $run_input = decode_json( $self->zapp_run->{ input } );
    my %context;
    for my $input ( @$run_input ) {
        my $type = $self->app->zapp->types->{ $input->{type} }
            or die qq{Could not find type "$input->{type}"};
        $context{ $input->{name} } = $type->task_input( $input->{config}, $input->{value} );
    }
    return \%context;
};

sub new( $class, @args ) {
    my $self = $class->SUPER::new( @args );
    # Process the initial arguments passed-in
    $self->args( $self->args );
    return $self;
}

sub set( $self, %values ) {
    $self->app->yancy->backend->set(
        zapp_run_tasks => $self->zapp_task->{task_id},
        \%values,
    );
    if ( exists $values{state} ) {
        my $run = $self->zapp_run;
        my $run_state = $run->{state};
        if ( $values{state} =~ /(active|failed|stopped|killed)/ && $run->{state} ne $values{state} ) {
            # One job in these states can change the run state
            $run_state = $values{state};
        }
        elsif ( $values{state} =~ /(inactive|finished)/ ) {
            # All tasks must be in this state to change the run state
            my @task_states = uniq map $_->{state}, $self->app->yancy->list( zapp_run_tasks => { $run->%{'run_id'} } );
            if ( @task_states == 1 && $task_states[0] eq $values{state} ) {
                $run_state = $values{state};
            }
        }

        if ( $run_state ne $run->{state} ) {
            $self->app->yancy->backend->set(
                zapp_runs => $run->{run_id},
                {
                    state => $run_state,
                    (
                        $run_state eq 'active' ? ( started => Time::Piece->new( $self->info->{started} )->datetime )
                        : $run_state ne 'inactive' ? ( finished => Time::Piece->new( $self->info->{finished} )->datetime )
                        : ()
                    ),
                },
            );
        }
    }
}

sub context( $self, $var ) {
    my $context = $self->_context;
    my ( $name ) = $var =~ m{^([^\[.]+)};
    if ( !$context->{ $name } ) {
        my ( $task ) = $self->app->yancy->list(
            zapp_run_tasks => {
                $self->zapp_run->%{'run_id'},
                name => $name,
            },
        );
        if ( $task && $task->{state} eq 'finished' ) {
            $context->{ $name } = decode_json( $task->{output} );
        }
    }
    return get_path_from_data( $var, $context );
}

sub args( $self, $new_args=undef ) {
    if ( $new_args ) {
        # Process before storing
        my $args = $self->process_input( $new_args );
        return $self->SUPER::args( $args );
    }
    return $self->SUPER::args;
}

sub execute( $self, @args ) {
    $self->set( state => 'active' );
    return $self->SUPER::execute( @args );
}

sub finish( $self, $output=undef ) {
    # Minion calls this again while reaping the child process, so bail
    # out if we're in the parent process after having started a child.
    # XXX: This may be a problem when trying to run a job synchronously
    # in a web request...
    return $self->SUPER::finish if $self->{pid};

    my $run_job = $self->zapp_task;
    my ( $run_id, $task_id ) = $run_job->@{qw( run_id task_id )};

    # XXX: Run output through task_output

    $self->app->yancy->backend->set(
        zapp_run_tasks => $task_id,
        { output => encode_json( $output ) },
    );

    my $ok = $self->SUPER::finish( $output );
    # Set state after so run `finished` timestamp can be set
    $self->set( state => 'finished' );
    return $ok;
}

sub fail( $self, $output=undef ) {
    $self->set( state => 'failed' );
    my $run_job = $self->zapp_task;
    my ( $run_id, $task_id ) = $run_job->@{qw( run_id task_id )};
    # XXX: Run output through task_output
    $self->app->yancy->backend->set(
        zapp_run_tasks => $task_id,
        { output => encode_json( $output ) },
    );
    return $self->SUPER::fail( $output );
}

# XXX: Process input and output are the same subroutines with two small
# changes: 1. task_(input|output) 2. input evals formulas

sub process_input( $self, $input ) {
    if ( !ref $input ) {
        if ( $input =~ /^=(?!=)/ ) {
            my $expr = substr $input, 1;
            $input = $self->app->formula->eval( $expr, currym( $self, 'context' ) );
        }
        # XXX: Run through task_input
        return $input;
    }
    elsif ( ref $input eq 'ARRAY' ) {
        return [
            map { $self->process_input( $_ ) }
            $input->@*
        ];
    }
    elsif ( ref $input eq 'HASH' ) {
        return {
            map { $_ => $self->process_input( $input->{$_} ) }
            keys $input->%*
        };
    }
    die "Unknown ref type for data: " . ref $input;
}

sub process_output( $self, $output, $path='' ) {
    if ( !ref $output ) {
        # XXX: Find type in schema and run through task_output
        my $schema = get_path_from_schema( $path, $self->schema->{output} );
        return $output;
    }
    elsif ( ref $output eq 'ARRAY' ) {
        return [
            map { $self->process_output( $output->[ $_ ], $path . "[$_]" ) }
            0..$output->$#*
        ];
    }
    elsif ( ref $output eq 'HASH' ) {
        return {
            map { $_ => $self->process_output( $output->{$_}, $path . ".$_" ) }
            keys $output->%*
        };
    }
    die "Unknown ref type for data: " . ref $output;
}

sub schema( $class ) {
    return {
        input => {
            type => 'array',
        },
        output => {
            type => 'string',
        },
    };
}

1;

__END__

=pod

=head1 NAME

Zapp::Task - Base class for individual steps in a job

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    package My::Task::Greet;
    use Mojo::Base 'Zapp::Task', -signatures;

    # Perform the task
    sub run( $self, $input ) {
        return $self->fail( 'No-one to greet' ) if !$input->{who};
        return $self->finish({
            greeting => "Hello, $input->{who}!",
        });
    }

    1;

    __DATA__
    @@ input.html.ep
    %# Display the form to configure this task
    %= text_field 'who', value => $input->{who}

    @@ output.html.ep
    %# Show the result of this task
    %# XXX: Switch to $task->{error} if it's an actual error
    % if ( !ref $task->{output} ) {
        <p>I couldn't send a greeting: <%= $task->{output} %></p>
    % }
    % else {
        <p>I sent a greeting of <q><%= $task->{output}{greeting} %></q></p>
    % }

=head1 DESCRIPTION

L<Zapp::Task> is the base class for all tasks. Tasks are the individual
steps of a job. Each task has an input template to configure its input
and an output template to display its output. Task input and output are
declared with JSON Schema (see the L</schema> method), and input will be
processed with L<Zapp::Formula> before being given to L</run>.

=head2 Creating a Task

To create a task, start by extending this class. Create a C<run> method
that takes one argument, C<$input>.  Inside this method, do the work you
want to do. Then, in the C<DATA> section of your module, create two
templates: C<input.html.ep> for the input form, and C<output.html.ep>
for the output display.

The input form should have a set of fields. Field names will be used as
the keys to the C<$input> hash reference given to the C<run> method. You
can build complex data structures using C<[\d]> to make arrays and C<.>
to nest hashes (see L<Zapp::Util/build_data_from_params>).

    <!-- { name => 'Planet Express', loc => { city => 'New New York' } } -->
    <input name="name" value="Planet Express">
    <input name="loc.city" value="New New York">

Input forms can also use special C<data-zapp-*> attributes to add
dynamic features without writing the JavaScript yourself. See
L<Mojo::Util/parse_zapp_attrs>.

Your C<run> method should do the actual work, and then call either
C<finish> (for success) or C<fail> (for failure) with the output data.
This data will be given to the C<output.html.ep> template for display.

=head1 SEE ALSO

L<Zapp::Task::Action>, L<Minion::Job>, L<Zapp>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
