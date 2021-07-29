package Zapp::Trigger;
# ABSTRACT: Trigger a plan from an event

#pod =head1 SYNOPSIS
#pod
#pod     package My::Trigger;
#pod     use Mojo::Base 'Zapp::Trigger', -signatures;
#pod
#pod     sub install( $self, $app, $config={} ) {
#pod         $self->SUPER::install( $app, $config );
#pod         # Set up trigger to call $self->enqueue when needed
#pod     }
#pod
#pod     __DATA__
#pod     @@ config.html.ep
#pod     %# Form to configure trigger
#pod
#pod =head1 DESCRIPTION
#pod
#pod This is the base class for Zapp triggers. Triggers handle events and run
#pod configured plans. Triggers can accept configuration and plan input.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Zapp>
#pod
#pod =cut

use Mojo::Base -base, -signatures;
use Mojo::JSON qw( decode_json encode_json );
use Scalar::Util qw( blessed );
use Mojo::Loader qw( data_section );

#pod =attr app
#pod
#pod The application object.
#pod
#pod =cut

has app => ;

#pod =attr moniker
#pod
#pod The name of the trigger. Multiple configurations for a trigger class
#pod should have different names.
#pod
#pod =cut

has moniker => ;

#pod =method install
#pod
#pod Called automatically when adding the trigger. Should be overridden to set up
#pod any routes, timers, connections, or other kind of listeners to fire the
#pod configured triggers.
#pod
#pod =cut

sub install( $self, $app, $config={} ) {
    $self->app( $app );
}

sub create( $self, $data ) {
    # Created a new trigger
    $data->{class} //= blessed $self;
    $data->{state} //= "inactive";
    # XXX: Auto-encode JSON in Yancy
    $data->{config} = encode_json( $data->{config} // {} );
    $data->{input} = encode_json( $data->{input} // {} );

    return $self->app->yancy->create( zapp_triggers => $data );
}

sub delete( $self, $trigger_id ) {
    return $self->app->yancy->delete( zapp_triggers => $trigger_id );
}

sub set( $self, $trigger_id, $data ) {
    # XXX: Auto-encode JSON in Yancy
    $data->{config} &&= encode_json( $data->{config} );
    $data->{input} &&= encode_json( $data->{input} );
    return $self->app->yancy->set( zapp_triggers => $trigger_id, $data );
}

#pod =method enqueue
#pod
#pod Enqueue the plan for the given trigger ID. The plan input will be processed via
#pod L<Zapp::Formula/resolve>, passing in the given C<context> hash reference of data.
#pod Returns the run enqueued (from L<Zapp/enqueue_plan>).
#pod
#pod =cut

sub enqueue( $self, $trigger_id, $context ) {
    # Called by the trigger to enqueue a job. Creates a row in
    # zapp_trigger_runs automatically.
    my $trigger = $self->app->yancy->get( zapp_triggers => $trigger_id );

    # Should modify $input from the trigger input to the plan input, if
    # needed.
    my $raw_input = decode_json( $trigger->{input} );
    my %input;
    for my $field ( keys %$raw_input ) {
        my $raw_value = $raw_input->{ $field }{ value };
        $input{ $field } = $self->app->formula->resolve( $raw_value, $context );
    }

    my $run = $self->app->enqueue_plan( $trigger->{plan_id}, \%input );
    $self->app->yancy->create(
        zapp_trigger_runs => {
            trigger_id => $trigger_id,
            run_id => $run->{ run_id },
            context => encode_json( $context ),
        },
    );

    return $run;
}

sub config_field( $self, $c, $config_value=undef ) {
    my $class = blessed $self;
    my $tmpl = data_section( $class, 'config.html.ep' );
    return '' if !$tmpl;
    # XXX: Use Mojo::Template directly to get better names than 'inline
    # template XXXXXXXXXXXX'?
    return $c->render_to_string(
        inline => $tmpl,
        self => $self,
        config => $config_value,
    );
}

1;

=pod

=head1 NAME

Zapp::Trigger - Trigger a plan from an event

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    package My::Trigger;
    use Mojo::Base 'Zapp::Trigger', -signatures;

    sub install( $self, $app, $config={} ) {
        $self->SUPER::install( $app, $config );
        # Set up trigger to call $self->enqueue when needed
    }

    __DATA__
    @@ config.html.ep
    %# Form to configure trigger

=head1 DESCRIPTION

This is the base class for Zapp triggers. Triggers handle events and run
configured plans. Triggers can accept configuration and plan input.

=head1 ATTRIBUTES

=head2 app

The application object.

=head2 moniker

The name of the trigger. Multiple configurations for a trigger class
should have different names.

=head1 METHODS

=head2 install

Called automatically when adding the trigger. Should be overridden to set up
any routes, timers, connections, or other kind of listeners to fire the
configured triggers.

=head2 enqueue

Enqueue the plan for the given trigger ID. The plan input will be processed via
L<Zapp::Formula/resolve>, passing in the given C<context> hash reference of data.
Returns the run enqueued (from L<Zapp/enqueue_plan>).

=head1 SEE ALSO

L<Zapp>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__