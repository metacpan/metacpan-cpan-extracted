# DESCRIPTION

This module implements the REST API of Xential.

# SYNOPSIS

    my $xential = WebService::Xential->new(
      api_user => 'foo',
      api_key => 'foo',
      api_host => '127.0.0.1',
    );

    my $who   = $xential->whoami();
    my $other = $xential->impersonate(..., $who->{XSessionId});
    my $session_id = $other{XSessionID};

    my $ticket = $xential->create_ticket($xml, \%options, $session_id);
    my $start = $xential->start_document(
        $ticket->{startDocumentUrl},
        $ticket->{ticketUuid},
        $session_id
    );

    # Status is either INVALID or VALID

    if ($start->{status} eq 'VALID') {
        my $build = $xential->build_document(
            1,
            $start->{documentUuid},
            $session_id
        );

        if ($build->{status} eq 'done') {
            # build succeeded
        }
        else {
            # build failed
        }
    }
    else {
        use URI;
        $uri = URI->new($start{resumeUrl});
        $uri->scheme('https');
        $uri->query_form($uri->query_form, afterOpenAction => 'close');
        $uri->host($xential->api_host);
        # redirect user to $uri
    }

# ATTRIBUTES

## api\_host

The API host of the Xential WebService

## client

The [OpenAPI::Client](https://metacpan.org/pod/OpenAPI%3A%3AClient)

# METHODS

## new()

    my $xential = WebService::Xential->new(
      api_user => 'foo',
      api_key => 'foo',
      api_host => '127.0.0.1',
    );

## has\_api\_host()

Tells you if you have a custom API host defined

## whoami($session\_id)

Implements the whoami call from Xential

## logout($session\_id)

Implements the logout call from Xential

## impersonate($username, $user\_uuid, $session\_id)

Implements the impersonate call from Xential

## create\_ticket($xml, $options, $session\_id)

Implements the create\_ticket call from Xential

## start\_document($username, $user\_uuid, $session\_id)

Implements the start\_document call from Xential

## build\_document($username, $user\_uuid, $session\_id)

Implements the build\_document call from Xential

## api\_call($operation, $query, $content)

A wrapper around the [OpenAPI::Client::call](https://metacpan.org/pod/OpenAPI%3A%3AClient%3A%3Acall) function. Returns the JSON from
the endpoint.
