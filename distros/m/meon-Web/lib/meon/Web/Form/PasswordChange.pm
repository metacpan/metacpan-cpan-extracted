package meon::Web::Form::PasswordChange;

use meon::Web::Util;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';
with 'meon::Web::Role::Form';

has '+name' => (default => 'form_password_change');
has '+widget_wrapper' => ( default => 'Bootstrap' );

has_field 'old_password' => (
    type => 'Password', required => 0, label => 'Old Password',
    element_class => 'no-hide',
    element_attr => { placeholder => 'please enter your current password' }
);
has_field 'password'     => (
    type => 'Password', required => 0, label => 'New Password',
    element_class => 'no-hide',
    element_attr => { placeholder => 'please enter minimum 8 characters' }
);
has_field 'password_conf'=> (
    type => 'Password', required => 0, label => 'Confirm Password Change',
    element_class => 'no-hide',
    element_attr => { placeholder => 'please retype your new password' }
);

has_field 'submit' => ( type => 'Submit', value => 'Update', element_class => 'btn btn-primary', );

before 'process' => sub {
    my $self = shift;

    $self->field('old_password')->inactive(1)
        if $self->old_pw_not_required;
};

sub old_pw_not_required {
    my $self = shift;
    $self->c->session->{old_pw_not_required}
}

sub validate {
    my $self = shift;

    my $usr     = $self->c->user;
    my $old_pw  = $self->values->{old_password};
    my $new_pw  = $self->values->{password};
    my $new_pw2 = $self->values->{password_conf};

    return if (length($old_pw.$new_pw.$new_pw2) == 0);

    unless ($self->old_pw_not_required) {
        if (length($old_pw)) {
            $self->field('old_password')->add_error('Incorrect password')
                unless ($usr->check_password($old_pw));
        }
        else {
            $self->field('old_password')->add_error('Required');
        }
    }

    if (length($new_pw)) {
        $self->field('password')->add_error('Password too short. Please enter at least 8 characters.')
            if (length($new_pw) < 8);
    }
    else {
        $self->field('password')->add_error('Required');
    }

    if (length($new_pw2)) {
        $self->field('password_conf')->add_error('Confirmation password does not match')
            unless ($new_pw eq $new_pw2);
    }
    else {
        $self->field('password_conf')->add_error('Required');
    }
}

sub submitted {
    my ($self) = @_;

    my $c = $self->c;
    my $xml = $c->model('ResponseXML')->dom;
    my $xpc = meon::Web::Util->xpc;
    my $detach_path = $self->get_config_text('detach');

    return unless $self->is_valid;

    delete $c->session->{old_pw_not_required};
    my $password = $self->field('password')->value;
    $c->user->set_password($password);

    $self->detach($detach_path);
}

no HTML::FormHandler::Moose;

1;
