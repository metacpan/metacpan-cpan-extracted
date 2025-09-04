[![Actions Status](https://github.com/scotticles/perl-zabbix7-api/actions/workflows/test.yml/badge.svg)](https://github.com/scotticles/perl-zabbix7-api/actions)
# NAME

Zabbix7::API -- Access the JSON-RPC API of a Zabbix server

# SYNOPSIS

    use Zabbix7::API;

    my $zabbix = Zabbix7::API->new(server => 'https://example.com/zabbix/api_jsonrpc.php');

    eval { $zabbix->login(user => 'calvin',
                          password => 'hobbes') };

    if ($@) { die 'could not authenticate' };

    my $items = $zabbix->fetch('Item', params => { search => { ... } });

# DESCRIPTION

This module is a Moo wrapper around the Zabbix 7.x JSON-RPC API.

For the Zabbix 1.8.x series, see [Zabbix::API](https://metacpan.org/pod/Zabbix%3A%3AAPI).
For the Zabbix < 6.0 series, see [Zabbix2::API](https://metacpan.org/pod/Zabbix2%3A%3AAPI).

What you need to start hacking is probably the `fetch` method in
`Zabbix7::API`; be sure to check out also what the various
`Zabbix7::API::Foo` classes do, as this is how you'll be manipulating
the objects you have just fetched.

Not all the tests have been tested for version 7, my focus on this library is making the hosts work for pulling information. I do not use the api to create objects or alter.

# ATTRIBUTES

## pull\_after\_push\_mode

(read-write boolean, defaults to a true value)

This attribute controls whether updating operations (calling `create`
or `update` on Zabbix objects) are immediately followed by an
automatic `pull` on the object, to retrieve server-generated values
such as IDs.  Disabling this behavior causes write operations to
become faster, which is handy for a pure-provisioning workflow.

## server

(read-only required string)

This must be set to the API endpoint of the Zabbix server.  This is
usually an HTTP URL of the form

    https://example.com/zabbix/api_jsonrpc.php

All API requests will be made to this URL.

## ua

(read-only [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) instance)

All HTTP requests will be performed by this object.  By default, it is
a vanilla [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) instance with all attributes at their
default value except for the User-Agent string, which is set to
"Zabbix API client (libwww-perl)".

## user

(read-only string, cannot be initialized in the constructor)

This attribute is set to the current user's username after a
successful login, and unset after a successful logout.

# METHODS

## api\_version

    my $version = $zabbix->api_version;

Query the Zabbix server for the API version number and return it.

## fetch

    my $things_aref = $zabbix->fetch('SomeClass', params => { ... });

This method fetches objects from the server.  The `params` hashref
should contain API method parameters that identify the objects you're
trying to fetch, for instance:

    $zabbix->fetch('Item', params => {
        search => { key_ => 'system.uptime' } });

The default value of `params` is an empty hashref, which **should**
mean "fetch every object of type CLASS".  See the Zabbix server API
documentation
[here](https://www.zabbix.com/documentation/2.2/manual/api/reference).

The method delegates a lot of work to the CLASS so that it can be as
generic as possible.  Any CLASS name in the `Zabbix7::API` namespace
is usable as long as it descends from `Zabbix7::API::CRUDE` (to be
precise, it should implement a number of methods, some of which
`CRUDE` implements, some of which are provided by specialized
subclasses provided in the distribution).  The string
`Zabbix7::API::` will be prepended if it is missing.

Returns an arrayref of CLASS instances.

Note that if you pass it parameters that change the return type, such
as "countOutput", `fetch` will be hopelessly confused, as it expects
the return value to be an array of object property maps.

## fetch\_single

    my $thing = $zabbix->fetch_single('SomeClass', params => { ... });

Like `fetch`, but also checks how many objects the server sent back.
If no objects were sent, returns `undef`.  If one object was sent,
returns that.  If more objects were sent, throws an exception.  This
helps against malformed queries; Zabbix tends to return **all** objects
of a class when a query contains strange parameters (like "searhc" or
"fliter").

## login

    $zabbix->login(user => 'me', password => 'mypassword');

Send login information to the Zabbix server and set the auth cookie if
the authentication was successful.

## logout

    $zabbix->logout;

Terminate the current session.

## query

    my $results = $zabbix->query(method => 'item.isreadable',
                                 params => { ... });

This method encodes the parameters provided, sends an API request,
waits for the server response and decodes it.  It will throw an
exception if the server sends back an API error message or an HTTP
error.

## useragent

    my $ua = $zabbix->useragent;

Alternative spelling of the `ua` accessor.

# TIPS AND TRICKS

## SSL SUPPORT

[LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) supports SSL if you install [LWP::Protocol::https](https://metacpan.org/pod/LWP%3A%3AProtocol%3A%3Ahttps).
You may need to configure [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) manually, e.g.

    my $zabbix = Zabbix7::API->new(
        ua => LWP::UserAgent->new(
            ssl_opts => { verify_hostname => 0,
                          SSL_verify_mode => 'SSL_VERIFY_NONE' }));

## LOGGING

[Zabbix7::API](https://metacpan.org/pod/Zabbix7%3A%3AAPI) uses [Log::Any](https://metacpan.org/pod/Log%3A%3AAny) to log outgoing requests and incoming
responses.

# BUGS AND MISSING FEATURES

The `user.logout` method has been broken ever since the first Zabbix
version that included an API.  It may have been fixed since.

Wrapping an API class requires a small but nonzero quantity of tuits
which I do not have.  Thus not all API classes are wrapped.  Patches
are welcome.

# CHANGES FROM Zabbix::API

## THE verbosity ATTRIBUTE

This attribute has been removed in favor of [Log::Any](https://metacpan.org/pod/Log%3A%3AAny)-based logging.
See also the documentation of [Log::Any::Adapter](https://metacpan.org/pod/Log%3A%3AAny%3A%3AAdapter).

## THE cache ATTRIBUTE

This feature was never very useful.  It has been removed to make the
code simpler and (hopefully) less bug-prone.

## USAGE OF Moo

[Zabbix::API](https://metacpan.org/pod/Zabbix%3A%3AAPI) used plain Perl objects, mostly due to constraints that
existed on the system for which it was originally written.  This
version uses [Moo](https://metacpan.org/pod/Moo), which removes a lot of boilerplate and makes the
code clearer.

## THE \_readonly\_properties METHOD

Zabbix 1.8.x used to silently ignore read-only properties sent as part
of an update or create operation.  However, Zabbix 2.x returns an
error if they are provided, even if they have not been changed from
the value stored on the server.  This means that most subclasses of
[Zabbix7::API::CRUDE](https://metacpan.org/pod/Zabbix7%3A%3AAPI%3A%3ACRUDE) need to implement this method to filter out the
list of properties that must be removed before calling `update` or
`create`.

## push VS create/update/exists

In [Zabbix::API](https://metacpan.org/pod/Zabbix%3A%3AAPI), you could call `$thing->push;` and it would
magically do things depending on if it thought the thing already
existed on the server.  This was well-suited to our initial usage, but
it proved problematic to maintain and hard to adapt to other
workflows.

[Zabbix7::API](https://metacpan.org/pod/Zabbix7%3A%3AAPI) has replaced the `push` method with explicit
`create`, `update` and `exists` methods.

# CONTRIBUTING

If you wish to contribute to this project, e.g. by writing a class
wrapper or fixing bugs etc., I would appreciate if you wrote the
attendant unit tests.

All unit tests in `t/` are run against a live Zabbix instance,
canonically the one provided by [this Docker
service](https://index.docker.io/u/berngp/docker-zabbix/).

# SEE ALSO

The Zabbix API documentation, at [https://www.zabbix.com/documentation/current/en/manual/api](https://www.zabbix.com/documentation/current/en/manual/api)

[LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent)

# AUTHOR

SCOTTH

# COPYRIGHT AND LICENSE

Copyright (C) 2011, 2012, 2013, 2014 SFR
Copyright (C) 2020 Fabrice Gabolde
Copyright (C) 2025 ScottH

This library is free software; you can redistribute it and/or modify
it under the terms of the GPLv3.
