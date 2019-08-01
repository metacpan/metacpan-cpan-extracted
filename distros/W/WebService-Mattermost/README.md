# WebService::Mattermost

[![Build Status](https://drone.netsplit.uk/api/badges/mike/WebService-Mattermost/status.svg?branch=master)](https://drone.netsplit.uk/mike/WebService-Mattermost)

Suite for interacting with Mattermost chat servers. Includes API and WebSocket
gateways.

See individual POD files for details.

This library supercedes [Net::Mattermost::Bot](https://git.netsplit.uk/mike/Net-Mattermost-Bot)
and replaces all functionality.

## Installation

### From CPAN

```
% cpanm WebService::Mattermost
```

### Manual

```
% git clone ssh://git@git.netsplit.uk:7170/mike/WebService-Mattermost.git
% cd WebService-Mattermost
% dzil listdeps | cpanm
% dzil authordeps | cpanm
% dzil install
```

## API usage

Currently, only API version 4 (latest) is supported.

```perl
use WebService::Mattermost;

my $mattermost = WebService::Mattermost->new({
    authenticate => 1, # Log into Mattermost
    debug        => 1, # Output some debug-level information via Mojo::Log
    username     => 'email@address.com',
    password     => 'hunter2',
    base_url     => 'https://my.mattermost.server.com/api/v4/',
});

# API methods available under:
my $api = $mattermost->api;

```

## WebSocket gateway usage

Several events are emitted:

* `gw_ws_started` when the bot opens its WebSocket connection.
* `gw_ws_finished` when the connection closes.
* `gw_ws_error` if an error occurs.
* `gw_message` on a "message" event.
* Unless it has no event type attached to it, where `gw_message_no_event` is
  emitted (this is usually a "ping" response).

The WebSocket gateway can be extended in a Moo or Moose class:

```perl
package SomePackage;

use Moo;

extends 'WebService::Mattermost::V4::Client';

# WebService::Mattermost::WS::v4 emits events which can be caught with these
# methods. None of them are required and they all pass two arguments ($self,
# HashRef $args).
sub gw_ws_started {}

sub gw_ws_finished {}

sub gw_message {
    my $self = shift;
    my $args = shift;

    # The message's data is in $args
}

sub gw_ws_error {}

sub gw_message_no_event {}

1;
```

Or used in a script:

```perl
use WebService::Mattermost::V4::Client;

my $bot = WebService::Mattermost::V4::Client->new({
    username => 'usernamehere',
    password => 'password',
    base_url => 'https://mattermost.server.com/api/v4/',

    # Optional arguments
    debug       => 1, # Show extra connection information
    ignore_self => 0, # May cause recursion!
});

$bot->on(gw_message => sub {
    my ($bot, $args) = @_;

    # $args contains the decoded message content
});

$bot->start(); # Add me last
```

The available events are the same:

* `gw_message_no_event`
* `gw_message`
* `gw_ws_error`
* `gw_ws_finished`
* `gw_ws_started`

## License

MIT. See LICENSE.txt.