package meon::Web::Form::SendEmail;

use strict;
use warnings;
use 5.010;

use List::MoreUtils 'uniq';
use Email::MIME;
use Email::Sender::Simple qw(sendmail);
use Data::Dumper;
use meon::Web::Util;
use meon::Web::Member;
use Path::Class 'dir';
use File::MimeInfo 'mimetype';

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';
with 'meon::Web::Role::Form';

has_field 'submit'   => ( type => 'Submit', value => 'Submit', );

before 'validate' => sub {
    my ($self) = @_;

    $self->add_form_error('Are you real?')
        if $self->c->req->param('yreo');
};

sub submitted {
    my ($self) = @_;

    my $c   = $self->c;
    my $xpc = meon::Web::Util->xpc;
    $c->log->debug(__PACKAGE__.' '.Data::Dumper::Dumper($c->req->params))
        if $c->debug;

    my $from = ($c->user_exists ? $c->member->email : 'no-reply@meon.eu');

    my $xml = $c->model('ResponseXML')->dom;
    my $rcpt_to  = $self->get_config_text('rcpt-to');
    my $subject  = $self->get_config_text('subject');
    $subject    .= ' - '.$c->req->param('email')
        if $c->req->param('name');
    $subject    .= ' - '.$c->req->param('subject')
        if $c->req->param('subject');
    my $detach   = $self->get_config_text('detach');
    my $email_content = '';

    my @input_names;
    my @file_attachments;
    foreach my $input ($xpc->findnodes('//x:form//x:input | //x:form//x:textarea',$xml)) {
        my $field_name = $input->getAttribute('name');
        my $field_type = lc($input->getAttribute('type') // '');
        next unless $input;

        if ($field_type eq 'file') {
            my $upload = $c->req->upload($field_name);
            if ($upload) {
                push(@file_attachments, Email::MIME->create(
                    attributes => {
                        filename     => $upload->filename,
                        name         => $upload->filename,
                        content_type => $upload->type,
                        encoding     => 'base64',
                    },
                    body => $upload->slurp,
                ));
            }
        }
        elsif ($field_type ne 'submit') {
            push(@input_names, $field_name);
        }
    }

    my @args;
    foreach my $input_name (@input_names) {
        my $input_value = $c->req->param($input_name) // '';
        next unless length $input_value;
        push(@args, [ $input_name => $input_value ]);
        $email_content .= $input_name.': '.$input_value."\n";    # FIXME use Data::Header::Fields
    }

    my $email = Email::MIME->create(
        header_str => [
            From    => $from,
            To      => $rcpt_to,
            Subject => $subject,
        ],
        parts => [
            Email::MIME->create(
                attributes => {
                    content_type => "text/plain",
                    charset      => "UTF-8",
                    encoding     => "8bit",
                },
                body_str => $email_content,
            ),
            @file_attachments,
        ],
    );

    if (Run::Env->prod) {
        sendmail($email->as_string);
    }
    else {
        warn $email->as_string;
    }

    $self->detach($detach);
}

no HTML::FormHandler::Moose;

1;
