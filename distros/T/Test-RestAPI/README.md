# NAME

Test::RestAPI - Real mock of REST API

# SYNOPSIS

    my $api = Test::RestAPI->new(
        endpoints => [
            Test::RestAPI::Endpoint->new(
                path => '/a',
                method   => 'any',
            )
        ],
    );

    $api->start();

    HTTP::Tiny->new->get($api->uri.'/test');

# DESCRIPTION

In many (test) case you need mock some REST API. One way is mock your REST-API class abstraction or HTTP client.
This module provides other way - start generated [Mojolicious](https://metacpan.org/pod/Mojolicious) server and provides pseudo-real your defined API.

# METHODS

## new(%attribute)

### %attribute

#### endpoints

_ArrayRef_ of instances [Test::RestAPI::Endpoint](https://metacpan.org/pod/Test::RestAPI::Endpoint)

default is _/_ (root) 200 OK - hello:

    Test::RestAPI::Endpoint->new(
        path   => '/',
        method => 'any',
        render => {text => 'Hello'},
    );

#### mojo\_app\_generator

This attribute is used for generating mojo application.

default is [Test::RestAPI::MojoGenerator](https://metacpan.org/pod/Test::RestAPI::MojoGenerator)

### start

Start REST API ([Mojolicious](https://metacpan.org/pod/Mojolicious)) application on some random unused port
and wait to initialize.

For start new process is used `fork-exec` on non-windows machines and [Win32::Process](https://metacpan.org/pod/Win32::Process) for windows machines.

For generating [Mojolicious](https://metacpan.org/pod/Mojolicious) application is used [Test::RestAPI::MojoGenerator](https://metacpan.org/pod/Test::RestAPI::MojoGenerator) in `mojo_app_generator` attribute - is possible set own generator.

## count\_of\_requests($path)

return count of request to `$path` endpoint

## list\_of\_requests\_body($path)

return list (ArrayRef) of requests body to `$path` endpoint

# LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Jan Seidl <seidl@avast.com>
