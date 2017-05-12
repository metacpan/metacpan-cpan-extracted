[![Build Status](https://travis-ci.org/xaicron/p5-WWW-Google-Cloud-Messaging.svg?branch=master)](https://travis-ci.org/xaicron/p5-WWW-Google-Cloud-Messaging)
# NAME

WWW::Google::Cloud::Messaging - Google Cloud Messaging (GCM) Client Library

# SYNOPSIS

    use WWW::Google::Cloud::Messaging;

    my $api_key = 'Your API Key';
    my $gcm = WWW::Google::Cloud::Messaging->new(api_key => $api_key);

    my $res = $gcm->send({
        registration_ids => [ $reg_id, ... ],
        collapse_key     => $collapse_key,
        data             => {
          message => 'blah blah blah',
        },
    });

    die $res->error unless $res->is_success;

    my $results = $res->results;
    while (my $result = $results->next) {
        my $reg_id = $result->target_reg_id;
        if ($result->is_success) {
            say sprintf 'message_id: %s, reg_id: %s',
                $result->message_id, $reg_id;
        }
        else {
            warn sprintf 'error: %s, reg_id: %s',
                $result->error, $reg_id;
        }

        if ($result->has_canonical_id) {
            say sprintf 'reg_id %s is old! refreshed reg_id is %s',
                $reg_id, $result->registration_id;
        }
    }

# DESCRIPTION

WWW::Google::Cloud::Messaging is a Google Cloud Messaging (GCM) client library,
which implements web application servers.

Currently this supports JSON API.

SEE ALSO [http://developer.android.com/guide/google/gcm/gcm.html#send-msg](http://developer.android.com/guide/google/gcm/gcm.html#send-msg).

# METHODS

## new(%args)

Create a WWW::Google::Cloud::Messaging instance.

    my $gcm = WWW::Google::Cloud::Messaging->new(api_key => $api_key);

Supported options are:

- api\_key : Str

    Required. Set your API key.

    For more information, please check [http://developer.android.com/guide/google/gcm/gs.html#access-key](http://developer.android.com/guide/google/gcm/gs.html#access-key).

- api\_url : Str

    Optional. Default values is `$WWW::Google::Cloud::Messaging::API_URL`.

- ua : LWP::UserAgent

    Optional. Set a custom LWP::UserAgent instance if needed.

## build\_request(\\%payload)

Returns HTTP::Request suitable for sending with arbitrary HTTP client avalaible
on CPAN. Response can than be decoded using `WWW::Google::Cloud::Messaging::Response`.

    my $res = $gcm->send({
        registration_ids => [ $reg_id ], # must be arrayref
        collapse_key     => '...',
        data             => {
            message   => 'xxxx',
            score     => 12345,
            is_update => JSON::true,
        },
    });

The possible options are as follows:

- registration\_ids : ArrayRef

    A string array with the list of devices (registration IDs) receiving the message. It must contain at least 1 and at most 1000 registration IDs. To send a multicast message, you must use JSON. For sending a single message to a single device, you could use a JSON object with just 1 registration id, or plain text (see below). Required.

- collapse\_key : Str

    An arbitrary string (such as "Updates Available") that is used to collapse a group of like messages when the device is offline, so that only the last message gets sent to the client. This is intended to avoid sending too many messages to the phone when it comes back online. Note that since there is no guarantee of the order in which messages get sent, the "last" message may not actually be the last message sent by the application server. See Advanced Topics for more discussion of this topic. Optional.

- data : Str

    A JSON-serializable object whose fields represents the key-value pairs of the message's payload data. Optional.

- delay\_while\_idle : Boolean

    If included, indicates that the message should not be sent immediately if the device is idle. The server will wait for the device to become active, and then only the last message for each collapse\_key value will be sent. Optional. The default value is false, and must be a JSON boolean.

- time\_to\_live : Int

    How long (in seconds) the message should be kept on GCM storage if the device is offline. Optional (default time-to-live is 4 weeks, and must be set as a JSON number).

- restricted\_package\_name : Str

    A string containing the package name of your application. When set, messages will only be sent to registration IDs that match the package name. Optional.

- dry\_run : Boolean

    If included, allows developers to test their request without actually sending a message. Optional. The default value is false, and must be a JSON boolean.

## send(\\%payload)

Build request using `build_request` and send message to GCM. Returns `WWW::Google::Cloud::Messaging::Response` instance.

The above is just a copy of the official GCM description and so could be old. You should check the latest information in [http://developer.android.com/guide/google/gcm/gcm.html#send-msg](http://developer.android.com/guide/google/gcm/gcm.html#send-msg).

# AUTHOR

xaicron <xaicron@cpan.org>

# COPYRIGHT

Copyright 2012 - xaicron

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[WWW::Google::Cloud::Messaging::Response](https://metacpan.org/pod/WWW::Google::Cloud::Messaging::Response)
