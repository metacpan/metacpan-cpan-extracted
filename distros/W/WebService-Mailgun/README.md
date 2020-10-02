[![Build Status](https://travis-ci.org/kan/p5-web-service-mailgun.svg?branch=master)](https://travis-ci.org/kan/p5-web-service-mailgun) [![Coverage Status](https://img.shields.io/coveralls/kan/p5-web-service-mailgun/master.svg?style=flat)](https://coveralls.io/r/kan/p5-web-service-mailgun?branch=master)
# NAME

WebService::Mailgun - API client for Mailgun ([https://mailgun.com/](https://mailgun.com/))

# SYNOPSIS

```perl
use WebService::Mailgun;

my $mailgun = WebService::Mailgun->new(
    api_key => '<YOUR_API_KEY>',
    domain => '<YOUR_MAIL_DOMAIN>',
);

# send mail
my $res = $mailgun->message({
    from    => 'foo@example.com',
    to      => 'bar@example.com',
    subject => 'test',
    text    => 'text',
});
```

# DESCRIPTION

WebService::Mailgun is API client for Mailgun ([https://mailgun.com/](https://mailgun.com/)).

# METHOD

## new(api\_key => $api\_key, domain => $domain, RaiseError => 0|1)

Create mailgun object.

### RaiseError (default: 0)

The RaiseError attribute can be used to force errors to raise exceptions rather than simply return error codes in the normal way. It is "off" by default.

## error

return recent error message.

## error\_status

return recent API result status\_line.

## message($args)

Send email message.

```perl
# send mail
my $res = $mailgun->message({
    from    => 'foo@example.com',
    to      => 'bar@example.com',
    subject => 'test',
    text    => 'text',
});
```

[https://documentation.mailgun.com/en/latest/api-sending.html#sending](https://documentation.mailgun.com/en/latest/api-sending.html#sending)

## lists()

Get list of mailing lists.

```perl
# get mailing lists
my $lists = $mailgun->lists();
# => ArrayRef of mailing list object.
```

[https://documentation.mailgun.com/en/latest/api-mailinglists.html#mailing-lists](https://documentation.mailgun.com/en/latest/api-mailinglists.html#mailing-lists)

## add\_list($args)

Add mailing list.

```perl
# add mailing list
my $res = $mailgun->add_list({
    address => 'ml@example.com', # Mailing list address
    name    => 'ml sample',      # Mailing list name (Optional)
    description => 'sample',     # description (Optional)
    access_level => 'members',   # readonly(default), members, everyone
});
```

[https://documentation.mailgun.com/en/latest/api-mailinglists.html#mailing-lists](https://documentation.mailgun.com/en/latest/api-mailinglists.html#mailing-lists)

## list($address)

Get detail for mailing list.

```perl
# get mailing list detail
my $data = $mailgun->list('ml@exmaple.com');
```

[https://documentation.mailgun.com/en/latest/api-mailinglists.html#mailing-lists](https://documentation.mailgun.com/en/latest/api-mailinglists.html#mailing-lists)

## update\_list($address, $args)

Update mailing list detail.

```perl
# update mailing list
my $res = $mailgun->update_list('ml@example.com' => {
    address => 'ml@example.com', # Mailing list address (Optional)
    name    => 'ml sample',      # Mailing list name (Optional)
    description => 'sample',     # description (Optional)
    access_level => 'members',   # readonly(default), members, everyone
});
```

[https://documentation.mailgun.com/en/latest/api-mailinglists.html#mailing-lists](https://documentation.mailgun.com/en/latest/api-mailinglists.html#mailing-lists)

## delete\_list($address)

Delete mailing list.

```perl
# delete mailing list
my $res = $mailgun->delete_list('ml@example.com');
```

[https://documentation.mailgun.com/en/latest/api-mailinglists.html#mailing-lists](https://documentation.mailgun.com/en/latest/api-mailinglists.html#mailing-lists)

## list\_members($address)

Get members for mailing list.

```perl
# get members
my $res = $mailgun->list_members('ml@example.com');
```

[https://documentation.mailgun.com/en/latest/api-mailinglists.html#mailing-lists](https://documentation.mailgun.com/en/latest/api-mailinglists.html#mailing-lists)

## add\_list\_member($address, $args)

Add member for mailing list.

```perl
# add member
my $res = $mailgun->add_list_member('ml@example.com' => {
    address => 'user@example.com', # member address
    name    => 'username',         # member name (Optional)
    vars    => '{"age": 34}',      # member params(JSON string) (Optional)
    subscribed => 'yes',           # yes(default) or no
    upsert     => 'no',            # no (default). if yes, update exists member
});
```

[https://documentation.mailgun.com/en/latest/api-mailinglists.html#mailing-lists](https://documentation.mailgun.com/en/latest/api-mailinglists.html#mailing-lists)

## add\_list\_members($address, $args)

Adds multiple members for mailing list.

```perl
use JSON::XS; # auto export 'encode_json'

# add members
my $res = $mailgun->add_list_members('ml@example.com' => {
    members => encode_json [
        { address => 'user1@example.com' },
        { address => 'user2@example.com' },
        { address => 'user3@example.com' },
    ],
    upsert  => 'no',            # no (default). if yes, update exists member
});

# too simple
my $res = $mailgun->add_list_members('ml@example.com' => {
    members => encode_json [qw/user1@example.com user2@example.com/],
});
```

[https://documentation.mailgun.com/en/latest/api-mailinglists.html#mailing-lists](https://documentation.mailgun.com/en/latest/api-mailinglists.html#mailing-lists)

## list\_member($address, $member\_address)

Get member detail.

```perl
# update member
my $res = $mailgun->list_member('ml@example.com', 'user@example.com');
```

[https://documentation.mailgun.com/en/latest/api-mailinglists.html#mailing-lists](https://documentation.mailgun.com/en/latest/api-mailinglists.html#mailing-lists)

## update\_list\_member($address, $member\_address, $args)

Update member detail.

```perl
# update member
my $res = $mailgun->update_list_member('ml@example.com', 'user@example.com' => {
    address => 'user@example.com', # member address (Optional)
    name    => 'username',         # member name (Optional)
    vars    => '{"age": 34}',      # member params(JSON string) (Optional)
    subscribed => 'yes',           # yes(default) or no
});
```

[https://documentation.mailgun.com/en/latest/api-mailinglists.html#mailing-lists](https://documentation.mailgun.com/en/latest/api-mailinglists.html#mailing-lists)

## delete\_list\_members($address, $member\_address)

Delete member for mailing list.

```perl
# delete member
my $res = $mailgun->delete_list_member('ml@example.com' => 'user@example.com');
```

[https://documentation.mailgun.com/en/latest/api-mailinglists.html#mailing-lists](https://documentation.mailgun.com/en/latest/api-mailinglists.html#mailing-lists)

## event($args)

Get event data.

```perl
# get event data
my ($events, $purl) = $mailgun->event({ event => 'stored', limit => 50 });
```

[Events](https://documentation.mailgun.com/en/latest/api-events.html)

## get\_message\_from\_event($event)

Get stored message.

```perl
# get event data
my ($events, $purl) = $mailgun->event({ event => 'stored' });
my $msg = $mailgun->get_message_from_event($events->[0]);
```

[Stored Message](https://documentation.mailgun.com/en/latest/api-sending.html#retrieving-stored-messages)

# Event Pooling

event method return previous url. it can use for fetch event.

```perl
# event Pooling
my ($events, $purl) = $mailgun->event({ event => 'stored', begin => localtime->epoch() });
// do something ...
$events = $mailgun->event($purl);
// ...
```

[Event Polling](https://documentation.mailgun.com/en/latest/api-events.html#event-polling)    

# TODO

this API not implement yet.

- [Domains](https://documentation.mailgun.com/en/latest/api-domains.html)
- [Stats](https://documentation.mailgun.com/en/latest/api-stats.html)
- [Tags](https://documentation.mailgun.com/en/latest/api-tags.html)
- [Suppressions](https://documentation.mailgun.com/en/latest/api-suppressions.html)
- [Routes](https://documentation.mailgun.com/en/latest/api-routes.html)
- [Webhooks](https://documentation.mailgun.com/en/latest/api-webhooks.html)
- [Email Validation](https://documentation.mailgun.com/en/latest/api-email-validation.html)

# SEE ALSO

[WWW::Mailgun](https://metacpan.org/pod/WWW%3A%3AMailgun), [https://documentation.mailgun.com/en/latest/](https://documentation.mailgun.com/en/latest/)

# LICENSE

Copyright (C) Kan Fushihara.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kan Fushihara <kan.fushihara@gmail.com>
