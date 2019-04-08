package WWW::FCM::HTTP::V1;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.02";

use Class::Accessor::Lite (
    new => 0,
    rw  => [qw/sender api_url/],
);
use JSON qw(encode_json);
use Carp qw(croak);

use WWW::FCM::HTTP::V1::OAuth;

our $SCOPE_FIREBASE_MESSAGING = "https://www.googleapis.com/auth/firebase.messaging";

sub new {
    my $class = shift;
    my %args  = $_[0] && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;
    croak 'Usage: WWW::FCM::HTTP::V1->new({ api_url => $api_url, api_key_json => $api_key_json })'
    unless (exists $args{api_url} && defined $args{api_url} && exists $args{api_key_json} && defined $args{api_key_json});

    $args{sender} ||= WWW::FCM::HTTP::V1::OAuth->new(
        api_key_json => $args{api_key_json},
        scopes       => [$SCOPE_FIREBASE_MESSAGING],
    );

    bless { %args }, $class;
}

sub send {
    my ($self, $content) = @_;
    croak 'Usage: $fcm->send(\%content)' unless ref $content eq 'HASH';

    $self->sender->request(
        method  => "POST",
        uri     => $self->api_url,
        content => encode_json($content),
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::FCM::HTTP::V1 - Client for Firebase Cloud Messaging HTTP v1 API

=head1 SYNOPSIS

    use WWW::FCM::HTTP::V1;

    # https://firebase.google.com/docs/cloud-messaging/auth-server
    my $api_key_json = '{ "type": "service_account"...'; # from service-account.json
    my $api_url      = 'https://fcm.googleapis.com/v1/projects/{ project_id }/messages:send'; # from Project ID

    my $fcm = WWW::FCM::HTTP::V1->new({
        api_url      => $api_url,
        api_key_json => $api_key_json,
     });

    # https://firebase.google.com/docs/cloud-messaging/send-message
    my $res = $fcm->send({
        message => {
            token        => "bk3RNwTe3H0:CI2k_HHwg...", # from Device registration token
            notification => {
                body  => "This is an FCM notification message!",
                title => "FCM Message",
            },
        },
    });

    # handle HTTP error
    unless ($res->is_success) {
        die $res->error;
    }

=head1 DESCRIPTION

WWW::FCM::HTTP::V1 is a Client for Firebase Cloud Messaging HTTP v1 API.

FCM HTTP v1 API authorizes requests with a short-lived OAuth 2.0 access token.

SEE ALSO L<< https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages >>.

=head1 METHODS

=head2 new(\%args)

Create a FCM API Client.

=head2 send(\%content)

Request to FCM API.

=head1 LICENSE

Copyright (C) omohayui.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

omohayui E<lt>omohayui@gmail.comE<gt>

=cut
