[![Build Status](https://travis-ci.org/masasuzu/p5-WebService-Slack-IncomingWebHook.svg?branch=master)](https://travis-ci.org/masasuzu/p5-WebService-Slack-IncomingWebHook) [![Coverage Status](https://img.shields.io/coveralls/masasuzu/p5-WebService-Slack-IncomingWebHook/master.svg?style=flat)](https://coveralls.io/r/masasuzu/p5-WebService-Slack-IncomingWebHook?branch=master)
# NAME

WebService::Slack::IncomingWebHook - slack incoming webhook client

# SYNOPSIS

    # for perl program
    use WebService::Slack::IncomingWebHook;
    my $client = WebService::Slack::IncomingWebHook->new(
        webhook_url => 'http://xxxxxxxxxxxxxx',
    );
    $client->post(
        text       => 'yahoooooo!!',
    );

    # for cli
    % post-slack --webhook_url='https://xxxxxx' --text='yahooo'

# DESCRIPTION

WebService::Slack::IncomingWebHook is slack incoming webhooks client.
[Slack](https://slack.com/) is chat web service.
For cli, this distribution provides post-slack command.

# METHOD

- WebService::Slack::IncomingWebHook->new(%params)

        my $client = WebService::Slack::IncomingWebHook->new(
            webhook_url => 'http://xxxxxxxxxxxxxx', # required
            channel    => '#general',               # optional
            username   => 'masasuzu',               # optional
            icon_emoji => ':sushi:',                # optional
            icon_url   => 'http://xxxxx/xxx.jpeg',  # optional
        );

    Creates new object.

- $client->post(%params)

        $client->post(
            text       => 'yahoooooo!!',
            channel    => '#general',
            username   => 'masasuzu',
            icon_emoji => ':sushi:',
            icon_url   => 'http://xxxxx/xxx.jpeg',
        );

    Posts to slack incoming webhooks.
    _channel_, _username_, _icon\_emoji_ and _icon\_url_ parameters can override constructor's parameter.

    _text_, _pretext_, _color_, _fields_ and _attachments_ parameter are available.
    See also slack incoming webhook document.

# SCRIPT

    % post-slack --webhook_url='https://xxxxxx' --text='yahooo'

available options are ...

- --webhook\_url (required)
- --text (required)
- --channel (optional)
- --username (optional)
- --icon\_url (optional)
- --icon\_emoji (optional)

# SEE ALSO

[https://my.slack.com/services/new/incoming-webhook](https://my.slack.com/services/new/incoming-webhook)

# LICENSE

Copyright (C) SUZUKI Masashi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

SUZUKI Masashi <m15.suzuki.masashi@gmail.com>
