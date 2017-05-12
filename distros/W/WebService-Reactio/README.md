[![Build Status](https://travis-ci.org/papix/WebService-Reactio.svg?branch=master)](https://travis-ci.org/papix/WebService-Reactio)
# NAME

WebService::Reactio - API client for Reactio

# SYNOPSIS

    use WebService::Reactio;

    my $client = WebService::Reactio->new(
        api_key      => '__API_KEY__',
        organization => '__ORGANIZATION__',
    );

    my $incidents = $client->incidents;

# DESCRIPTION

WebService::Reactio is API client for Reactio ([https://reactio.jp/](https://reactio.jp/)).

# METHODS

## new(%params)

Create instance of WebService::Reactio.

_%params_ must have following parameter:

- api\_key

    API key of Reactio.
    You can get API key on project setting page.

- organization

    Organization ID of Reactio.
    This is the same as the subdomain in your organization of Reactio.
    If you can use Reactio in the subdomain called [https://your-organization.reactio.jp/](https://your-organization.reactio.jp/), your Organization ID is `your-organization`.

_%params_ optional parameters are:

- domain

    Domain of Reactio.
    The default is `reactio.jp`.

## create\_incident($name, \[\\%options\])

Create new incident.

You must have following parameter:

- $name

    Incident name.

_%options_ is optional parameters.
Please refer API official guide if you want to get details.

## notify\_incident($incident\_id, $notification\_text, \[\\%options\])

Send notificate to specified incident.

You must have following parameter:

- $incident\_id

    Incident ID.

- $notification\_text

    Notification text.

_%options_ is optional parameters.
Please refer API official guide if you want to get details.

## incident($incident\_id)

Get incident details.

You must have following parameter:

- $incident\_id

    Incident ID.

## incidents(\[\\%options\])

Get incident list.

_%options_ is optional parameters.
Please refer API official guide if you want to get details.

## send\_message($incident\_id, $text)

Send message to specified incident's timeline.

You must have following parameter:

- $incident\_id

    Incident ID.

- $text

    Timeline message.

# LICENSE

Copyright (C) papix.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

Reactio API Official Guide [https://reactio.jp/development/api](https://reactio.jp/development/api)

# AUTHOR

papix <mail@papix.net>
