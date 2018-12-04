[![Build Status](https://travis-ci.org/xaicron/p5-WWW-FCM-HTTP.svg?branch=master)](https://travis-ci.org/xaicron/p5-WWW-FCM-HTTP)
# NAME

WWW::FCM::HTTP - HTTP Client for Firebase Cloud Messaging

# SYNOPSIS

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

# DESCRIPTION

WWW::FCM::HTTP is a HTTP Clinet for Firebase Cloud Messaging.

SEE ALSO [https://firebase.google.com/docs/cloud-messaging/http-server-ref](https://firebase.google.com/docs/cloud-messaging/http-server-ref).

# METHODS

## new(\\%args)

    my $fcm = WWW::FCM::HTTP->new({
        api_key => $api_key,
    });

- api\_key : Str

    Required. FCM API Key. See client.api\_key in google-services.json.

- api\_url : Str

    Optional. `https://fcm.googleapis.com/fcm/send` by default.

- ua : LWP::UserAgent

    Optional. You can override custom LWP::UserAgent instance if needed.

## send(\\%payload)

Send request to FCM. Returns `WWW::FCM::HTTP::Response` instance.

    my $res = $fcm->send({
        to   => '/topics/all',
        data => {
            title => 'message title',
            body  => 'message body',
        },
    });

The possible parameters are see documents [https://firebase.google.com/docs/cloud-messaging/http-server-ref](https://firebase.google.com/docs/cloud-messaging/http-server-ref).

# LICENSE

Copyright (C) xaicron.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

xaicron <xaicron@gmail.com>
