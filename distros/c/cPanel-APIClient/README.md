# NAME

cPanel::APIClient - [cPanel](http://cpanel.com) APIs, à la TIMTOWTDI!

# SYNOPSIS

Create a [cPanel::APIClient::Service::cpanel](https://metacpan.org/pod/cPanel%3A%3AAPIClient%3A%3AService%3A%3Acpanel) object
to call cPanel APIs:

    my $cpanel = cPanel::APIClient->create(
        service => 'cpanel',
        transport => [ 'CLISync' ],
    );

    my $resp = $cpanel->call_uapi( 'Email', 'list_pops' );

    my $pops_ar = $resp->get_data();

Create a [cPanel::APIClient::Service::whm](https://metacpan.org/pod/cPanel%3A%3AAPIClient%3A%3AService%3A%3Awhm) object
to call WHM APIs:

    my $whm = cPanel::APIClient->create(
        service => 'whm',
        transport => [ 'CLISync' ],
    );

    my $resp = $whm->call_api1( 'listaccts' );

    my $accts_ar = $resp->get_data();

# DESCRIPTION

cPanel & WHM exposes a number of ways to access its APIs: different transport
mechanisms, different authentication schemes, etc. This library provides
client logic with sufficient abstractions to accommodate most supported
access mechanisms via a unified interface.

This library intends to supersede [cPanel::PublicAPI](https://metacpan.org/pod/cPanel%3A%3APublicAPI) as the preferred way
to access cPanel & WHM’s APIs from Perl. It can also serve as a model for
similar client libraries in other languages.

# FEATURES

- Fully object-oriented.
- Can use blocking or non-blocking I/O. Non-blocking I/O implementation
works with almost any modern Perl event loop interface.
- Uses minimal dependencies: no [Moose](https://metacpan.org/pod/Moose) &c.
- Extensively tested.
- Can run in pure Perl.

# CHARACTER ENCODING

cPanel & WHM’s API is character-set-agnostic. All text that you give to this
library should thus be encoded to binary, and all strings that you’ll receive
back will be binary.

This means that if you character-decode your inputs—as [perlunitut](https://metacpan.org/pod/perlunitut)
recommends—then you’ll need to encode your strings back to bytes before
giving them to this module.

Use of UTF-8 encoding is **strongly** recommended!

# FUNCTIONS

## $client = cPanel::APIClient->create( %OPTS )

A factory function that creates a “client” object that your code can
use to call the APIs.

%OPTS are:

- `service` - Required. The service that exposes the API(s) to call.
This controls the class of the returned object. Recognized values are:
    - `cpanel` - Function will return a [cPanel::APIClient::Service::cpanel](https://metacpan.org/pod/cPanel%3A%3AAPIClient%3A%3AService%3A%3Acpanel)
    instance.
    - `whm` - Function will return a [cPanel::APIClient::Service::whm](https://metacpan.org/pod/cPanel%3A%3AAPIClient%3A%3AService%3A%3Awhm)
    instance.
- `transport` - Required. An array reference that describes the
transport mechanism to use. The first member of this array names the mechanism;
remaining arguments are key-value pairs of attributes to give to the
mechanism class’s constructor.

    Currently supported mechanisms are:

    - [cPanel::APIClient::Transport::HTTPSync](https://metacpan.org/pod/cPanel%3A%3AAPIClient%3A%3ATransport%3A%3AHTTPSync) (`HTTPSync`) -
    Synchronous HTTP requests.
    - [cPanel::APIClient::Transport::CLISync](https://metacpan.org/pod/cPanel%3A%3AAPIClient%3A%3ATransport%3A%3ACLISync) (`CLISync`) -
    Synchronous local requests via cPanel & WHM’s command-line API tools.
    - [cPanel::APIClient::Transport::NetCurlPromiser](https://metacpan.org/pod/cPanel%3A%3AAPIClient%3A%3ATransport%3A%3ANetCurlPromiser) (`NetCurlPromiser`) -
    Asynchronous HTTP requests via
    [Net::Curl::Promiser](https://metacpan.org/pod/Net%3A%3ACurl%3A%3APromiser), which can use any event loop interface.
    As of this writing it supports [IO::Async](https://metacpan.org/pod/IO%3A%3AAsync), [AnyEvent](https://metacpan.org/pod/AnyEvent), and [Mojolicious](https://metacpan.org/pod/Mojolicious)
    out-of-the-box.
    - [cPanel::APIClient::Transport::MojoUserAgent](https://metacpan.org/pod/cPanel%3A%3AAPIClient%3A%3ATransport%3A%3AMojoUserAgent) (`MojoUserAgent`) -
    Asynchronous HTTP requests via [Mojo::UserAgent](https://metacpan.org/pod/Mojo%3A%3AUserAgent) (pure Perl).

    Which of the above to use will depend on your needs. If your application
    is local to the cPanel & WHM server you might find it easiest to use
    `CLISync`. For HTTP `NetCurlPromiser` offers the best flexibility
    and (probably) speed, whereas `MojoUserAgent` and `HTTPSync` can run in
    pure Perl (assuming you have [Net::SSLeay](https://metacpan.org/pod/Net%3A%3ASSLeay)).

    There currently is no documentation for how to create a 3rd-party transport
    mechanism (e.g., if you want to use a different HTTP library). Submissions
    via pull request will be evaluated on a case-by-case basis.

- `credentials` - Some transports require this; others don’t.
The recognized schemes are:
    - `username` & `api_token` - Authenticate with an API token
    - `username` & `password` - Authenticate with a password
    - `username`, `password`, & `tfa_token` - Authenticate with a
    password and two-factor authentication (2FA) token.
    - `username` only - Implicit authentication, only usable for local
    transports.

Depending on the `service` given, this function returns an instance of
either [cPanel::APIClient::Service::cpanel](https://metacpan.org/pod/cPanel%3A%3AAPIClient%3A%3AService%3A%3Acpanel) or
[cPanel::APIClient::Service::whm](https://metacpan.org/pod/cPanel%3A%3AAPIClient%3A%3AService%3A%3Awhm).

# LICENSE

Copyright 2020 cPanel, L. L. C. All rights reserved. [http://cpanel.net](http://cpanel.net)

This is free software; you can redistribute it and/or modify it under the
same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic).
