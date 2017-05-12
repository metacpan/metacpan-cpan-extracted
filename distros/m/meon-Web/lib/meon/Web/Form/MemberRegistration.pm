package meon::Web::Form::MemberRegistration;

use 5.010;

use List::MoreUtils 'uniq';
use Email::MIME;
use Email::Sender::Simple qw(sendmail);
use Data::Dumper;
use meon::Web::Util;
use meon::Web::Member;
use Path::Class 'dir';
use Data::Header::Fields;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';
with 'meon::Web::Role::Form';

has_field 'submit'   => ( type => 'Submit', value => 'Submit', );

before 'validate' => sub {
    my ($self) = @_;

    $self->add_form_error('Are you real?')
        if $self->c->req->param('yreo');
};

sub _build_configured_field_list {
    my $self = shift;

    # check if there are mandatory settings
    $self->get_config_text('rcpt-to');
    $self->get_config_text('subject');
}

sub submitted {
    my ($self) = @_;

    my $c   = $self->c;
    my $xpc = meon::Web::Util->xpc;
    my $xml = $c->model('ResponseXML')->dom;
    my %params  = %{$c->req->params};
    $c->log->debug(__PACKAGE__.' '.Data::Dumper::Dumper($c->req->params))
        if $c->debug;

    my $email = $c->req->param('email');
    my $password = $c->req->param('password') // '';
    my $all_required_set = 1;
    my $members_folder = $c->default_auth_store->folder;

    my $login = eval { $self->get_config_text('login') };
    if ($login) {
        my $member = meon::Web::Member->find_by_email(
            members_folder => $members_folder,
            email          => $email,
        );
        if ($member) {
            if ($member->user->check_password($password)) {
                my $username = $member->username;
                $c->set_authenticated($c->find_user({ username => $member->user->username }));
                return $self->detach;
            }
            else {
                $all_required_set = 0;
                $c->session->{form_input_errors}->{'password'} = 'wrong password';
            }

        }
    }

    my %inputs = map { $_->getAttribute('name') => $_ } $xpc->findnodes('.//x:input|.//x:select|.//x:textarea',$xml);
    foreach my $key (keys %params) {
        next unless my $input = $inputs{$key};
        my $value = $params{$key} // '';
        $value =~ s/\r//g;
        $value = undef if (length($value) == 0);
        if (!defined($value) && $input->getAttribute('required')) {
            $all_required_set = 0;
            $c->session->{form_input_errors}->{$key} = 'Required';
        }
    }
    foreach my $input (values %inputs) {
        my $input_name = $input->getAttribute('name');
        my $input_value = $params{$input_name} // '';
        next if (($input->getAttribute('type') // '') eq 'submit');

        my $nodeName = $input->nodeName;
        if ($nodeName eq 'select') {        
            my ($option) = $xpc->findnodes('.//x:option[@value="'.$input_value.'"]',$input);
            $option->setAttribute('selected' => 'selected')
                if $option;
        } elsif ($nodeName eq 'textarea') {
            $input->removeChildNodes();
            $input->appendText($input_value)
        } else {
            $input->setAttribute(value => $input_value);
        }
    }
    return unless $all_required_set;

    my $members_folder = $c->default_auth_store->folder;
    my $username = (
        meon::Web::env->hostname_config->{'auth'}{'external'}
        ? $c->session->{external_auth_username}
        : meon::Web::Util->username_cleanup((
                $c->req->param('username')
                // $c->req->param('name')
                // $c->req->param('email')
                // ''
            ),
            $members_folder,
        )
    );
    $c->req->params->{username} = $username;

    my $member_folder = dir($members_folder, $username);
    mkdir($member_folder) or die 'failed to create member folder: '.$!;

    my $rcpt_to  = $self->get_config_text('rcpt-to');
    my $subject  = $self->get_config_text('subject');
    $subject    .= ' - '.$c->req->param('name')
        if $c->req->param('name');
    my $detach   = $self->get_config_text('detach');

    my $email_content = '';

    my (@input_names) =
        uniq
        grep { defined $_ }
        map { $_->getAttribute('name') }
        grep { $_->getAttribute('type') !~ /password/i }
        $xpc->findnodes('//x:form//x:input | //x:form//x:select | //x:form//x:textarea',$xml);

    my @args;
    my $dhf = Data::Header::Fields->new;
    foreach my $input_name (@input_names) {
        my $input_value = $c->req->param($input_name) // '';
        next unless length $input_value;
        push(@args, [ $input_name => $input_value ]);
        $dhf->set_value($input_name => ' '.$input_value);
    }
    $email_content .= $dhf->encode;

    # create user xml file
    my $member = meon::Web::Member->new(
        members_folder => $members_folder,
        username       => $username,
    );
    $member->create(
        name    => $c->req->param('name') // '',
        email   => $c->req->param('email') // '',
        sex     => $c->req->param('sex') // '',
        address => $c->req->param('address') // '',
        lat     => $c->req->param('lat') // '',
        lng     => $c->req->param('lng') // '',
        registration_form => $email_content,
    );
    if ($password) {
        $member->user->set_password($password);
        if (eval { $self->get_config_text('auto-activate') } // 0 ) {
            $member->user->set_status('active');
            $c->set_authenticated($c->find_user({ username => $member->user->username }));
        }
    }

    meon::Web::Util->send_email(
        from    => $c->req->param('email'),
        to      => $rcpt_to,
        subject => $subject,
        text    => $email_content,
    );

    $self->detach($detach);
}

no HTML::FormHandler::Moose;

1;
