[![Actions Status](https://github.com/mihyaeru21/p5-WebService-Slack-WebApi/workflows/test/badge.svg)](https://github.com/mihyaeru21/p5-WebService-Slack-WebApi/actions) [![Coverage Status](https://img.shields.io/coveralls/mihyaeru21/p5-WebService-Slack-WebApi/master.svg?style=flat)](https://coveralls.io/r/mihyaeru21/p5-WebService-Slack-WebApi?branch=master)
# NAME

WebService::Slack::WebApi - a simple wrapper for Slack Web API

# SYNOPSIS

    use WebService::Slack::WebApi;

    # By default we use the HTTP client library Furl but you can also use any other
    # Eg. LWP::UserAgent
    my $slack = WebService::Slack::WebApi->new( ua => LWP::UserAgent->new() );

    # the token is required unless using $slack->oauth->access
    my $slack = WebService::Slack::WebApi->new(token => 'access token');

    # getting channel's descriptions
    my $channels = $slack->conversations->list;

    # posting message to specified channel and getting message description
    my $posted_message = $slack->chat->post_message(
        channel  => 'channel id', # required
        text     => 'hoge',       # required (not required if 'attachments' argument exists)
        username => 'fuga',       # optional
        # other optional parameters...
    );

# DESCRIPTION

WebService::Slack::WebApi is a simple wrapper for Slack Web API (https://api.slack.com/web).

# Options

You can set some options by giving `opt` parameter to `new` method.
All values of `opt` are given to `Furl#new`.

    WebService::Slack::WebApi->new(token => 'access token', opt => {});

## User Agent

By default WebService::Slack::WebApi uses the [Furl](https://metacpan.org/pod/Furl) HTTP client.
But if your software is already using some other client,
e.g. [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) or [HTTP::Tiny](https://metacpan.org/pod/HTTP%3A%3ATiny),
you can also use that. Under the hood WebService::Slack::WebApi uses
the HTTP client wrapper [HTTP::AnyUA](https://metacpan.org/pod/HTTP%3A%3AAnyUA).

Use parameter `ua` to specify the user agent which you have already
created.

    my $ua = LWP::UserAgent->new( timeout => 10 );
    my $slack = WebService::Slack::WebApi->new( ua => $ua );

If you use both parameters `ua` and `opt`, WebService::Slack::WebApi
will throw an exception. This combination is illegal.

## Proxy

`opt` can contain `env_proxy` as boolean value .
If `env_proxy` is true then proxy settings are loaded from `$ENV{HTTP_PROXY}` and `$ENV{NO_PROXY}` by calling `Furl#env_proxy` method.
See also https://metacpan.org/pod/Furl#furl-env\_proxy.

# METHODS

This module provides all methods declared in the API reference (https://api.slack.com/methods).

## Basis

`WebService::Slack::WebApi::Namespace::method_name` corresponds to `namespace.methodName` in Slack Web API.
For example `WebService::Slack::WebApi::Chat::post_message` corresponds to `chat.postMessage`.
You describe as below to call `Chat::post_message` method.

    my $result = $slack->chat->post_message;

## Return value

All methods return HashRef.
When you want to know what is contained in HashRef, see the API reference.

## The token parameter

The API reference shows `chat.update` method require 4 parameters: `token`, `ts`, `channel` and `text`.
When using this module `token` parameter is added implicitly except using `oauth.access` method.
So you pass the other 3 parameters to `Chat::update` method as shown below.

    my $result = $slack->chat->update(
        ts      => '1401383885.000061',  # as Str
        channel => 'channel id',
        text    => 'hoge',
    );

## Optional parameters

Some methods have optional parameters.
If a parameter is optional in the API reference, it is also optional in this module.

## Not primitive parameters

These parameters are not primitive:

- `files.upload.file`: string of path to local file
- `files.upload.channels`: ArrayRef of channel id string

# SEE ALSO

- https://api.slack.com/web
- https://api.slack.com/methods

# AUTHOR

Mihyaeru/mihyaeru21 <mihyaeru21@gmail.com>

# LICENSE

Copyright (C) Mihyaeru/mihyaeru21

Released under the MIT license.

See `LICENSE` file.
