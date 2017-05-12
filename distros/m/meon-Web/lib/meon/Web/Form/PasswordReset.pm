package meon::Web::Form::PasswordReset;

use meon::Web::Member;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';
with 'meon::Web::Role::Form';

has '+name' => (default => 'form_password_reset');
has '+widget_wrapper' => ( default => 'Bootstrap' );

has_field 'email' => ( type => 'Email', required => 1, label => 'Email' );
has_field 'submit'   => ( type => 'Submit', value => 'Submit', );

sub submitted {
    my ($self) = @_;

    my $c = $self->c;
    $c->log->debug(__PACKAGE__.' '.Data::Dumper::Dumper($c->req->params))
        if $c->debug;

    my $members_folder = $c->default_auth_store->folder;
    my $detach         = $self->get_config_text('detach');
    my $from           = $self->get_config_text('from');
    my $pw_change      = $self->get_config_text('pw-change');

    my $email = $self->field('email')->value;
    my $member = meon::Web::Member->find_by_email(
        members_folder => $members_folder,
        email          => $email,
    );

    unless ($member) {
        $self->field('email')->add_error('no such email found');
        return;
    }

    $member->send_password_reset(
        $from,
        $c->uri_for($pw_change),
    );
    $self->detach($detach);
}

no HTML::FormHandler::Moose;

1;
