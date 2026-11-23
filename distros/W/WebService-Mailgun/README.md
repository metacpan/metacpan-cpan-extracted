[![Actions Status](https://github.com/kan/p5-web-service-mailgun/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/kan/p5-web-service-mailgun/actions?workflow=test)
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
}) or die $mailgun->error;
```

# DESCRIPTION

WebService::Mailgun is a client for the Mailgun API ([https://mailgun.com/](https://mailgun.com/)): sending messages
(also in MIME format), mailing lists and their members, events, stored messages and templates.

Each method sends one request, or a series of them for the methods that return every page of a
list, and returns the response decoded from JSON.

## Errors

When a request fails, the method returns `undef` (an empty list in list context), and
`error` and `error_status` tell why. With `RaiseError => 1`, it warns with the error
message and dies with the status line instead.

```perl
my $res = $mailgun->message($args)
    or die sprintf '%s: %s', $mailgun->error_status, $mailgun->error;
```

A response that is not what Mailgun sends fails the same way, even with a `2xx` status (then
in `error_status`): a body that is not a JSON object, a page without its list of items, a
`paging.next` that is not an https URL on the API's host, and one that points back to a page
already fetched. An empty body (`204 No Content`) is
a success with nothing in it.

The methods that return every page (["Lists of every page"](#lists-of-every-page)) do not return `undef`: they stop
at the page that failed and return the items fetched so far. Without `RaiseError`, a failure
there shows only in `error`, which keeps the message of the last failure until the next one.

### Rate limits

Mailgun answers `429 Too Many Requests` when the account sends too many requests. This module
does not try again by itself. The response
in `error_response` tells when to: `X-RateLimit-Reset` is the time (in milliseconds since the
epoch, UTC) the limit is reset.

```perl
my $res = $mailgun->message($args);
if (!$res && $mailgun->error_status =~ /^429/) {
    my $reset = $mailgun->error_response->header('X-RateLimit-Reset');
    my $wait  = $reset ? int($reset / 1000 - time) + 1 : 1;
    sleep $wait if $wait > 0;
    $res = $mailgun->message($args);
}
```

[Rate limits](https://documentation.mailgun.com/docs/mailgun/api-reference/api-overview)

## Lists of every page

`lists`, `list_members` and `event` follow `paging.next` until a page has no items, and
return two values: an array reference of all the items, and the `paging.next` URL of that
empty page as a [URI](https://metacpan.org/pod/URI), where the items that come later will be (for `event`, see
["Event Polling"](#event-polling)). When a request fails, the second value is the URL of the page that failed
instead; passed back to `event`, it fetches the rest of the events from there. A page with no
`paging.next` is the last one, and the second value is that page's own URL. The URL carries no
API key, so it can be kept or logged; `event` sets the key when it is passed back. Take the
items in list context:

```perl
my ($lists) = $mailgun->lists();
my ($events, $next) = $mailgun->event({ event => 'stored', ascending => 'yes' });
```

In scalar context they return the URL, not the items.

# METHODS

## `new(api_key => $api_key, domain => $domain, region => "us"|"eu"|"au", RaiseError => 0|1, timeout => $seconds)`

Create a WebService::Mailgun object.

### RaiseError (default: 0)

Die when a request fails, instead of returning `undef` (see ["Errors"](#errors)).

### region (default: "us")

The region the domain belongs to: `us`, `eu` or `au`. Any other value dies when a request
is made. The AU region (`api.au.mailgun.net`) is for Mailgun Send customers who asked for it.

### timeout (default: the one of [Furl](https://metacpan.org/pod/Furl), 10 seconds)

The seconds a request may take, given to [Furl](https://metacpan.org/pod/Furl). Raise it to send large attachments over a
slow connection. The HTTP client is made on the first request, so set it in `new`, or before
the first request.

## error

The error message of the last request that failed.

## error\_status

The status line (`401 Unauthorized`, say) of the last request that failed (see ["Errors"](#errors)).

## error\_response

The response (a [Furl::Response](https://metacpan.org/pod/Furl%3A%3AResponse)) of the last request that failed, for what `error` and
`error_status` leave out, such as its headers. See ["Rate limits"](#rate-limits). It does not keep the
request (whose URL carries the API key). For a response that is not what Mailgun sends (see
["Errors"](#errors)), it is that response, which can have a `2xx` status.

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

A decoded string (one with the UTF-8 flag, such as one from `decode_utf8` or a literal under
`use utf8`) is sent encoded in UTF-8. Any other string is sent as the bytes it holds.

To give a key several values, pass them in an array reference; the key is sent once for each:

```perl
my $res = $mailgun->message({
    from    => 'foo@example.com',
    to      => ['bar@example.com', 'baz@example.com'],
    'o:tag' => ['newsletter', 'weekly'],
    subject => 'test',
    text    => 'text',
});
```

An empty array reference dies, rather than leaving the key out.

`attachment` and `inline` are the exception: there an array reference is a file
(`[$path]`, or `[$path, $filename]`), as [HTTP::Request::Common](https://metacpan.org/pod/HTTP%3A%3ARequest%3A%3ACommon) takes it, and an array
reference of those is several files:

```perl
attachment => [ ['/path/to/a.pdf'], ['/path/to/b.pdf', 'b.pdf'] ],
```

The same can be passed as an array reference of key-value pairs instead of a hash reference,
with the key given once for each file:

```perl
my $res = $mailgun->message([
    from       => 'foo@example.com',
    to         => 'bar@example.com',
    subject    => 'test',
    text       => 'text',
    attachment => ['/path/to/a.pdf'],
    attachment => ['/path/to/b.pdf'],
]);
```

[Send an email](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/messages/post-v3--domain-name--messages)

## mime($args)

Send a MIME message you build yourself, usually by using a library to create that MIME message.
The `to` parameter needs to be passed as one of the arguments.
Either the `file` or `message` parameter will also need to be passed.

The `file` parameter should contain the path to the filename that holds the MIME message.
The `message` parameter should contain either a string or a reference to a string that holds the MIME message:

```perl
# send MIME message via a filename:
my $res = $mailgun->mime({
    to   => 'bar@example.com',
    file => '/path/to/filename.mime',
});

# send MIME message via a string:
use MIME::Entity;
my $str = MIME::Entity->build(
    From    => 'foo@example.com',
    To      => 'bar@example.com',
    Subject => 'Subject',
    Data    => 'Message',
)->as_string;

my $res = $mailgun->mime({
    to      => 'bar@example.com',
    message => $str,
});

# or send MIME message via a string ref:
my $res = $mailgun->mime({
    to      => 'bar@example.com',
    message => \$str,
});
```

The MIME message is bytes. A decoded string (one with the UTF-8 flag) is sent encoded in UTF-8,
as are the values of the other keys, here and in `message`. Give `message` or `file`, not
both.

The other keys are sent as they are, and like `message`, several values of a key can be given in
an array reference (`to => ['bar@example.com', 'baz@example.com']`). The hash reference
given is not changed, so the same one can be passed again.

[Send a message in MIME format](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/messages/post-v3--domain-name--messages-mime)

## lists($query)

Get list of mailing lists. `$query` is an optional hash reference of the query, such as
`limit`, the number of lists on a page (fewer requests for many lists).

```perl
# get mailing lists (every page; see "Lists of every page")
my ($lists) = $mailgun->lists();
# => ArrayRef of mailing list object.

my ($lists) = $mailgun->lists({ limit => 100 });
```

[Get mailing lists](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/mailing-lists/get-v3-lists-pages)

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

[Create a mailing list](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/mailing-lists/post-v3-lists)

## list($address)

Get detail for mailing list.

```perl
# get mailing list detail
my $data = $mailgun->list('ml@example.com');
```

[Get a mailing list](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/mailing-lists/get-v3-lists-address)

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

[Update a mailing list](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/mailing-lists/put-v3-lists-address)

## delete\_list($address)

Delete mailing list.

```perl
# delete mailing list
my $res = $mailgun->delete_list('ml@example.com');
```

[Delete a mailing list](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/mailing-lists/delete-v3-lists-address)

## list\_members($address, $query)

Get members for mailing list. `$query` is an optional hash reference of the query, such as
`subscribed` (`yes` or `no`) and `limit`.

```perl
# get members (every page; see "Lists of every page")
my ($members) = $mailgun->list_members('ml@example.com');

# only the members who unsubscribed
my ($members) = $mailgun->list_members('ml@example.com', { subscribed => 'no' });
```

[Get members of a mailing list](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/mailing-lists/get-lists-list_address-members-pages)

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

[Add a member to a mailing list](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/mailing-lists/post-lists-string:list_address-members)

## add\_list\_members($address, $args)

Adds multiple members for mailing list.

```perl
use JSON; # auto export 'encode_json'

# add members
my $res = $mailgun->add_list_members('ml@example.com' => {
    members => encode_json [
        { address => 'user1@example.com' },
        { address => 'user2@example.com' },
        { address => 'user3@example.com' },
    ],
    upsert  => 'no',            # no (default). if yes, update exists member
});

# or just the addresses
my $res = $mailgun->add_list_members('ml@example.com' => {
    members => encode_json [qw/user1@example.com user2@example.com/],
});
```

[Add members to a mailing list](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/mailing-lists/post-lists-list_address-members.json)

## list\_member($address, $member\_address)

Get member detail.

```perl
# get member
my $member = $mailgun->list_member('ml@example.com', 'user@example.com');
```

[Get a member of a mailing list](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/mailing-lists/get-lists-list_address-members-member_address)

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

[Update a member of a mailing list](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/mailing-lists/put-lists-list_address-members-member_address)

## delete\_list\_member($address, $member\_address)

Delete member for mailing list.

```perl
# delete member
my $res = $mailgun->delete_list_member('ml@example.com' => 'user@example.com');
```

[Delete a member of a mailing list](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/mailing-lists/delete-lists-list_address-members-member_address)

## event($args|$url)

Get event data. `$args` is a hash reference of the query. In its place `$url` (a [URI](https://metacpan.org/pod/URI) or a
string) is fetched as it is, such as the second value an earlier call returned (see
["Event Polling"](#event-polling)); it must be an https URL on the API's host, or `event` dies.

```perl
# get event data (every page; see "Lists of every page")
my ($events, $next) = $mailgun->event({ event => 'stored', limit => 50 });
```

[Get events](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/events/get-v3-domain_name-events)

## get\_message\_from\_event($event)

Get stored message. `$event` must be an event with `storage.url`, such as a `stored` event;
any other event dies. So does a `storage.url` that is not an https URL on `mailgun.net`, a
host under it, or the API's host, as the API key is sent there.

```perl
# get event data
my ($events) = $mailgun->event({ event => 'stored' });
my $msg = $mailgun->get_message_from_event($events->[0]);
```

[Retrieve a stored email](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/messages/get-v3-domains--domain-name--messages--storage-key-)

## add\_template($args)

Add a template. Like `message`, it takes a hash reference or an array reference of key-value
pairs. Unlike `message`, an array reference as a value is always a file (`[$path]`), as
[HTTP::Request::Common](https://metacpan.org/pod/HTTP%3A%3ARequest%3A%3ACommon) takes it, such as the template read from a file.

```perl
# add template
my $res = $mailgun->add_template({
    name        => 'welcome',     # Template name
    template    => 'Hello!',      # Template data
    engine      => 'handlebars',  # Template engine (optional)
    description => 'xyz',         # Description of template (optional)
    tag         => '2.0' ,        # Version tag (optional)
    comment     => 'Test',        # Version comment (optional)
});
```

[Create a template](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/post-v3--domain-name--templates)

## delete\_templates()

Delete all templates of the domain.

```perl
my $res = $mailgun->delete_templates();
```

[Delete all templates](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/delete-v3--domain-name--templates)

## delete\_template($name)

Delete a template.

```perl
my $res = $mailgun->delete_template($name);
```

[Delete a template](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/delete-v3--domain-name--templates--template-name-)

# Event Polling

The second value `event` returns is the `paging.next` URL of the empty page it stopped at, as a
[URI](https://metacpan.org/pod/URI) without the API key (keep it as a string between runs, if you like). Pass it back to
`event` in place of the query, and it sets the API key, returns the events stored since the
last call, and the URL to use the next time:

```perl
use Time::Piece;

my ($events, $next) = $mailgun->event({
    event     => 'stored',
    begin     => localtime->epoch - 30 * 60,
    ascending => 'yes',
});
while (1) {
    # do something with @$events ...
    sleep 60;
    ($events, $next) = $mailgun->event($next);
}
```

Use `ascending => 'yes'`, so that the URL points forward in time.

Mailgun may store an event some time after it happens. Such an event can be dated before events
already fetched, and the URL does not return it. If every event matters, fetch a time range
again once it is old enough (Mailgun's documentation suggests half an hour), and drop the events
whose `id` was seen already.

[Event Polling](https://documentation.mailgun.com/docs/mailgun/user-manual/events/event-polling)

# TODO

These APIs are not implemented yet.

- [Domains](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domains)
- [Stats](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/stats)
- [Tags](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/tags)
- Suppressions ([Bounces](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/bounces), [Unsubscribes](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/unsubscribe), [Complaints](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/complaints), [Allowlist](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/allowlist))
- [Routes](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/routes)
- [Webhooks](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/webhooks)
- [Email Validation](https://documentation.mailgun.com/docs/mailgun/api-reference/send/validate/validations)
- [Templates](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates) (only creating and deleting are implemented)

# SEE ALSO

- [Mailgun API reference](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/messages)
- [WWW::Mailgun](https://metacpan.org/pod/WWW%3A%3AMailgun), another client for the Mailgun API

# LICENSE

Copyright (C) Kan Fushihara.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kan Fushihara <kan.fushihara@gmail.com>
