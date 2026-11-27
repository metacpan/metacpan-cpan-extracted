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

The lists of the templates and of the suppressions return every page in the same way, but their
second value is only good for taking up a failure where it stopped. The `paging.next` of their
empty page points back to the first page (the suppressions), or to the last one (the versions
of a template), not to the items that come later.

`all_logs` also returns every page, and the items fetched so far on a failure; its second
value is not a URL (see ["all\_logs($body)"](#all_logs-body)).

# METHODS

## `new(api_key => $api_key, domain => $domain, region => "us"|"eu"|"au", RaiseError => 0|1, timeout => $seconds)`

Create a WebService::Mailgun object.

### RaiseError (default: 0)

Die when a request fails, instead of returning `undef` (see ["Errors"](#errors)).

### region (default: "us")

The region the domain belongs to: `us`, `eu` or `au`. Any other value dies when a request
is made. The AU region (`api.au.mailgun.net`) is for Mailgun Send customers who asked for it.

Every version of the API (v3, and the v1 and v4 of some methods, such as `domains` and
`validate_address`) is called on the host of the region. Mailgun's documentation does not say
whether the AU region serves Email Validation.

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

Mailgun has deprecated the Events API in favor of the
[Logs API](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/logs/post-v1-analytics-logs)
(`logs`; see ["ANALYTICS"](#analytics)). No date has been announced for its removal, and `event` stays
while the Events API works.

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

## templates($query)

Get every template of the domain (every page; see ["Lists of every page"](#lists-of-every-page)). `$query` is an
optional hash reference of the query, such as `limit => 100` (the most Mailgun takes).

```perl
my ($templates) = $mailgun->templates();
```

[Get templates](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/get-v3--domain-name--templates)

## template($name, $query)

Get a template (the `template` of the response). With `{ active => 'yes' }`, it has the
active version in `version`.

```perl
my $template = $mailgun->template('welcome', { active => 'yes' });
```

[Get template](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/get-v3--domain-name--templates--template-name-)

## update\_template($name, $args)

Update the description of a template. Like `add_template`, it takes a hash reference or an
array reference of key-value pairs.

```perl
my $res = $mailgun->update_template(welcome => { description => 'The first mail' });
```

[Update template](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/put-v3--domain-name--templates--template-name-)

## rename\_template($name, $new\_name)

```perl
my $res = $mailgun->rename_template(welcome => 'welcome-v2');
```

[Rename a template](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/put-v3--domain-name--templates--template-name--rename--new-template-name-)

## copy\_template($name, $args)

Copy a template to other accounts. `$args` is the body Mailgun takes, sent as JSON:
`requests` (an array reference of `account_id`, `name` and `domain`) and `source_versions`
(the versions to copy; all of them when left out).

```perl
my $res = $mailgun->copy_template(welcome => {
    requests => [ { account_id => $account_id, name => 'welcome', domain => 'example.com' } ],
});
```

[Copy a template](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/put-v3--domain-name--templates--template-name--copy)

## template\_versions($name, $query)

Get every version of a template (every page; see ["Lists of every page"](#lists-of-every-page)). `$query` is an
optional hash reference of the query, such as `limit`.

```perl
my ($versions) = $mailgun->template_versions('welcome');
```

[Get all versions](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/get-v3--domain-name--templates--template-name--versions)

## template\_version($name, $tag)

Get a version of a template: the `template` of the response, with the version in `version`.

```perl
my $template = $mailgun->template_version(welcome => 'v1');
my $content  = $template->{version}{template};
```

[Get a version](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/get-v3--domain-name--templates--template-name--versions--version-name-)

## add\_template\_version($name, $args)

Add a version to a template. Like `add_template`, it takes a hash reference or an array
reference of key-value pairs, and an array reference as a value is a file.

```perl
my $res = $mailgun->add_template_version(welcome => {
    template => 'Hello, {{name}}!',
    tag      => 'v2',
    comment  => 'With the name',   # (optional)
    active   => 'yes',             # (optional)
});
```

[Create a new version](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/post-v3--domain-name--templates--template-name--versions)

## update\_template\_version($name, $tag, $args)

Update a version of a template. The fields left out stay as they are.

```perl
my $res = $mailgun->update_template_version(welcome => 'v2', { active => 'yes' });
```

[Update a version](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/put-v3--domain-name--templates--template-name--versions--version-name-)

## delete\_template\_version($name, $tag)

```perl
my $res = $mailgun->delete_template_version(welcome => 'v1');
```

[Delete a version](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/delete-v3--domain-name--templates--template-name--versions--version-name-)

## copy\_template\_version($name, $tag, $new\_tag, $query)

Copy a version of a template to a new version of it. `$query` is an optional hash reference,
such as `{ comment => '...' }`.

```perl
my $res = $mailgun->copy_template_version(welcome => 'v2', 'v3');
```

[Copy a version](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/put-v3--domain-name--templates--template-name--versions--version-name--copy--new-version-name-)

## domain\_webhooks()

Get the webhooks of the domain (the v3 API): a hash reference of the URLs for each type of
event, such as `{ clicked => { urls => [...] }, ... }`.

```perl
my $webhooks = $mailgun->domain_webhooks();
```

The types are `accepted`, `delivered`, `opened`, `clicked`, `unsubscribed`, `complained`,
`temporary_fail` and `permanent_fail`. A type takes up to 3 URLs.

[List all webhooks](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-webhooks/get-v3-domains--domain--webhooks)

## domain\_webhook($type)

Get the URLs of a type of event, such as `{ urls => [...] }`.

```perl
my $webhook = $mailgun->domain_webhook('clicked');
```

[Get webhook URLs by type](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-webhooks/get-v3-domains--domain-name--webhooks--webhook-name-)

## add\_domain\_webhook($type, $url|\\@urls)

Add the webhook of a type of event, with a URL or an array reference of URLs. A URL is a
string or an object that is one, such as a [URI](https://metacpan.org/pod/URI).

```perl
my $res = $mailgun->add_domain_webhook(clicked => 'https://example.com/clicked');
$res = $mailgun->add_domain_webhook(opened => ['https://example.com/a', 'https://example.com/b']);
```

[Create a webhook](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-webhooks/post-v3-domains--domain--webhooks)

## update\_domain\_webhook($type, $url|\\@urls)

Replace the URLs of a type of event.

```perl
my $res = $mailgun->update_domain_webhook(clicked => ['https://example.com/new']);
```

[Update a webhook](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-webhooks/put-v3-domains--domain-name--webhooks--webhook-name-)

## delete\_domain\_webhook($type)

Delete every URL of a type of event.

```perl
my $res = $mailgun->delete_domain_webhook('clicked');
```

[Delete a webhook](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-webhooks/delete-v3-domains--domain-name--webhooks--webhook-name-)

# SUPPRESSIONS

The bounces, unsubscribes, complaints and allowlist of the domain. Each kind has the same
methods: the list of every entry, an entry, adding, importing a CSV file, deleting an entry,
and deleting every entry. Bounces, unsubscribes and complaints also add up to 1000 entries in
one request.

The lists follow every page, as `lists` does (["Lists of every page"](#lists-of-every-page)), and take an optional
hash reference of the query, such as `limit` (up to 1000) and `term` (the start of the
addresses). The methods that add take the fields Mailgun's documentation lists for the kind,
such as `code` and `error` of a bounce, or `domain` in place of `address` on the allowlist.

## bounces($query)

```perl
my ($bounces) = $mailgun->bounces({ limit => 1000 });
```

[List bounces](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/bounces/get-v3--domainid--bounces)

## bounce($address)

```perl
my $bounce = $mailgun->bounce('user@example.com');
```

[Lookup a bounce](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/bounces/get-v3--domainid--bounces--address-)

## add\_bounce($args)

```perl
my $res = $mailgun->add_bounce({ address => 'user@example.com', code => 550, error => 'No such user' });
```

[Add bounces](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/bounces/post-v3--domainid--bounces)

## add\_bounces(\\@records)

Add up to 1000 bounces in one request, sent as JSON. Give the strings as characters (decoded),
not as bytes of UTF-8. `code` goes out as a JSON string, even when it is given as a number
(`550`): Mailgun answers `400 Invalid JSON` to a number there.

```perl
my $res = $mailgun->add_bounces([
    { address => 'a@example.com', code => '550', error => 'No such user' },
    { address => 'b@example.com' },
]);
```

[Add bounces](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/bounces/post-v3--domainid--bounces)

## import\_bounces($path)

Import a CSV file of bounces, up to 25MB. Mailgun takes the file in the background (`202
Accepted`), so the entries show up a moment later. The header row has to have every column,
even one left empty in the rows: `address,code,error,created_at`. Without one, Mailgun answers
`400 invalid header row`. The header rows of the other kinds are
`address,tags,created_at` (unsubscribes), `address,created_at` (complaints) and
`address,domain` (the allowlist).

```perl
# bounces.csv
address,code,error,created_at
user@example.com,550,No such user,

my $res = $mailgun->import_bounces('bounces.csv');
```

[Import a list of bounces](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/bounces/post-v3--domainid--bounces-import)

## delete\_bounce($address)

```perl
my $res = $mailgun->delete_bounce('user@example.com');
```

[Delete a single bounce](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/bounces/delete-v3--domainid--bounces--address-)

## delete\_bounces()

Delete every bounce of the domain.

```perl
my $res = $mailgun->delete_bounces();
```

[Delete all bounces](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/bounces/delete-v3--domainid--bounces)

## unsubscribes($query), unsubscribe($address), add\_unsubscribe($args), add\_unsubscribes(\\@records), import\_unsubscribes($path), delete\_unsubscribe($address, $tag), delete\_unsubscribes()

The same as the methods of bounces, for unsubscribes. An unsubscribe has the tags it applies to
(`*`, the default, for every message of the domain); see Mailgun's documentation for the field.
`delete_unsubscribe` takes an optional tag: with one, it removes only that tag of the
unsubscribe, and the others stay. A tag given as `undef` or `''` dies rather than deleting
every tag; leave the argument out for that.

```perl
my $res = $mailgun->add_unsubscribe({ address => 'user@example.com' });
$res = $mailgun->add_unsubscribe({ address => 'user@example.com', tag => 'news' });
$res = $mailgun->delete_unsubscribe('user@example.com', 'news');   # only 'news'
```

[Unsubscribe](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/unsubscribe)

## complaints($query), complaint($address), add\_complaint($args), add\_complaints(\\@records), import\_complaints($path), delete\_complaint($address), delete\_complaints()

The same as the methods of bounces, for complaints.

```perl
my $res = $mailgun->add_complaint({ address => 'user@example.com' });
```

[Complaints](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/complaints)

## allowlist\_entries($query), allowlist\_entry($value), add\_allowlist\_entry($args), import\_allowlist($path), delete\_allowlist\_entry($value), delete\_allowlist()

The same as the methods of bounces, for the allowlist, whose entries are addresses or domains
(`value`). There is no method to add many entries in one request: import a CSV file instead.

```perl
my $res = $mailgun->add_allowlist_entry({ address => 'user@example.com' });
$res = $mailgun->add_allowlist_entry({ domain => 'example.com' });
my $entry = $mailgun->allowlist_entry('example.com');
```

[Allowlist](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/allowlist)

# DOMAINS

The domains of the account, with the v4 API (and the v3 one to delete a domain, as Mailgun has
it).

## domains($query)

Get a page of the domains: the response, with `items` and `total_count`. Unlike `lists`, it
does not follow the pages: Mailgun gives the page with `skip` and `limit` (up to 1000), not
with `paging.next`. `$query` is an optional hash reference, such as `state`, `search` or
`sort`.

```perl
my $page = $mailgun->domains({ limit => 1000 });
my @names = map { $_->{name} } @{ $page->{items} };
my $next  = $mailgun->domains({ limit => 1000, skip => 1000 });
```

[Get domains](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domains/get-v4-domains)

## get\_domain($name)

Get a domain: the response, with `domain` and its DNS records (`sending_dns_records` and
`receiving_dns_records`). It is not `domain`, which is the domain given to `new`.

```perl
my $res = $mailgun->get_domain('example.com');
```

[Get domain](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domains/get-v4-domains--name-)

## add\_domain($args)

Add a domain. Like `add_template`, it takes a hash reference or an array reference of
key-value pairs. The response has no `smtp_login`: Mailgun leaves it out for a new domain.

```perl
my $res = $mailgun->add_domain({ name => 'mg.example.com', spam_action => 'tag' });
```

[Create a domain](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domains/post-v4-domains)

## update\_domain($name, $args)

```perl
my $res = $mailgun->update_domain('mg.example.com' => { spam_action => 'block' });
```

[Update a domain](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domains/put-v4-domains--name-)

## verify\_domain($name)

Ask Mailgun to check the DNS records of a domain again.

```perl
my $res = $mailgun->verify_domain('mg.example.com');
```

[Verify a domain](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domains/put-v4-domains--name--verify)

## delete\_domain($name)

```perl
my $res = $mailgun->delete_domain('mg.example.com');
```

[Delete a domain](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domains/delete-v3-domains--name-)

# EMAIL VALIDATION

## validate\_address($address, $query)

Validate an address (the v4 API). `$query` is an optional hash reference, such as
`{ provider_lookup => 'false' }`. The response has `result`, `risk`, `reason` and the
rest. Mailgun charges for each validation, and a free account gets `403 Forbidden`
("Email Validations are only available for paid accounts.").

```perl
my $res = $mailgun->validate_address('user@example.com');
print "$res->{result}\n";   # deliverable, undeliverable, ...
```

[Validate a single email address](https://documentation.mailgun.com/docs/mailgun/api-reference/send/validate/validations/get-v4-address-validate)

# ANALYTICS

The analytics of the account, with the v1 API: Logs in place of the deprecated Events API of
`event`, Metrics in place of the deprecated Stats API, and the new Tags in place of the
deprecated Tags API of v3. Each method takes the JSON body Mailgun documents, as a hash
reference, and returns the response: **one page**. Give the next page in the body, as below, or
use `all_logs` for every page of the logs.

## logs($body)

Get a page of the events of the account (every domain), sent as JSON. `start` and `end` are
dates of RFC 2822 (`Wed, 25 Nov 2026 10:00:00 +0000`), and `pagination` takes `limit` (up
to 100), `sort` and `token`. The next page is the token in `$res->{pagination}{next}`.

```perl
use Time::Piece;

# RFC 2822 in English, whatever the locale is (strftime's %a and %b follow it)
sub rfc2822 {
    my $t = gmtime(shift);
    sprintf '%s, %02d %s %d %s +0000', $t->day, $t->mday, $t->monname, $t->year, $t->hms;
}

my $body = {
    start      => rfc2822(time - 3600),
    end        => rfc2822(time),
    events     => ['delivered'],
    pagination => { sort => 'timestamp:asc', limit => 100 },
};
my $res = $mailgun->logs($body) or die $mailgun->error;
# the next page, while there is a token
if (my $next = $res->{pagination}{next}) {
    $body->{pagination}{token} = $next;
    $res = $mailgun->logs($body);
}
```

In place of ["Event Polling"](#event-polling), ask for the time since the last event kept, with `start`, and
drop the events whose `id` was seen already: Mailgun may store an event some time after it
happens.

Mailgun keeps the logs for a number of days that depends on the plan (one day on a free
account). A `start` before that fails with `400 Bad Request`, and `error` tells the time the
logs go back to.

[Query logs](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/logs/post-v1-analytics-logs)

## all\_logs($body)

Get every page of `logs`: it sends the token in `pagination.next` as
`pagination.token` of the next request, until a page has no `pagination.next` or no
items. It takes the body
of `logs` (it does not change it) and returns two values, as the ["Lists of every page"](#lists-of-every-page) do:
an array reference of the items of every page, and `undef`. Take them in list context: in
scalar context it returns the second value, not the items.

```perl
my ($items) = $mailgun->all_logs({
    start      => rfc2822(time - 3600),
    end        => rfc2822(time),
    events     => ['delivered'],
    pagination => { sort => 'timestamp:asc', limit => 100 },
});
```

On a failure it does not return `undef`: it returns the items fetched so far, and in place of
`undef` the `pagination` of the page that failed, a hash reference (with the token of that
page; without one when it is the first page). `error` and `error_status` tell why. Give it
back as the `pagination` of the body to fetch the rest from there. With `RaiseError`, it dies
instead, and the items fetched so far are lost.

A `pagination.next` that gives back a token already sent is a failure too, rather than a
loop. Its `pagination` has that token, so passing it back goes round the same pages again: ask
for the logs again with a narrower `start` and `end` instead.

```perl
my ($items, $rest) = $mailgun->all_logs($body);
if ($rest) {
    warn $mailgun->error;
    $body->{pagination} = $rest;
    my ($more) = $mailgun->all_logs($body);
}
```

## metrics($body)

Get a page of the metrics of the account, such as `processed_count` and `delivered_count`,
by `dimensions` and `resolution`. The pages go by `skip` and `limit` in `pagination`;
fewer items than `limit` is the last page.

```perl
my $res = $mailgun->metrics({
    duration   => '7d',
    resolution => 'day',
    dimensions => ['time'],
    metrics    => ['delivered_count', 'bounced_count'],
});
```

[Query metrics](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/metrics/post-v1-analytics-metrics)

## usage\_metrics($body)

The same as `metrics`, for the usage of the account, such as `email_validation_count`.

[Query usage metrics](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/metrics/post-v1-analytics-usage-metrics)

## tags($body)

Get a page of the tags of the account. `tag` is a tag or the start of tags, and
`pagination` takes `skip` and `limit` (up to 1000).

```perl
my $res = $mailgun->tags({ tag => 'news', pagination => { limit => 100 } });
```

[List tags](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/tags-new/post-v1-analytics-tags)

## update\_tag($tag, $description)

Set the description of a tag. The description is required: `''` clears it.

```perl
my $res = $mailgun->update_tag(newsletter => 'The weekly newsletter');
```

[Update a tag](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/tags-new/put-v1-analytics-tags)

## delete\_tag($tag)

```perl
my $res = $mailgun->delete_tag('newsletter');
```

[Delete a tag](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/tags-new/delete-v1-analytics-tags)

## tag\_limits()

The limit of the tags of the account, how many there are (`count`) and `limit_reached`.

```perl
my $res = $mailgun->tag_limits();
```

[Get tag limits](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/tags-new/get-v1-analytics-tags-limits)

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

- The rest of the [Domains](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domains) API, such as the settings under a domain (listing, adding, updating, verifying and deleting a domain are implemented)
- Following every page of `metrics`, `usage_metrics` and `tags` (each returns one page; `all_logs` follows the pages of `logs`)
- [Routes](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/routes)
- Webhooks: the v4 API of the [domain webhooks](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-webhooks) (the v3 one is implemented) and the [account webhooks](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/account-webhooks)
- [Email Validation](https://documentation.mailgun.com/docs/mailgun/api-reference/send/validate/validations) of many addresses (a single address is `validate_address`)
- [Templates of the account](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/account-templates) (the v4 API; the templates of the domain are implemented)

# SEE ALSO

- [Mailgun API reference](https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/messages)
- [WWW::Mailgun](https://metacpan.org/pod/WWW%3A%3AMailgun), another client for the Mailgun API

# LICENSE

Copyright (C) Kan Fushihara.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kan Fushihara <kan.fushihara@gmail.com>
