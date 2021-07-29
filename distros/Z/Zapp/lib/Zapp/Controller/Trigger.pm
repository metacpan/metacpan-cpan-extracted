package Zapp::Controller::Trigger;
# ABSTRACT: Web handlers for trigger management

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::JSON qw( decode_json encode_json );
use Zapp::Util qw( build_data_from_params );

#pod =method edit
#pod
#pod Create or edit a trigger. A C<GET> request shows the form. A C<POST>
#pod request saves the form and returns the user to the plan view.
#pod
#pod When creating a new trigger, the C<plan_id> and C<class> params must be
#pod defined. When editing a trigger, the C<trigger_id> param must be
#pod defined.
#pod
#pod =cut

sub edit( $self ) {
    if ( $self->req->method eq 'GET' ) {
        my $trigger;
        if ( my $trigger_id = $self->param( 'trigger_id' ) ) {
            $trigger = $self->app->yancy->get( zapp_triggers => $trigger_id );
        }
        else {
            $trigger = {
                type => $self->param( 'type' ),
                plan_id => $self->param( 'plan_id' ),
            };
        }

        # XXX: Auto-decode JSON in Yancy
        $trigger->{config} &&= decode_json( $trigger->{config} );
        my $plan = $self->app->get_plan( $trigger->{plan_id} );

        return $self->render(
            'zapp/trigger/edit',
            trigger => $trigger,
            inputs => $plan->{inputs},
        );
    }

    my $trigger = build_data_from_params( $self );
    $trigger->{$_} &&= encode_json( $trigger->{$_} ) for qw( config input );
    my $trigger_id = $self->param( 'trigger_id' );
    # XXX: Make Yancy set forward to create() when the ID is undef
    if ( $trigger_id ) {
        $self->yancy->set( zapp_triggers => $trigger_id, $trigger );
    }
    else {
        $trigger_id = $self->yancy->create( zapp_triggers => $trigger );
    }

    return $self->redirect_to( 'zapp.list_plans' );
}

1;

__END__

=pod

=head1 NAME

Zapp::Controller::Trigger - Web handlers for trigger management

=head1 VERSION

version 0.005

=head1 METHODS

=head2 edit

Create or edit a trigger. A C<GET> request shows the form. A C<POST>
request saves the form and returns the user to the plan view.

When creating a new trigger, the C<plan_id> and C<class> params must be
defined. When editing a trigger, the C<trigger_id> param must be
defined.

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
