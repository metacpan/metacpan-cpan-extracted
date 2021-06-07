package Test::Zapp;

use Mojo::Base 'Test::Mojo';
use Mojo::JSON qw( encode_json );
use Mojo::File qw( tempdir );
use Mojo::Home;
use Zapp;
use Scalar::Util qw( blessed );
use Test::More;

sub new {
    my $class = shift;
    # Test Zapp itself by default
    if ( !@_ || ( ref $_[0] && !blessed $_[0] ) ) {
        unshift @_, Zapp->new(
            home => Mojo::Home->new( tempdir ),
        );
    }
    my $t = $class->SUPER::new( @_ );
    $t->app->ua( $t->ua );
    return $t;
}

sub render_ok {
    my ( $self, @args ) = @_;
    my @tmpl;
    my $name = 'render template succeeds';
    if ( $args[0] eq 'inline' ) {
        @tmpl = ( shift @args, shift @args );
    }
    if ( @args % 2 == 1 ) {
        $name = pop @args;
    }

    my $output;
    eval {
        $output = $self->app->build_controller->render_to_string( @tmpl, @args );
    };
    $self->test( ok => !$@, $name );
    if ( !$self->success ) {
        diag "Render error: $@";
        return $self;
    }

    # Magic up a TX and response so that Test::Mojo methods work
    $self->tx( $self->ua->build_tx( GET => '/render_ok' ) );
    my $res = $self->tx->res;
    $res->code( 200 );
    $res->message( "Ok" );
    $res->content->asset->add_chunk( $output );

    return $self;
}

sub run_queue {
    my ( $self ) = @_;
    # Run all tasks on the queue
    my $worker = $self->app->minion->worker->register;
    while ( my $job = $worker->dequeue(0) ) {
        my $e = $job->execute;
        $self->test( 'ok', !$e, 'job executed successfully' );
        $self->or( sub { diag "Job error: ", explain $e } );
        last if $e;
    }
    $worker->unregister;
}

sub run_task {
    my ( $self, $task_class, $input, $context, $name ) = @_;
    if ( !ref $context ) {
        $name = $context;
        $context = [];
    }
    # XXX: We no longer need to create a plan to create a run
    my $plan = $self->{zapp}{plan} = $self->app->create_plan({
        label => $name // "Test $task_class",
        tasks => [
            {
                name => $task_class,
                class => $task_class,
                input => encode_json( $input ),
            },
        ],
        inputs => $context,
    });
    my $run = $self->{zapp}{run} = $self->app->enqueue_plan(
        $plan->{plan_id},
        { map $_->@{qw( name value )}, @$context },
    );

    my $worker = $self->app->minion->worker->register;
    my $job = $self->{zapp}{job} = $worker->dequeue;
    my $e = $job->execute;
    $self->test( 'ok', !$e, 'job executed successfully' );
    $self->or( sub { diag "Job error: ", explain $e } );
    $worker->unregister;
    return $self;
}

sub task_output_is {
    my ( $self, $key, $output, $name ) = @_;
    my $result = $self->{zapp}{job}->info->{result};
    if ( !ref $key ) {
        $result = $result->{ $key };
    }
    else {
        $name = $output;
        $output = $key;
        undef $key;
    }

    $self->test( 'is_deeply', $result, $output, $name );
}

sub task_output_like {
    my ( $self, $key, $output, $name ) = @_;
    my $result = $self->{zapp}{job}->info->{result}{$key};
    $self->test( 'like', $result, $output, $name );
}

sub task_info_is {
    my ( $self, $info_key, $info_value, $name ) = @_;
    $self->test( 'is', $self->{zapp}{job}->info->{$info_key}, $info_value, $name );
}

sub clear_backend {
    my ( $self ) = @_;
    $self->Test::Yancy::clear_backend;
    $self->app->minion->reset({ all => 1 });
    return $self;
}

sub Test::Yancy::clear_backend {
    my ( $self ) = @_;
    my %tables = (
        zapp_plans => 'plan_id',
        zapp_plan_inputs => [ 'plan_id', 'name' ],
        zapp_plan_tasks => 'task_id',
        zapp_plan_task_parents => [ 'task_id', 'parent_task_id' ],
        zapp_runs => 'run_id',
    );
    for my $table ( keys %tables ) {
        my $id_field = $tables{ $table };
        for my $item ( $self->app->yancy->list( $table ) ) {
            my $id = ref $id_field eq 'ARRAY'
                ? { map { $_ => $item->{ $_ } } @$id_field }
                : $item->{ $id_field }
                ;
            $self->app->yancy->backend->delete( $table => $id );
        }
    }
}

1;

__END__

=pod

=head1 NAME

Test::Zapp

=head1 VERSION

version 0.004

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
