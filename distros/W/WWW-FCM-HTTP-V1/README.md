[![Build Status](https://travis-ci.com/omohayui/WWW-FCM-HTTP-V1.svg?branch=master)](https://travis-ci.com/omohayui/WWW-FCM-HTTP-V1)
# NAME

WWW::FCM::HTTP::V1 - Client for Firebase Cloud Messaging HTTP v1 API

# SYNOPSIS

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

# DESCRIPTION

WWW::FCM::HTTP::V1 is a Client for Firebase Cloud Messaging HTTP v1 API.

FCM HTTP v1 API authorizes requests with a short-lived OAuth 2.0 access token.

SEE ALSO [https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages).

# METHODS

## new(\\%args)

Create a FCM API Client.

## send(\\%content)

Request to FCM API.

# LICENSE

Copyright (C) omohayui.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

omohayui <omohayui@gmail.com>
