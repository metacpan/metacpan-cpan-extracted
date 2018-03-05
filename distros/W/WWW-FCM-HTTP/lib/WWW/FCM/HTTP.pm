package WWW::FCM::HTTP;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use LWP::UserAgent;
use LWP::Protocol::https;
use LWP::ConnCache;
use JSON qw(encode_json);
use Class::Accessor::Lite (
    new => 0,
    rw  => [qw/ua api_url api_key json/],
);
use Carp qw(croak);

use WWW::FCM::HTTP::Response;

our $API_URL = 'https://fcm.googleapis.com/fcm/send';

sub new {
    my $class = shift;
    my %args = ref @_ eq 'HASH' ? %{ @_ } : @_;
    croak 'Usage: WWW::FCM::HTTP->new(api_key => $api_key)' unless exists $args{api_key};

    $args{api_url} ||= $API_URL;
    $args{ua}      ||= LWP::UserAgent->new(
        agent      => __PACKAGE__.'/'.$VERSION,
        conn_cache => LWP::ConnCache->new,
    );

    bless { %args }, $class;
}

sub send {
    my ($self, $payload) = @_;
    croak 'Usage: $fcm->send(\%payload)' unless ref $payload eq 'HASH';

    my $res = $self->ua->request($self->build_request($payload));
    WWW::FCM::HTTP::Response->new($res, $payload->{registration_ids});
}

sub build_request {
    my ($self, $payload) = @_;
    croak 'Usage: $gcm->build_request(\%payload)' unless ref $payload eq 'HASH';

    my $req = HTTP::Request->new(POST => $self->api_url);
    $req->header(Authorization => 'key='.$self->api_key);
    $req->header('Content-Type' => 'application/json; charset=UTF-8');
    $req->content(encode_json $payload);

    return $req;
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::FCM::HTTP - HTTP Client for Firebase Cloud Messaging

=head1 SYNOPSIS

    use WWW::FCM::HTTP;

    my $api_key = 'Your API key'; # from google-services.json
    my $fcm     = WWW::FCM::HTTP->new({ api_key => $api_key });

    # send multicast request
    my $res = $fcm->send({
        registration_ids => [ $reg_id, ... ],
        data             => {
            message   => 'blah blah blah',
            other_key => 'foo bar baz',
        },
    });

    # handle HTTP error
    unless ($res->is_success) {
        die $res->error;
    }

    my $multicast_id  = $res->multicast_id;
    my $success       = $res->success;
    my $failure       = $res->failure;
    my $canonical_ids = $res->canonical_ids;
    my $results       = $res->results;
    while (my $result = $results->next) {
        my $sent_reg_id     = $result->sent_reg_id;
        my $message_id      = $result->message_id;
        my $registration_id = $result->registration_id;
        my $error           = $result->error;

        if ($result->is_success) {
            say sprintf 'message_id: %s, sent_reg_id: %s',
                $message_id, $sent_reg_id;
        }
        else {
            warn sprintf 'error: %s, sent_reg_id: %s',
                $error, $sent_reg_id;
        }

        if ($result->has_canonical_id) {
            say sprintf 'sent_reg_id: %s is old registration_id, you will update to %s',
                $sent_reg_id, $registration_id;
        }
    }

=head1 DESCRIPTION

WWW::FCM::HTTP is a HTTP Clinet for Firebase Cloud Messaging.

SEE ALSO L<< https://firebase.google.com/docs/cloud-messaging/http-server-ref >>.

=head1 METHODS

=head2 new(%args)

    my $fcm = WWW::FCM::HTTP->new({
        api_key => $api_key,
    });

=over

=item api_key : Str

Required. FCM API Key. See client.api_key in google-services.json.

=item api_url : Str

Optional. C<< https://fcm.googleapis.com/fcm/send >> by default.

=item ua : LWP::UserAgent

Optional. You can override custom LWP::UserAgent instance if needed.

=back

=head2 send(\%payload)

Send request to FCM. Returns C<< WWW::FCM::HTTP::Response >> instance.

    my $res = $fcm->send({
        to   => '/topics/all',
        data => {
            title => 'message title',
            body  => 'message body',
        },
    });

The possible parameters are see documents L<< https://firebase.google.com/docs/cloud-messaging/http-server-ref >>.

=head1 LICENSE

Copyright (C) xaicron.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

xaicron E<lt>xaicron@gmail.comE<gt>

=cut

