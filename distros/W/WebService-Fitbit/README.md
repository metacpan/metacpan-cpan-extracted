# NAME

WebService::Fitbit - Thin wrapper around the Fitbit OAuth API

# VERSION

version 0.000001

# SYNOPSIS

    use strict;
    use warnings;

    use WebService::Fitbit ();

    my $client = WebService::Fitbit->new(
        access_token  => 'secret-access-token',
        app_key       => 'my-app-id',
        app_secret    => 'my-app-secret',
        refresh_token => 'secret-refresh-token',
    );

    my $me = $client->get('/1/user/-/profile.json');

    # Dump HashRef of response
    use Data::Printer;
    p( $me->content );

# DESCRIPTION

beta beta beta.  Interface is subject to change.

This is a very thin wrapper around the Fitbit OAuth API.

# CONSTRUCTOR AND STARTUP

## new

- `access_token`

    A (once) valid OAuth access token.  It's ok if it has expired.

- `app_key`

    The key which Fitbit has assigned to your app.

- `app_secret`

    The secret which Fitbit has assigned to your app.

- `refresh_token`

    A valid `refresh_token` which the Fitbit API has provided.

- `ua`

    Optional.  A useragent of the [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) family.

- `base_uri`

    Optional.  Provide only if you want to route your requests somewhere other than
    the Fitbit OAuth endpoint.

## get

Accepts a relative URL path and an optional HashRef of params.  Returns a
[WebService::Fitbit::Response](https://metacpan.org/pod/WebService::Fitbit::Response) object.

    my $me = $client->get('/1/user/-/profile.json');

    my $activities = $client->get(
        '/1/user/-/activities/list.json',
        {
            beforeDate => '2015-07-15T23:45:47.000Z',
            limit      => 10,
            sort       => 'desc',
        }
    );

## delete

Accepts a relative URL path and an optional HashRef of params.  Returns a
[WebService::Fitbit::Response](https://metacpan.org/pod/WebService::Fitbit::Response) object.

    my $delete = $client->delete(
        '/1/user/-/activities/[activity-log-id].json'
    );

## post

Accepts a relative URL path and an optional HashRef of params.  Returns a
[WebService::Fitbit::Response](https://metacpan.org/pod/WebService::Fitbit::Response) object.

    my $post = $client->post(
        '/1/user/[user-id]/activities/goals/[period].json',
        { foo => 'bar', ... }
    );

## access\_token

Returns the current `access_token`.  This may not be the token which you
originally supplied.  If your supplied token has been expired, then this module
will try to get you a fresh `access_token`.

## access\_token\_expiration

Returns expiration time of access token in epoch seconds, if available.  Check
the predicate before calling this method in order to avoid a possible
exception.

    if ( $client->has_access_token_expiration ) {
        print $client->access_token_expiration;
    }

## has\_access\_token\_expiration

Predicate.  Returns true if `access_token_expiration` has been set.

## refresh\_access\_token

Tries to refresh the `access_token`.  Returns true on success and dies on
failure.  Use the `access_token` method to get the new token if this method
has returned `true`.

## ua

Returns the UserAgent which is being used to make requests.  Defaults to a
[WWW::Mechanize](https://metacpan.org/pod/WWW::Mechanize) object.

# AUTHOR

Olaf Alders <olaf@wundercounter.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
