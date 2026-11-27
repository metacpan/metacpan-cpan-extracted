package WebService::Mailgun;


use 5.020;
use strict;
use warnings;

use Furl;
use JSON;
use URI;
use Try::Tiny;
use Carp;
use Scalar::Util qw(blessed reftype);
use overload ();
use HTTP::Request::Common;


our $VERSION = "1.2.0";
our $API_BASE = 'api.mailgun.net/v3';
our $API_BASE_EU = 'api.eu.mailgun.net/v3';
our $API_BASE_AU = 'api.au.mailgun.net/v3';

use Class::Accessor::Lite (
    new => 1,
    rw  => [qw(api_key domain RaiseError region timeout)],
    ro  => [qw(error error_status error_response)],
);

# The body of a response as a hash reference, or undef when it is not a JSON object.
sub _json_object {
    my ($res) = @_;

    my $json = try { decode_json $res->content };
    return ref $json eq 'HASH' ? $json : undef;
}

sub decode_response {
    my ($self, $res) = @_;

    # Every endpoint answers with a JSON object. A success that is not one (a page from a proxy,
    # say) is a failure too, so that RaiseError decides whether it dies, as for any other (#35).
    # An empty body (204 No Content) is a success with nothing in it. The body goes into the
    # message cut short: a proxy's HTML page would otherwise fill the logs.
    if ($res->is_success) {
        my $content = $res->content // '';
        return {} if $content eq '';
        my $json = _json_object($res);
        return $json if $json;
        my $start = length $content > 200 ? substr($content, 0, 200) . '...' : $content;
        return $self->_fail("the response is not a JSON object: $start", $res);
    }

    my $json = _json_object($res);
    my $message = $json && defined $json->{message} && !ref $json->{message}
        ? $json->{message} : $res->content;
    return $self->_fail($message, $res);
}

# Records a failure in error and error_status, and dies with RaiseError. Without it, returns
# nothing, like the methods do on a failure.
sub _fail {
    my ($self, $message, $res) = @_;

    $self->{error} = $message;
    $self->{error_status} = $res->status_line;
    # The response itself, for what error and error_status leave out: the headers of a 429, say,
    # which tell when to try again (#43).
    $self->{error_response} = _without_request($res);
    if ($self->RaiseError) {
        carp $self->error;
        croak $self->error_status;
    }
    return;
}

# A copy of a Furl::Response without the request it keeps (request_src, and captured_req_* when
# Furl captured them): the URL of the request carries the API key, and its body every attachment.
# error_response would otherwise hold both until the next failure.
sub _without_request {
    my ($res) = @_;

    return $res unless blessed($res) && $res->isa('Furl::Response') && reftype($res) eq 'HASH';
    my $copy = bless { %$res }, ref $res;
    delete @{$copy}{qw(request_src captured_req_headers captured_req_content)};
    return $copy;
}

# The list of items of a page: the one under @keys ('items', or 'template', 'versions' for the
# versions of a template), or undef when there is none. With $null_items, a key that is there
# with null is an empty list: Mailgun's documentation has the templates' lists as "array or
# null". The other lists keep a null a failure (#35).
sub _items_of {
    my ($json, $null_items, @keys) = @_;

    my $items = $json;
    for my $k (@keys) {
        return unless ref $items eq 'HASH' && exists $items->{$k};
        $items = $items->{$k};
    }
    return [] if $null_items && !defined $items;
    return ref $items eq 'ARRAY' ? $items : undef;
}

sub recursive {
    my ($self, $method, $query, $key, $api_uri, $opt) = @_;

    $query //= {};
    my @keys = ref $key ? @$key : ($key // 'items');
    my @result;
    my $next;
    unless($api_uri) {
        $api_uri = URI->new($self->api_url($method));
        $api_uri->query_form($query);
    }

    # The URLs fetched so far, without the API key: a paging.next that points back to one of them
    # would go round for ever (#35).
    my %seen;
    my $last_res;
    while (1) {
        my $plain = $api_uri->clone;
        $plain->userinfo(undef);
        if ($seen{"$plain"}++) {
            # Not a URL fetched: the failure is told with the response that pointed back.
            $self->_fail("paging.next points back to $plain", $last_res);
            $next = $api_uri;
            last;
        }
        my $res = $self->client->get($api_uri->as_string);
        $last_res = $res;
        my $json = $self->decode_response($res);
        # A page without the list of items is a failure, like a request that failed (#35).
        my $items = $json && _items_of($json, $opt && $opt->{null_items}, @keys);
        if ($json && !$items) {
            $json = $self->_fail("the response has no '" . join('.', @keys) . "' list", $res);
        }
        unless ($json) {
            # The request failed: return the URL of the page that failed, so that the caller can
            # fetch the rest from there.
            $next = $api_uri;
            last;
        }
        push @result, @$items;
        my $page_next = ref $json->{paging} eq 'HASH' && $json->{paging}->{next};
        # The API key is set on paging.next to fetch it, so it has to be an https URL on the
        # API's host, as for event($url). Any other (a relative URL, say) is a failure.
        if ($page_next) {
            $page_next = $self->_api_host_url($page_next);
            unless ($page_next) {
                my ($host) = split m{/}, $self->api_base;
                $self->_fail("paging.next is not an https URL on $host", $res);
                $next = $api_uri;
                last;
            }
            # The query of the first page (`subscribed` of list_members, say) goes on every
            # page: a key that paging.next leaves out is put back, so that the later pages are
            # not fetched without it (#41). A key it has is left as Mailgun gave it.
            my %has = $page_next->query_form;
            my @missing = grep { !exists $has{$_} } sort keys %$query;
            $page_next->query_form($page_next->query_form, map { ($_ => $query->{$_}) } @missing)
                if @missing;
        }
        unless (@$items && $page_next) {
            # The end: an empty page, or one with no paging.next. paging.next of the empty page
            # is where the items that come later will be; for events this is how Event Polling
            # goes on (#25). paging.previous would point back over the last page and return it
            # again. A page with no paging.next gives its own URL instead, never undef: passed
            # back, `event(undef)` would fetch every event again.
            $next = $page_next || $api_uri;
            last;
        }
        $api_uri = $page_next;
        $api_uri->userinfo('api:'.$self->api_key);
    }

    # The URL goes back without the API key: a caller of Event Polling keeps it (in a database,
    # say) or logs it, and event($url) sets the key again before fetching it (#38).
    $next = $next->clone;
    $next->userinfo(undef);
    return \@result, $next;
}

# A copy of $url (a URI or a string) as a URI when it is an https URL on the API's host, or
# undef. Only such a URL gets the API key.
sub _api_host_url {
    my ($self, $url) = @_;

    my $uri = blessed($url) ? $url->clone : URI->new($url);
    my ($host) = split m{/}, $self->api_base;
    return unless _https_host($uri) eq lc($host);
    return $uri;
}

# The host of an https URI in lower case, or '' for any other URI. A host with anything but
# letters, digits, `.` and `-` is '' too: URI decodes `%2F` in the host while the request goes
# out with the string as it is, so `evil.example.com%2Fx.mailgun.net` would pass a check on the
# name it ends with (#42).
sub _https_host {
    my ($uri) = @_;

    return '' unless ($uri->scheme // '') eq 'https';
    my $host = lc($uri->host // '');
    return $host =~ /\A[a-z0-9.-]+\z/ ? $host : '';
}

sub client {
    my $self = shift;

    # The client is made on the first request, so timeout has to be set before it (#40).
    $self->{_client} //= Furl->new(
        agent => __PACKAGE__ . '/' . $VERSION,
        (defined $self->timeout ? (timeout => $self->timeout) : ()),
    );
}

sub api_base {
    my ($self) = @_;

    if ($self->region) {
        if (lc($self->region) eq "eu") {
            return $API_BASE_EU;
        } elsif (lc($self->region) eq "au") {
            return $API_BASE_AU;
        } elsif (lc($self->region) ne "us") {
            die "unsupported region '" . $self->region ."'";
        }
    }
    return $API_BASE;
}

# The base of the URLs for $version of the API ('v1', 'v4' ...; #47). Mailgun serves every version
# on the host of the region, so the version at the end of api_base ($API_BASE and the others,
# 'api.mailgun.net/v3') is replaced. Without $version, api_base as it is: the v3 API, or what a
# test or a user set $API_BASE to. A base that does not end in a version cannot give another one.
sub _api_base_of {
    my ($self, $version) = @_;

    my $base = $self->api_base;
    return $base unless defined $version;
    croak "unsupported API version '$version'" unless $version =~ /\Av[0-9]+\z/;
    $base =~ s{/v[0-9]+\z}{/$version}
        or croak "the API base '$base' does not end in a version, so it has no $version";
    return $base;
}

sub api_url {
    my ($self, $method, $version) = @_;

    sprintf 'https://api:%s@%s/%s',
        $self->api_key, $self->_api_base_of($version), $method;
}

sub domain_api_url {
    my ($self, $method) = @_;

    # Through api_url, so that the base of the URLs is made in one place.
    return $self->api_url(join '/', $self->domain, $method);
}

# The URL path from its segments, such as ('lists', $address, 'members'). Each segment (a list
# address, a member address, a template name) is percent-encoded on its own (#34). What a
# segment can hold as it is (the pchar of RFC 3986: `@`, `+` and the like) is left alone, so the
# addresses that worked before go out the same; `?`, `#`, `/`, `%` and the rest are encoded, so
# that they cannot end the path or add a segment.
#
# A decoded string (one with the UTF-8 flag) is sent as UTF-8. Any other string is taken as the
# bytes to send, as before, so that an address read without decoding is not encoded twice.
#
# An undefined or empty segment dies: `list(undef)` would otherwise ask for `lists`, every list.
sub _path {
    my @segments = @_;

    return join '/', map {
        croak 'an address or a name is required' unless defined $_ && length $_;
        my $segment = $_;
        utf8::encode($segment) if utf8::is_utf8($segment);
        $segment =~ s/([^A-Za-z0-9\-._~!\$&'()*+,;=:\@])/sprintf '%%%02X', ord $1/ge;
        $segment;
    } @segments;
}

# The form-data content of the key-value pairs given to $method (message, mime).
#
# `to => ['a@example.com', 'b@example.com']` sends `to` twice, as Mailgun takes a key given more
# than once. HTTP::Request::Common would take the array reference for a file, and die opening a
# file named after the first address (#36). Under the keys in @file_keys an array reference is
# still a file ([$path, $filename, ...]), and an array reference of those is several files.
sub _form_content {
    my ($method, $pairs, @file_keys) = @_;

    my %file_key = map { $_ => 1 } @file_keys;
    my @content;
    for (my $i = 0; $i < @$pairs; $i += 2) {
        my ($key, $value) = @$pairs[$i, $i + 1];
        if (ref $value ne 'ARRAY') {
            push @content, $key => _form_value($value);
            next;
        }
        # An empty list would leave the key out, and Mailgun would answer that it is missing.
        croak "$method(): '$key' is an empty array reference" unless @$value;
        if (!$file_key{$key}) {
            push @content, map { ($key => _form_value($_)) } @$value;
        } elsif (ref $value->[0] eq 'ARRAY') {
            push @content, map { ($key => $_) } @$value;
        } else {
            push @content, $key => $value;
        }
    }
    return \@content;
}

# A value of the form as bytes. A decoded string (one with the UTF-8 flag) is sent as UTF-8:
# HTTP::Request::Common takes only bytes, and dies on a character above 0xFF.
sub _form_value {
    my ($value) = @_;

    return $value if ref $value || !defined $value || !utf8::is_utf8($value);
    my $bytes = $value;
    utf8::encode($bytes);
    return $bytes;
}

sub message {
    my ($self, $args) = @_;

    my @pairs;
    if (ref($args) eq 'HASH') {
        @pairs = %$args;
    }
    elsif (ref($args) eq 'ARRAY') {
        @pairs = @$args;
    }
    else {
        die 'unsupport argument. message() need HashRef or ArrayRef.';
	}

    my $content = _form_content('message', \@pairs, qw(attachment inline));
    my $req = POST $self->domain_api_url('messages'), Content_type => 'form-data', Content => $content;

    my $res = $self->client->request($req);
    $self->decode_response($res);
}



sub mime {
    my ($self, $args) = @_;

    unless (ref($args) eq 'HASH') {
        die 'unsupport argument. mime() needs a hash ref.';
    }

    # A copy: the hash reference given is left as it is, so that it can be passed again (#39).
    my %args = %$args;

    croak 'mime(): give message or file, not both' if exists $args{message} && exists $args{file};

    if (exists $args{message}) {
        # The MIME message goes in the form as the content of a file, from memory: no temporary
        # file to write and remove.
        my $message = $args{message};
        my $mime = ref $message eq 'SCALAR'                    ? $$message
                 : !ref $message                               ? $message
                 : blessed($message) && overload::Method($message, '""') ? "$message"
                 : croak 'mime(): message must be a string or a reference to a string';
        # A MIME message is bytes. A decoded string (one with the UTF-8 flag) is sent as UTF-8.
        $args{message} = [undef, 'message.mime', Content => _form_value($mime // '')];
    }
    elsif (exists $args{file}) {
        my $file = delete $args{file};
        croak "cannot find file, " . ($file // 'undef') unless defined $file && -f $file;
        $args{message} = [$file];
    }

    my $content = _form_content('mime', [%args], 'message');
    my $req = POST $self->domain_api_url('messages.mime'),
        Content_Type => 'form-data',
        Content => $content;

    my $res = $self->client->request($req);
    $self->decode_response($res);
}




# The query of lists() / list_members(): a hash reference, or nothing (#41).
sub _list_query {
    my ($method, $query) = @_;

    return {} unless defined $query;
    # reftype, not ref: a blessed hash (Hash::MultiValue, say) is a hash too.
    croak "$method() takes a query hash reference" unless (reftype($query) // '') eq 'HASH';
    return { %$query };
}

sub lists {
    my ($self, $query) = @_;

    return $self->recursive('lists/pages', _list_query('lists', $query));
}

sub add_list {
    my ($self, $args) = @_;

    my $res = $self->client->post($self->api_url("lists"), [], $args);
    $self->decode_response($res);
}

sub list {
    my ($self, $address) = @_;

    my $res = $self->client->get($self->api_url(_path('lists', $address)));
    my $json = $self->decode_response($res) or return;
    return $json->{list};
}

sub update_list {
    my ($self, $address, $args) = @_;

    my $res = $self->client->put($self->api_url(_path('lists', $address)), [], $args);
    $self->decode_response($res);
}

sub delete_list {
    my ($self, $address) = @_;

    my $res = $self->client->delete($self->api_url(_path('lists', $address)));
    $self->decode_response($res);
}

sub list_members {
    my ($self, $address, $query) = @_;

    return $self->recursive(_path('lists', $address, 'members', 'pages'),
        _list_query('list_members', $query));
}

sub add_list_member {
    my ($self, $address, $args) = @_;

    my $res = $self->client->post(
        $self->api_url(_path('lists', $address, 'members')), [], $args);
    $self->decode_response($res);
}

sub add_list_members {
    my ($self, $address, $args) = @_;

    my $res = $self->client->post(
        $self->api_url(_path('lists', $address, 'members.json')), [], $args);
    $self->decode_response($res);
}

sub list_member {
    my ($self, $address, $member) = @_;

    my $res = $self->client->get($self->api_url(_path('lists', $address, 'members', $member)));
    my $json = $self->decode_response($res) or return;
    return $json->{member};
}

sub update_list_member {
    my ($self, $address, $member, $args) = @_;

    my $res = $self->client->put(
        $self->api_url(_path('lists', $address, 'members', $member)), [], $args);
    $self->decode_response($res);
}

sub delete_list_member {
    my ($self, $address, $member) = @_;

    my $res = $self->client->delete(
        $self->api_url(_path('lists', $address, 'members', $member)));
    $self->decode_response($res);
}

sub event {
    my ($self, $query) = @_;

    my $api_url;
    if ((blessed($query) && $query->isa('URI')) || (defined $query && !ref $query)) {
        # A URL (the next URL an earlier call returned, for Event Polling) is fetched as it
        # is. Mailgun's paging URLs carry no credentials, so the API key is set on it: only for
        # an https URL on the API's own host, so that the key is never sent anywhere else.
        $api_url = $self->_api_host_url($query);
        unless ($api_url) {
            # Without the userinfo: a URL kept from 1.0.0 still carries the API key.
            my $shown = blessed($query) ? $query->clone : URI->new($query);
            $shown->userinfo(undef) if $shown->can('userinfo');
            my ($host) = split m{/}, $self->api_base;
            croak "event() takes a query hash reference or an https URL on $host, not '$shown'";
        }
        $api_url->userinfo('api:'.$self->api_key);
    } else {
        $api_url = URI->new($self->domain_api_url("events"));
        $api_url->query_form($query);
    }
    return $self->recursive("events", {}, "items", $api_url);
}

sub get_message_from_event {
    my ($self, $event) = @_;

    # Any event that carries storage.url (stored, and others such as accepted) has a message to
    # get; one without it dies, as a non-stored event did (#42).
    my $storage = (reftype($event) // '') eq 'HASH' ? $event->{storage} : undef;
    my $url = (reftype($storage) // '') eq 'HASH' ? $storage->{url} : undef;
    croak "invalid event! this method needs an event with storage.url (a 'stored' event, say)."
        unless defined $url && length $url && (!ref $url || (blessed($url) && $url->isa('URI')));

    # The API key is set on storage.url, so it has to be an https URL on Mailgun's own domain:
    # the storage hosts are per region (storage-us-east4.api.mailgun.net, say), so the API's
    # host alone would refuse them. The API's host (api_base, which a test may point elsewhere)
    # is taken too. An event kept and read back could have been changed.
    my $uri = blessed($url) ? $url->clone : URI->new($url);
    my $host = _https_host($uri);
    my ($api_host) = split m{/}, $self->api_base;
    unless ($host ne '' && ($host eq 'mailgun.net' || $host =~ /\.mailgun\.net\z/ || $host eq lc $api_host)) {
        my $shown = $uri->clone;
        $shown->userinfo(undef) if $shown->can('userinfo');
        croak "get_message_from_event() takes storage.url only on https and mailgun.net, not '$shown'";
    }
    $uri->userinfo('api:'.$self->api_key);

    my $res = $self->client->get($uri->as_string);
    $self->decode_response($res);
}

sub delete_templates {
    my ($self) = @_;

    my $res = $self->client->delete($self->domain_api_url("templates"));
    $self->decode_response($res);
}

sub delete_template {
    my ($self, $name) = @_;

    my $res = $self->client->delete(
        $self->domain_api_url(_path('templates', $name)));
    $self->decode_response($res);
}

# Sends $args (a hash reference or an array reference of pairs) as form-data with $verb ('post'
# or 'put'), as _send_json does JSON; $caller names the method in the error. An array reference
# as a value is a file ([$path]), as HTTP::Request::Common takes it; a decoded string goes out
# as UTF-8, as for message().
my %FORM_REQUEST = (post => \&POST, put => \&PUT);

sub _send_form {
    my ($self, $verb, $url, $caller, $args) = @_;

    my @content;
    if (ref($args) eq 'HASH') {
        @content = %$args;
    }
    elsif (ref($args) eq 'ARRAY') {
        @content = @$args;
    }
    else {
        die "unsupport argument. $caller() need HashRef or ArrayRef.";
    }
    @content = map { _form_value($_) } @content;

    my $req = $FORM_REQUEST{$verb}->($url, Content_type => 'form-data', Content => \@content);
    my $res = $self->client->request($req);
    $self->decode_response($res);
}

sub add_template {
    my ($self, $args) = @_;

    return $self->_send_form(post => $self->domain_api_url('templates'), 'add_template', $args);
}

# $url (a string) with the query of the hash reference $query, as a string.
sub _url_with_query {
    my ($url, $query) = @_;

    my $uri = URI->new($url);
    $uri->query_form($query);
    return $uri->as_string;
}

# The path and the URL of an endpoint of the domain (/v3/{domain}/...), for the templates and the
# suppressions. Unlike domain_api_url, the domain goes through _path too, so a missing domain
# dies before a request is sent.
sub _domain_path {
    my ($self, @segments) = @_;

    return _path($self->domain, @segments);
}

sub _domain_url {
    my ($self, @segments) = @_;

    return $self->api_url($self->_domain_path(@segments));
}

sub templates {
    my ($self, $query) = @_;

    return $self->recursive($self->_domain_path('templates'), _list_query('templates', $query),
        'items', undef, { null_items => 1 });
}

sub template {
    my ($self, $name, $query) = @_;

    my $res = $self->client->get(
        _url_with_query($self->_domain_url('templates', $name), _list_query('template', $query)));
    return $self->_hash_of($res, 'template');
}

sub update_template {
    my ($self, $name, $args) = @_;

    return $self->_send_form(put => $self->_domain_url('templates', $name), 'update_template', $args);
}

sub rename_template {
    my ($self, $name, $new_name) = @_;

    my $res = $self->client->put($self->_domain_url('templates', $name, 'rename', $new_name), [], []);
    $self->decode_response($res);
}

sub copy_template {
    my ($self, $name, $args) = @_;

    croak 'copy_template() takes a hash reference' unless (reftype($args) // '') eq 'HASH';
    return $self->_send_json(put => $self->_domain_url('templates', $name, 'copy'), $args);
}

sub template_versions {
    my ($self, $name, $query) = @_;

    return $self->recursive($self->_domain_path('templates', $name, 'versions'),
        _list_query('template_versions', $query), ['template', 'versions'], undef,
        { null_items => 1 });
}

sub template_version {
    my ($self, $name, $tag) = @_;

    my $res = $self->client->get($self->_domain_url('templates', $name, 'versions', $tag));
    return $self->_hash_of($res, 'template');
}

sub add_template_version {
    my ($self, $name, $args) = @_;

    return $self->_send_form(post => $self->_domain_url('templates', $name, 'versions'),
        'add_template_version', $args);
}

sub update_template_version {
    my ($self, $name, $tag, $args) = @_;

    return $self->_send_form(put => $self->_domain_url('templates', $name, 'versions', $tag),
        'update_template_version', $args);
}

sub delete_template_version {
    my ($self, $name, $tag) = @_;

    my $res = $self->client->delete($self->_domain_url('templates', $name, 'versions', $tag));
    $self->decode_response($res);
}

sub copy_template_version {
    my ($self, $name, $tag, $new_tag, $query) = @_;

    my $url = $self->_domain_url('templates', $name, 'versions', $tag, 'copy', $new_tag);
    my $res = $self->client->put(
        _url_with_query($url, _list_query('copy_template_version', $query)), [], []);
    $self->decode_response($res);
}

# The webhooks of the domain in v3 (/v3/domains/{domain}/webhooks): the URLs for each type of
# event. The names leave `webhooks` and the like to the account webhooks of v1 (#46).
sub _domain_webhook_url {
    my ($self, @segments) = @_;

    return $self->api_url(_path('domains', $self->domain, 'webhooks', @segments));
}

# The form of the URLs ($url or [$url, ...]): `url` once for each, as Mailgun takes it. A URL
# is a string or an object that is one (a URI, say).
sub _webhook_urls {
    my ($method, $urls) = @_;

    my @urls = map {
        blessed($_) && overload::Method($_, '""') ? "$_" : $_
    } ref $urls eq 'ARRAY' ? @$urls : ($urls);
    croak "$method() takes a URL or an array reference of URLs"
        if !@urls || grep { !defined $_ || ref $_ || !length $_ } @urls;
    return [ map { (url => _form_value($_)) } @urls ];
}

# The hash reference under $key of the response, or a failure when the response has none.
sub _hash_of {
    my ($self, $res, $key) = @_;

    my $json = $self->decode_response($res) or return;
    return $json->{$key} if ref $json->{$key} eq 'HASH';
    return $self->_fail("the response has no '$key'", $res);
}

sub domain_webhooks {
    my ($self) = @_;

    my $res = $self->client->get($self->_domain_webhook_url);
    return $self->_hash_of($res, 'webhooks');
}

sub domain_webhook {
    my ($self, $name) = @_;

    my $res = $self->client->get($self->_domain_webhook_url($name));
    return $self->_hash_of($res, 'webhook');
}

sub add_domain_webhook {
    my ($self, $name, $urls) = @_;

    # The type goes in the form (`id`), not in the path: _path only checks it is given.
    _path($name);
    my $res = $self->client->post($self->_domain_webhook_url, [],
        [ id => _form_value($name), @{ _webhook_urls('add_domain_webhook', $urls) } ]);
    $self->decode_response($res);
}

sub update_domain_webhook {
    my ($self, $name, $urls) = @_;

    my $res = $self->client->put($self->_domain_webhook_url($name), [],
        _webhook_urls('update_domain_webhook', $urls));
    $self->decode_response($res);
}

sub delete_domain_webhook {
    my ($self, $name) = @_;

    my $res = $self->client->delete($self->_domain_webhook_url($name));
    $self->decode_response($res);
}

# The suppressions of the domain (#44): the same six endpoints under /v3/{domain}/<path> for
# each kind, so their methods are made from this table. `add_many` is the method that adds up to
# 1000 records in JSON; the allowlist has none (it takes one record, or a CSV file).
# `json_strings` are the fields add_many sends as JSON strings: Mailgun answers `400 Invalid
# JSON` to the `code` of a bounce as a number, and a Perl number (550) goes out as one.
# `delete_tag` takes the tag to remove as the second argument of `delete`, which goes in the
# query (`?tag=`): Mailgun then removes only that tag of the unsubscribe.
my @SUPPRESSIONS = (
    {
        path => 'bounces', list => 'bounces', one => 'bounce', add => 'add_bounce',
        add_many => 'add_bounces', import => 'import_bounces',
        delete => 'delete_bounce', delete_all => 'delete_bounces',
        json_strings => ['code'],
    },
    {
        path => 'unsubscribes', list => 'unsubscribes', one => 'unsubscribe',
        add => 'add_unsubscribe', add_many => 'add_unsubscribes',
        import => 'import_unsubscribes',
        delete => 'delete_unsubscribe', delete_all => 'delete_unsubscribes',
        delete_tag => 1,
    },
    {
        path => 'complaints', list => 'complaints', one => 'complaint',
        add => 'add_complaint', add_many => 'add_complaints', import => 'import_complaints',
        delete => 'delete_complaint', delete_all => 'delete_complaints',
    },
    {
        # The API still calls the allowlist `whitelists`.
        path => 'whitelists', list => 'allowlist_entries', one => 'allowlist_entry',
        add => 'add_allowlist_entry', import => 'import_allowlist',
        delete => 'delete_allowlist_entry', delete_all => 'delete_allowlist',
    },
);

# Sends $data as JSON with $method ('post', 'put' or 'delete', a method of the client). The strings in it
# are taken as characters: a string of bytes of UTF-8 (one read without decoding) would go out
# encoded twice.
sub _send_json {
    my ($self, $method, $url, $data) = @_;

    $self->decode_response($self->_json_request($method, $url, $data));
}

# The response itself, for the callers that look at it after decode_response (all_logs).
sub _json_request {
    my ($self, $method, $url, $data) = @_;

    return $self->client->$method($url, [ 'Content-Type' => 'application/json' ],
        encode_json($data));
}

for my $kind (@SUPPRESSIONS) {
    my $path = $kind->{path};
    my %method;

    $method{ $kind->{list} } = sub {
        my ($self, $query) = @_;

        return $self->recursive($self->_domain_path($path), _list_query($kind->{list}, $query));
    };

    $method{ $kind->{one} } = sub {
        my ($self, $address) = @_;

        my $res = $self->client->get($self->_domain_url($path, $address));
        $self->decode_response($res);
    };

    $method{ $kind->{add} } = sub {
        my ($self, $args) = @_;

        croak "$kind->{add}() takes a hash reference" unless (reftype($args) // '') eq 'HASH';
        my $res = $self->client->post($self->_domain_url($path), [],
            _form_content($kind->{add}, [ %$args ]));
        $self->decode_response($res);
    };

    if ($kind->{add_many}) {
        $method{ $kind->{add_many} } = sub {
            my ($self, $records) = @_;

            croak "$kind->{add_many}() takes an array reference of hash references"
                if ref $records ne 'ARRAY' || !@$records
                || grep { (reftype($_) // '') ne 'HASH' } @$records;
            # Copies, so that the records given are not changed.
            my @strings = @{ $kind->{json_strings} || [] };
            my @copies = map {
                my %record = %$_;
                for my $f (grep { defined $record{$_} && !ref $record{$_} } @strings) {
                    $record{$f} = "$record{$f}";
                }
                \%record;
            } @$records;
            return $self->_send_json(post => $self->_domain_url($path), \@copies);
        };
    }

    $method{ $kind->{import} } = sub {
        my ($self, $file) = @_;

        croak "$kind->{import}() takes the path of a CSV file"
            unless defined $file && !ref $file && -f $file;
        my $req = POST $self->_domain_url($path, 'import'),
            Content_type => 'form-data', Content => [ file => [ _form_value($file) ] ];
        my $res = $self->client->request($req);
        $self->decode_response($res);
    };

    $method{ $kind->{delete} } = sub {
        my ($self, $address, @tag) = @_;

        my $url = $self->_domain_url($path, $address);
        # A second argument that cannot be used dies: deleting the whole entry in place of a
        # tag of it (an undef from a missing key, or a kind without tags) cannot be undone.
        if (@tag) {
            croak "$kind->{delete}() takes only an address" unless $kind->{delete_tag};
            my ($tag) = @tag;
            $tag = "$tag" if blessed($tag) && overload::Method($tag, '""');
            croak "$kind->{delete}() takes a tag as a string"
                if @tag > 1 || !defined $tag || ref $tag || !length $tag;
            $url = _url_with_query($url, { tag => _form_value($tag) });
        }
        my $res = $self->client->delete($url);
        $self->decode_response($res);
    };

    $method{ $kind->{delete_all} } = sub {
        my ($self) = @_;

        my $res = $self->client->delete($self->_domain_url($path));
        $self->decode_response($res);
    };

    no strict 'refs';
    *{ __PACKAGE__ . "::$_" } = $method{$_} for keys %method;
}

sub validate_address {
    my ($self, $address, $query) = @_;

    croak 'validate_address() takes an address' unless defined $address && length $address;
    my $form = _list_query('validate_address', $query);
    $form->{address} = _form_value($address);
    my $res = $self->client->get(_url_with_query($self->api_url('address/validate', 'v4'), $form));
    $self->decode_response($res);
}

# The domains of the account. The list is a page of the v4 API (skip and limit, not paging.next),
# and the domain is deleted with the v3 API, as Mailgun has them.
sub domains {
    my ($self, $query) = @_;

    my $res = $self->client->get(
        _url_with_query($self->api_url('domains', 'v4'), _list_query('domains', $query)));
    $self->decode_response($res);
}

sub get_domain {
    my ($self, $name) = @_;

    my $res = $self->client->get($self->api_url(_path('domains', $name), 'v4'));
    $self->decode_response($res);
}

sub add_domain {
    my ($self, $args) = @_;

    return $self->_send_form(post => $self->api_url('domains', 'v4'), 'add_domain', $args);
}

sub update_domain {
    my ($self, $name, $args) = @_;

    return $self->_send_form(put => $self->api_url(_path('domains', $name), 'v4'),
        'update_domain', $args);
}

sub verify_domain {
    my ($self, $name) = @_;

    my $res = $self->client->put($self->api_url(_path('domains', $name, 'verify'), 'v4'), [], []);
    $self->decode_response($res);
}

sub delete_domain {
    my ($self, $name) = @_;

    my $res = $self->client->delete($self->api_url(_path('domains', $name)));
    $self->decode_response($res);
}

# The analytics of the account (/v1/analytics/...; #48): Logs in place of the Events API, Metrics
# in place of the Stats API, and the new Tags. Each takes the JSON body Mailgun documents and
# returns one page. all_logs follows the pages of Logs; the pages of Metrics and Tags are left
# to the caller (see the POD): how Tags goes on past a page is not known yet.
sub _analytics {
    my ($self, $verb, $path, $caller, $body) = @_;

    $body //= {};
    croak "$caller() takes a hash reference of the body" unless (reftype($body) // '') eq 'HASH';
    # A copy as a plain hash: encode_json dies on a blessed one (Hash::MultiValue, say).
    return $self->_send_json($verb => $self->api_url("analytics/$path", 'v1'), { %$body });
}

sub logs {
    my ($self, $body) = @_;

    return $self->_analytics(post => 'logs', 'logs', $body);
}

# Every page of the logs: the token in pagination.next goes in pagination.token of the next
# request, until a page has no pagination.next (the real API leaves the key out on the last
# page). Returns the items and undef, or, on a failure, the items so far and the pagination of
# the page that failed (with its token; none for the first page), as recursive does with the URL:
# passed back as the pagination of the body, it fetches the rest from there. It is a hash
# reference even for the first page, so that a failure there is not taken for no logs.
sub all_logs {
    my ($self, $body) = @_;

    $body //= {};
    croak 'all_logs() takes a hash reference of the body' unless (reftype($body) // '') eq 'HASH';
    my %body = %$body;
    croak 'all_logs(): pagination is not a hash reference'
        if defined $body{pagination} && (reftype($body{pagination}) // '') ne 'HASH';
    my %pagination = %{ $body{pagination} // {} };
    my $url = $self->api_url('analytics/logs', 'v1');

    my (@items, %seen, $last_res);
    while (1) {
        my $token = $pagination{token};
        # A token that comes again would go round for ever, as a paging.next does in recursive.
        if (defined $token && $seen{$token}++) {
            $self->_fail('pagination.next points back to a page already fetched', $last_res);
            return \@items, { %pagination };
        }
        my $res = $self->_json_request(post => $url, { %body, pagination => { %pagination } });
        $last_res = $res;
        my $json = $self->decode_response($res) or return \@items, { %pagination };
        my $page = _items_of($json, 0, 'items');
        unless ($page) {
            $self->_fail("the response has no 'items' list", $res);
            return \@items, { %pagination };
        }
        push @items, @$page;
        my $next = ref $json->{pagination} eq 'HASH' ? $json->{pagination}{next} : undef;
        # An empty page is the end too, as in recursive: one that still gives a new token (with
        # no `end` in the body, say) would be followed for ever.
        return \@items, undef unless @$page && defined $next && !ref $next && length $next;
        $pagination{token} = $next;
    }
}

sub metrics {
    my ($self, $body) = @_;

    return $self->_analytics(post => 'metrics', 'metrics', $body);
}

sub usage_metrics {
    my ($self, $body) = @_;

    return $self->_analytics(post => 'usage/metrics', 'usage_metrics', $body);
}

sub tags {
    my ($self, $body) = @_;

    return $self->_analytics(post => 'tags', 'tags', $body);
}

sub update_tag {
    my ($self, $tag, $description) = @_;

    croak 'update_tag() takes a tag' unless defined $tag && length $tag;
    # Not '' for a missing one: that would clear the description.
    croak 'update_tag() takes a description' unless defined $description;
    return $self->_analytics(put => 'tags', 'update_tag', { tag => $tag, description => $description });
}

sub delete_tag {
    my ($self, $tag) = @_;

    croak 'delete_tag() takes a tag' unless defined $tag && length $tag;
    return $self->_analytics(delete => 'tags', 'delete_tag', { tag => $tag });
}

sub tag_limits {
    my ($self) = @_;

    my $res = $self->client->get($self->api_url('analytics/tags/limits', 'v1'));
    $self->decode_response($res);
}

1;
__END__

=encoding utf-8

=head1 NAME

WebService::Mailgun - API client for Mailgun (L<https://mailgun.com/>)

=head1 SYNOPSIS

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

=head1 DESCRIPTION

WebService::Mailgun is a client for the Mailgun API (L<https://mailgun.com/>): sending messages
(also in MIME format), mailing lists and their members, events, stored messages and templates.

Each method sends one request, or a series of them for the methods that return every page of a
list, and returns the response decoded from JSON.

=head2 Errors

When a request fails, the method returns C<undef> (an empty list in list context), and
C<error> and C<error_status> tell why. With C<< RaiseError => 1 >>, it warns with the error
message and dies with the status line instead.

    my $res = $mailgun->message($args)
        or die sprintf '%s: %s', $mailgun->error_status, $mailgun->error;

A response that is not what Mailgun sends fails the same way, even with a C<2xx> status (then
in C<error_status>): a body that is not a JSON object, a page without its list of items, a
C<paging.next> that is not an https URL on the API's host, and one that points back to a page
already fetched. An empty body (C<204 No Content>) is
a success with nothing in it.

The methods that return every page (L</Lists of every page>) do not return C<undef>: they stop
at the page that failed and return the items fetched so far. Without C<RaiseError>, a failure
there shows only in C<error>, which keeps the message of the last failure until the next one.

=head3 Rate limits

Mailgun answers C<429 Too Many Requests> when the account sends too many requests. This module
does not try again by itself. The response
in C<error_response> tells when to: C<X-RateLimit-Reset> is the time (in milliseconds since the
epoch, UTC) the limit is reset.

    my $res = $mailgun->message($args);
    if (!$res && $mailgun->error_status =~ /^429/) {
        my $reset = $mailgun->error_response->header('X-RateLimit-Reset');
        my $wait  = $reset ? int($reset / 1000 - time) + 1 : 1;
        sleep $wait if $wait > 0;
        $res = $mailgun->message($args);
    }

L<Rate limits|https://documentation.mailgun.com/docs/mailgun/api-reference/api-overview>

=head2 Lists of every page

C<lists>, C<list_members> and C<event> follow C<paging.next> until a page has no items, and
return two values: an array reference of all the items, and the C<paging.next> URL of that
empty page as a L<URI>, where the items that come later will be (for C<event>, see
L</Event Polling>). When a request fails, the second value is the URL of the page that failed
instead; passed back to C<event>, it fetches the rest of the events from there. A page with no
C<paging.next> is the last one, and the second value is that page's own URL. The URL carries no
API key, so it can be kept or logged; C<event> sets the key when it is passed back. Take the
items in list context:

    my ($lists) = $mailgun->lists();
    my ($events, $next) = $mailgun->event({ event => 'stored', ascending => 'yes' });

In scalar context they return the URL, not the items.

The lists of the templates and of the suppressions return every page in the same way, but their
second value is only good for taking up a failure where it stopped. The C<paging.next> of their
empty page points back to the first page (the suppressions), or to the last one (the versions
of a template), not to the items that come later.

C<all_logs> also returns every page, and the items fetched so far on a failure; its second
value is not a URL (see L</all_logs($body)>).

=head1 METHODS

=head2 C<< new(api_key => $api_key, domain => $domain, region => "us"|"eu"|"au", RaiseError => 0|1, timeout => $seconds) >>

Create a WebService::Mailgun object.

=head3 RaiseError (default: 0)

Die when a request fails, instead of returning C<undef> (see L</Errors>).

=head3 region (default: "us")

The region the domain belongs to: C<us>, C<eu> or C<au>. Any other value dies when a request
is made. The AU region (C<api.au.mailgun.net>) is for Mailgun Send customers who asked for it.

Every version of the API (v3, and the v1 and v4 of some methods, such as C<domains> and
C<validate_address>) is called on the host of the region. Mailgun's documentation does not say
whether the AU region serves Email Validation.

=head3 timeout (default: the one of L<Furl>, 10 seconds)

The seconds a request may take, given to L<Furl>. Raise it to send large attachments over a
slow connection. The HTTP client is made on the first request, so set it in C<new>, or before
the first request.

=head2 error

The error message of the last request that failed.

=head2 error_status

The status line (C<401 Unauthorized>, say) of the last request that failed (see L</Errors>).

=head2 error_response

The response (a L<Furl::Response>) of the last request that failed, for what C<error> and
C<error_status> leave out, such as its headers. See L</Rate limits>. It does not keep the
request (whose URL carries the API key). For a response that is not what Mailgun sends (see
L</Errors>), it is that response, which can have a C<2xx> status.

=head2 message($args)

Send email message.

    # send mail
    my $res = $mailgun->message({
        from    => 'foo@example.com',
        to      => 'bar@example.com',
        subject => 'test',
        text    => 'text',
    });

A decoded string (one with the UTF-8 flag, such as one from C<decode_utf8> or a literal under
C<use utf8>) is sent encoded in UTF-8. Any other string is sent as the bytes it holds.

To give a key several values, pass them in an array reference; the key is sent once for each:

    my $res = $mailgun->message({
        from    => 'foo@example.com',
        to      => ['bar@example.com', 'baz@example.com'],
        'o:tag' => ['newsletter', 'weekly'],
        subject => 'test',
        text    => 'text',
    });

An empty array reference dies, rather than leaving the key out.

C<attachment> and C<inline> are the exception: there an array reference is a file
(C<[$path]>, or C<[$path, $filename]>), as L<HTTP::Request::Common> takes it, and an array
reference of those is several files:

    attachment => [ ['/path/to/a.pdf'], ['/path/to/b.pdf', 'b.pdf'] ],

The same can be passed as an array reference of key-value pairs instead of a hash reference,
with the key given once for each file:

    my $res = $mailgun->message([
        from       => 'foo@example.com',
        to         => 'bar@example.com',
        subject    => 'test',
        text       => 'text',
        attachment => ['/path/to/a.pdf'],
        attachment => ['/path/to/b.pdf'],
    ]);

L<Send an email|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/messages/post-v3--domain-name--messages>

=head2 mime($args)

Send a MIME message you build yourself, usually by using a library to create that MIME message.
The C<to> parameter needs to be passed as one of the arguments.
Either the C<file> or C<message> parameter will also need to be passed.

The C<file> parameter should contain the path to the filename that holds the MIME message.
The C<message> parameter should contain either a string or a reference to a string that holds the MIME message:

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

The MIME message is bytes. A decoded string (one with the UTF-8 flag) is sent encoded in UTF-8,
as are the values of the other keys, here and in C<message>. Give C<message> or C<file>, not
both.

The other keys are sent as they are, and like C<message>, several values of a key can be given in
an array reference (C<< to => ['bar@example.com', 'baz@example.com'] >>). The hash reference
given is not changed, so the same one can be passed again.

L<Send a message in MIME format|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/messages/post-v3--domain-name--messages-mime>


=head2 lists($query)

Get list of mailing lists. C<$query> is an optional hash reference of the query, such as
C<limit>, the number of lists on a page (fewer requests for many lists).

    # get mailing lists (every page; see "Lists of every page")
    my ($lists) = $mailgun->lists();
    # => ArrayRef of mailing list object.

    my ($lists) = $mailgun->lists({ limit => 100 });

L<Get mailing lists|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/mailing-lists/get-v3-lists-pages>

=head2 add_list($args)

Add mailing list.

    # add mailing list
    my $res = $mailgun->add_list({
        address => 'ml@example.com', # Mailing list address
        name    => 'ml sample',      # Mailing list name (Optional)
        description => 'sample',     # description (Optional)
        access_level => 'members',   # readonly(default), members, everyone
    });

L<Create a mailing list|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/mailing-lists/post-v3-lists>

=head2 list($address)

Get detail for mailing list.

    # get mailing list detail
    my $data = $mailgun->list('ml@example.com');

L<Get a mailing list|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/mailing-lists/get-v3-lists-address>

=head2 update_list($address, $args)

Update mailing list detail.

    # update mailing list
    my $res = $mailgun->update_list('ml@example.com' => {
        address => 'ml@example.com', # Mailing list address (Optional)
        name    => 'ml sample',      # Mailing list name (Optional)
        description => 'sample',     # description (Optional)
        access_level => 'members',   # readonly(default), members, everyone
    });

L<Update a mailing list|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/mailing-lists/put-v3-lists-address>

=head2 delete_list($address)

Delete mailing list.

    # delete mailing list
    my $res = $mailgun->delete_list('ml@example.com');

L<Delete a mailing list|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/mailing-lists/delete-v3-lists-address>

=head2 list_members($address, $query)

Get members for mailing list. C<$query> is an optional hash reference of the query, such as
C<subscribed> (C<yes> or C<no>) and C<limit>.

    # get members (every page; see "Lists of every page")
    my ($members) = $mailgun->list_members('ml@example.com');

    # only the members who unsubscribed
    my ($members) = $mailgun->list_members('ml@example.com', { subscribed => 'no' });

L<Get members of a mailing list|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/mailing-lists/get-lists-list_address-members-pages>

=head2 add_list_member($address, $args)

Add member for mailing list.

    # add member
    my $res = $mailgun->add_list_member('ml@example.com' => {
        address => 'user@example.com', # member address
        name    => 'username',         # member name (Optional)
        vars    => '{"age": 34}',      # member params(JSON string) (Optional)
        subscribed => 'yes',           # yes(default) or no
        upsert     => 'no',            # no (default). if yes, update exists member
    });

L<Add a member to a mailing list|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/mailing-lists/post-lists-string:list_address-members>

=head2 add_list_members($address, $args)

Adds multiple members for mailing list.

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

L<Add members to a mailing list|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/mailing-lists/post-lists-list_address-members.json>

=head2 list_member($address, $member_address)

Get member detail.

    # get member
    my $member = $mailgun->list_member('ml@example.com', 'user@example.com');

L<Get a member of a mailing list|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/mailing-lists/get-lists-list_address-members-member_address>

=head2 update_list_member($address, $member_address, $args)

Update member detail.

    # update member
    my $res = $mailgun->update_list_member('ml@example.com', 'user@example.com' => {
        address => 'user@example.com', # member address (Optional)
        name    => 'username',         # member name (Optional)
        vars    => '{"age": 34}',      # member params(JSON string) (Optional)
        subscribed => 'yes',           # yes(default) or no
    });

L<Update a member of a mailing list|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/mailing-lists/put-lists-list_address-members-member_address>

=head2 delete_list_member($address, $member_address)

Delete member for mailing list.

    # delete member
    my $res = $mailgun->delete_list_member('ml@example.com' => 'user@example.com');

L<Delete a member of a mailing list|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/mailing-lists/delete-lists-list_address-members-member_address>

=head2 event($args|$url)

Get event data. C<$args> is a hash reference of the query. In its place C<$url> (a L<URI> or a
string) is fetched as it is, such as the second value an earlier call returned (see
L</Event Polling>); it must be an https URL on the API's host, or C<event> dies.

Mailgun has deprecated the Events API in favor of the
L<Logs API|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/logs/post-v1-analytics-logs>
(C<logs>; see L</ANALYTICS>). No date has been announced for its removal, and C<event> stays
while the Events API works.

    # get event data (every page; see "Lists of every page")
    my ($events, $next) = $mailgun->event({ event => 'stored', limit => 50 });

L<Get events|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/events/get-v3-domain_name-events>

=head2 get_message_from_event($event)

Get stored message. C<$event> must be an event with C<storage.url>, such as a C<stored> event;
any other event dies. So does a C<storage.url> that is not an https URL on C<mailgun.net>, a
host under it, or the API's host, as the API key is sent there.

    # get event data
    my ($events) = $mailgun->event({ event => 'stored' });
    my $msg = $mailgun->get_message_from_event($events->[0]);

L<Retrieve a stored email|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/messages/get-v3-domains--domain-name--messages--storage-key->

=head2 add_template($args)

Add a template. Like C<message>, it takes a hash reference or an array reference of key-value
pairs. Unlike C<message>, an array reference as a value is always a file (C<[$path]>), as
L<HTTP::Request::Common> takes it, such as the template read from a file.

    # add template
    my $res = $mailgun->add_template({
        name        => 'welcome',     # Template name
        template    => 'Hello!',      # Template data
        engine      => 'handlebars',  # Template engine (optional)
        description => 'xyz',         # Description of template (optional)
        tag         => '2.0' ,        # Version tag (optional)
        comment     => 'Test',        # Version comment (optional)
    });

L<Create a template|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/post-v3--domain-name--templates>

=head2 delete_templates()

Delete all templates of the domain.

    my $res = $mailgun->delete_templates();

L<Delete all templates|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/delete-v3--domain-name--templates>

=head2 delete_template($name)

Delete a template.

    my $res = $mailgun->delete_template($name);

L<Delete a template|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/delete-v3--domain-name--templates--template-name->

=head2 templates($query)

Get every template of the domain (every page; see L</Lists of every page>). C<$query> is an
optional hash reference of the query, such as C<< limit => 100 >> (the most Mailgun takes).

    my ($templates) = $mailgun->templates();

L<Get templates|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/get-v3--domain-name--templates>

=head2 template($name, $query)

Get a template (the C<template> of the response). With C<< { active => 'yes' } >>, it has the
active version in C<version>.

    my $template = $mailgun->template('welcome', { active => 'yes' });

L<Get template|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/get-v3--domain-name--templates--template-name->

=head2 update_template($name, $args)

Update the description of a template. Like C<add_template>, it takes a hash reference or an
array reference of key-value pairs.

    my $res = $mailgun->update_template(welcome => { description => 'The first mail' });

L<Update template|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/put-v3--domain-name--templates--template-name->

=head2 rename_template($name, $new_name)

    my $res = $mailgun->rename_template(welcome => 'welcome-v2');

L<Rename a template|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/put-v3--domain-name--templates--template-name--rename--new-template-name->

=head2 copy_template($name, $args)

Copy a template to other accounts. C<$args> is the body Mailgun takes, sent as JSON:
C<requests> (an array reference of C<account_id>, C<name> and C<domain>) and C<source_versions>
(the versions to copy; all of them when left out).

    my $res = $mailgun->copy_template(welcome => {
        requests => [ { account_id => $account_id, name => 'welcome', domain => 'example.com' } ],
    });

L<Copy a template|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/put-v3--domain-name--templates--template-name--copy>

=head2 template_versions($name, $query)

Get every version of a template (every page; see L</Lists of every page>). C<$query> is an
optional hash reference of the query, such as C<limit>.

    my ($versions) = $mailgun->template_versions('welcome');

L<Get all versions|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/get-v3--domain-name--templates--template-name--versions>

=head2 template_version($name, $tag)

Get a version of a template: the C<template> of the response, with the version in C<version>.

    my $template = $mailgun->template_version(welcome => 'v1');
    my $content  = $template->{version}{template};

L<Get a version|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/get-v3--domain-name--templates--template-name--versions--version-name->

=head2 add_template_version($name, $args)

Add a version to a template. Like C<add_template>, it takes a hash reference or an array
reference of key-value pairs, and an array reference as a value is a file.

    my $res = $mailgun->add_template_version(welcome => {
        template => 'Hello, {{name}}!',
        tag      => 'v2',
        comment  => 'With the name',   # (optional)
        active   => 'yes',             # (optional)
    });

L<Create a new version|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/post-v3--domain-name--templates--template-name--versions>

=head2 update_template_version($name, $tag, $args)

Update a version of a template. The fields left out stay as they are.

    my $res = $mailgun->update_template_version(welcome => 'v2', { active => 'yes' });

L<Update a version|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/put-v3--domain-name--templates--template-name--versions--version-name->

=head2 delete_template_version($name, $tag)

    my $res = $mailgun->delete_template_version(welcome => 'v1');

L<Delete a version|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/delete-v3--domain-name--templates--template-name--versions--version-name->

=head2 copy_template_version($name, $tag, $new_tag, $query)

Copy a version of a template to a new version of it. C<$query> is an optional hash reference,
such as C<< { comment => '...' } >>.

    my $res = $mailgun->copy_template_version(welcome => 'v2', 'v3');

L<Copy a version|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-templates/put-v3--domain-name--templates--template-name--versions--version-name--copy--new-version-name->

=head2 domain_webhooks()

Get the webhooks of the domain (the v3 API): a hash reference of the URLs for each type of
event, such as C<< { clicked => { urls => [...] }, ... } >>.

    my $webhooks = $mailgun->domain_webhooks();

The types are C<accepted>, C<delivered>, C<opened>, C<clicked>, C<unsubscribed>, C<complained>,
C<temporary_fail> and C<permanent_fail>. A type takes up to 3 URLs.

L<List all webhooks|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-webhooks/get-v3-domains--domain--webhooks>

=head2 domain_webhook($type)

Get the URLs of a type of event, such as C<< { urls => [...] } >>.

    my $webhook = $mailgun->domain_webhook('clicked');

L<Get webhook URLs by type|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-webhooks/get-v3-domains--domain-name--webhooks--webhook-name->

=head2 add_domain_webhook($type, $url|\@urls)

Add the webhook of a type of event, with a URL or an array reference of URLs. A URL is a
string or an object that is one, such as a L<URI>.

    my $res = $mailgun->add_domain_webhook(clicked => 'https://example.com/clicked');
    $res = $mailgun->add_domain_webhook(opened => ['https://example.com/a', 'https://example.com/b']);

L<Create a webhook|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-webhooks/post-v3-domains--domain--webhooks>

=head2 update_domain_webhook($type, $url|\@urls)

Replace the URLs of a type of event.

    my $res = $mailgun->update_domain_webhook(clicked => ['https://example.com/new']);

L<Update a webhook|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-webhooks/put-v3-domains--domain-name--webhooks--webhook-name->

=head2 delete_domain_webhook($type)

Delete every URL of a type of event.

    my $res = $mailgun->delete_domain_webhook('clicked');

L<Delete a webhook|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-webhooks/delete-v3-domains--domain-name--webhooks--webhook-name->

=head1 SUPPRESSIONS

The bounces, unsubscribes, complaints and allowlist of the domain. Each kind has the same
methods: the list of every entry, an entry, adding, importing a CSV file, deleting an entry,
and deleting every entry. Bounces, unsubscribes and complaints also add up to 1000 entries in
one request.

The lists follow every page, as C<lists> does (L</Lists of every page>), and take an optional
hash reference of the query, such as C<limit> (up to 1000) and C<term> (the start of the
addresses). The methods that add take the fields Mailgun's documentation lists for the kind,
such as C<code> and C<error> of a bounce, or C<domain> in place of C<address> on the allowlist.

=head2 bounces($query)

    my ($bounces) = $mailgun->bounces({ limit => 1000 });

L<List bounces|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/bounces/get-v3--domainid--bounces>

=head2 bounce($address)

    my $bounce = $mailgun->bounce('user@example.com');

L<Lookup a bounce|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/bounces/get-v3--domainid--bounces--address->

=head2 add_bounce($args)

    my $res = $mailgun->add_bounce({ address => 'user@example.com', code => 550, error => 'No such user' });

L<Add bounces|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/bounces/post-v3--domainid--bounces>

=head2 add_bounces(\@records)

Add up to 1000 bounces in one request, sent as JSON. Give the strings as characters (decoded),
not as bytes of UTF-8. C<code> goes out as a JSON string, even when it is given as a number
(C<550>): Mailgun answers C<400 Invalid JSON> to a number there.

    my $res = $mailgun->add_bounces([
        { address => 'a@example.com', code => '550', error => 'No such user' },
        { address => 'b@example.com' },
    ]);

L<Add bounces|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/bounces/post-v3--domainid--bounces>

=head2 import_bounces($path)

Import a CSV file of bounces, up to 25MB. Mailgun takes the file in the background (C<202
Accepted>), so the entries show up a moment later. The header row has to have every column,
even one left empty in the rows: C<address,code,error,created_at>. Without one, Mailgun answers
C<400 invalid header row>. The header rows of the other kinds are
C<address,tags,created_at> (unsubscribes), C<address,created_at> (complaints) and
C<address,domain> (the allowlist).

    # bounces.csv
    address,code,error,created_at
    user@example.com,550,No such user,

    my $res = $mailgun->import_bounces('bounces.csv');

L<Import a list of bounces|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/bounces/post-v3--domainid--bounces-import>

=head2 delete_bounce($address)

    my $res = $mailgun->delete_bounce('user@example.com');

L<Delete a single bounce|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/bounces/delete-v3--domainid--bounces--address->

=head2 delete_bounces()

Delete every bounce of the domain.

    my $res = $mailgun->delete_bounces();

L<Delete all bounces|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/bounces/delete-v3--domainid--bounces>

=head2 unsubscribes($query), unsubscribe($address), add_unsubscribe($args), add_unsubscribes(\@records), import_unsubscribes($path), delete_unsubscribe($address, $tag), delete_unsubscribes()

The same as the methods of bounces, for unsubscribes. An unsubscribe has the tags it applies to
(C<*>, the default, for every message of the domain); see Mailgun's documentation for the field.
C<delete_unsubscribe> takes an optional tag: with one, it removes only that tag of the
unsubscribe, and the others stay. A tag given as C<undef> or C<''> dies rather than deleting
every tag; leave the argument out for that.

    my $res = $mailgun->add_unsubscribe({ address => 'user@example.com' });
    $res = $mailgun->add_unsubscribe({ address => 'user@example.com', tag => 'news' });
    $res = $mailgun->delete_unsubscribe('user@example.com', 'news');   # only 'news'

L<Unsubscribe|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/unsubscribe>

=head2 complaints($query), complaint($address), add_complaint($args), add_complaints(\@records), import_complaints($path), delete_complaint($address), delete_complaints()

The same as the methods of bounces, for complaints.

    my $res = $mailgun->add_complaint({ address => 'user@example.com' });

L<Complaints|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/complaints>

=head2 allowlist_entries($query), allowlist_entry($value), add_allowlist_entry($args), import_allowlist($path), delete_allowlist_entry($value), delete_allowlist()

The same as the methods of bounces, for the allowlist, whose entries are addresses or domains
(C<value>). There is no method to add many entries in one request: import a CSV file instead.

    my $res = $mailgun->add_allowlist_entry({ address => 'user@example.com' });
    $res = $mailgun->add_allowlist_entry({ domain => 'example.com' });
    my $entry = $mailgun->allowlist_entry('example.com');

L<Allowlist|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/allowlist>

=head1 DOMAINS

The domains of the account, with the v4 API (and the v3 one to delete a domain, as Mailgun has
it).

=head2 domains($query)

Get a page of the domains: the response, with C<items> and C<total_count>. Unlike C<lists>, it
does not follow the pages: Mailgun gives the page with C<skip> and C<limit> (up to 1000), not
with C<paging.next>. C<$query> is an optional hash reference, such as C<state>, C<search> or
C<sort>.

    my $page = $mailgun->domains({ limit => 1000 });
    my @names = map { $_->{name} } @{ $page->{items} };
    my $next  = $mailgun->domains({ limit => 1000, skip => 1000 });

L<Get domains|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domains/get-v4-domains>

=head2 get_domain($name)

Get a domain: the response, with C<domain> and its DNS records (C<sending_dns_records> and
C<receiving_dns_records>). It is not C<domain>, which is the domain given to C<new>.

    my $res = $mailgun->get_domain('example.com');

L<Get domain|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domains/get-v4-domains--name->

=head2 add_domain($args)

Add a domain. Like C<add_template>, it takes a hash reference or an array reference of
key-value pairs. The response has no C<smtp_login>: Mailgun leaves it out for a new domain.

    my $res = $mailgun->add_domain({ name => 'mg.example.com', spam_action => 'tag' });

L<Create a domain|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domains/post-v4-domains>

=head2 update_domain($name, $args)

    my $res = $mailgun->update_domain('mg.example.com' => { spam_action => 'block' });

L<Update a domain|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domains/put-v4-domains--name->

=head2 verify_domain($name)

Ask Mailgun to check the DNS records of a domain again.

    my $res = $mailgun->verify_domain('mg.example.com');

L<Verify a domain|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domains/put-v4-domains--name--verify>

=head2 delete_domain($name)

    my $res = $mailgun->delete_domain('mg.example.com');

L<Delete a domain|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domains/delete-v3-domains--name->

=head1 EMAIL VALIDATION

=head2 validate_address($address, $query)

Validate an address (the v4 API). C<$query> is an optional hash reference, such as
C<< { provider_lookup => 'false' } >>. The response has C<result>, C<risk>, C<reason> and the
rest. Mailgun charges for each validation, and a free account gets C<403 Forbidden>
("Email Validations are only available for paid accounts.").

    my $res = $mailgun->validate_address('user@example.com');
    print "$res->{result}\n";   # deliverable, undeliverable, ...

L<Validate a single email address|https://documentation.mailgun.com/docs/mailgun/api-reference/send/validate/validations/get-v4-address-validate>

=head1 ANALYTICS

The analytics of the account, with the v1 API: Logs in place of the deprecated Events API of
C<event>, Metrics in place of the deprecated Stats API, and the new Tags in place of the
deprecated Tags API of v3. Each method takes the JSON body Mailgun documents, as a hash
reference, and returns the response: B<one page>. Give the next page in the body, as below, or
use C<all_logs> for every page of the logs.

=head2 logs($body)

Get a page of the events of the account (every domain), sent as JSON. C<start> and C<end> are
dates of RFC 2822 (C<Wed, 25 Nov 2026 10:00:00 +0000>), and C<pagination> takes C<limit> (up
to 100), C<sort> and C<token>. The next page is the token in C<< $res->{pagination}{next} >>.

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

In place of L</Event Polling>, ask for the time since the last event kept, with C<start>, and
drop the events whose C<id> was seen already: Mailgun may store an event some time after it
happens.

Mailgun keeps the logs for a number of days that depends on the plan (one day on a free
account). A C<start> before that fails with C<400 Bad Request>, and C<error> tells the time the
logs go back to.

L<Query logs|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/logs/post-v1-analytics-logs>

=head2 all_logs($body)

Get every page of C<logs>: it sends the token in C<< pagination.next >> as
C<< pagination.token >> of the next request, until a page has no C<< pagination.next >> or no
items. It takes the body
of C<logs> (it does not change it) and returns two values, as the L</Lists of every page> do:
an array reference of the items of every page, and C<undef>. Take them in list context: in
scalar context it returns the second value, not the items.

    my ($items) = $mailgun->all_logs({
        start      => rfc2822(time - 3600),
        end        => rfc2822(time),
        events     => ['delivered'],
        pagination => { sort => 'timestamp:asc', limit => 100 },
    });

On a failure it does not return C<undef>: it returns the items fetched so far, and in place of
C<undef> the C<pagination> of the page that failed, a hash reference (with the token of that
page; without one when it is the first page). C<error> and C<error_status> tell why. Give it
back as the C<pagination> of the body to fetch the rest from there. With C<RaiseError>, it dies
instead, and the items fetched so far are lost.

A C<< pagination.next >> that gives back a token already sent is a failure too, rather than a
loop. Its C<pagination> has that token, so passing it back goes round the same pages again: ask
for the logs again with a narrower C<start> and C<end> instead.

    my ($items, $rest) = $mailgun->all_logs($body);
    if ($rest) {
        warn $mailgun->error;
        $body->{pagination} = $rest;
        my ($more) = $mailgun->all_logs($body);
    }

=head2 metrics($body)

Get a page of the metrics of the account, such as C<processed_count> and C<delivered_count>,
by C<dimensions> and C<resolution>. The pages go by C<skip> and C<limit> in C<pagination>;
fewer items than C<limit> is the last page.

    my $res = $mailgun->metrics({
        duration   => '7d',
        resolution => 'day',
        dimensions => ['time'],
        metrics    => ['delivered_count', 'bounced_count'],
    });

L<Query metrics|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/metrics/post-v1-analytics-metrics>

=head2 usage_metrics($body)

The same as C<metrics>, for the usage of the account, such as C<email_validation_count>.

L<Query usage metrics|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/metrics/post-v1-analytics-usage-metrics>

=head2 tags($body)

Get a page of the tags of the account. C<tag> is a tag or the start of tags, and
C<pagination> takes C<skip> and C<limit> (up to 1000).

    my $res = $mailgun->tags({ tag => 'news', pagination => { limit => 100 } });

L<List tags|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/tags-new/post-v1-analytics-tags>

=head2 update_tag($tag, $description)

Set the description of a tag. The description is required: C<''> clears it.

    my $res = $mailgun->update_tag(newsletter => 'The weekly newsletter');

L<Update a tag|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/tags-new/put-v1-analytics-tags>

=head2 delete_tag($tag)

    my $res = $mailgun->delete_tag('newsletter');

L<Delete a tag|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/tags-new/delete-v1-analytics-tags>

=head2 tag_limits()

The limit of the tags of the account, how many there are (C<count>) and C<limit_reached>.

    my $res = $mailgun->tag_limits();

L<Get tag limits|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/tags-new/get-v1-analytics-tags-limits>

=head1 Event Polling

The second value C<event> returns is the C<paging.next> URL of the empty page it stopped at, as a
L<URI> without the API key (keep it as a string between runs, if you like). Pass it back to
C<event> in place of the query, and it sets the API key, returns the events stored since the
last call, and the URL to use the next time:

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

Use C<< ascending => 'yes' >>, so that the URL points forward in time.

Mailgun may store an event some time after it happens. Such an event can be dated before events
already fetched, and the URL does not return it. If every event matters, fetch a time range
again once it is old enough (Mailgun's documentation suggests half an hour), and drop the events
whose C<id> was seen already.

L<Event Polling|https://documentation.mailgun.com/docs/mailgun/user-manual/events/event-polling>


=head1 TODO

These APIs are not implemented yet.

=over

=item * The rest of the L<Domains|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domains> API, such as the settings under a domain (listing, adding, updating, verifying and deleting a domain are implemented)

=item * Following every page of C<metrics>, C<usage_metrics> and C<tags> (each returns one page; C<all_logs> follows the pages of C<logs>)

=item * L<Routes|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/routes>

=item * Webhooks: the v4 API of the L<domain webhooks|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/domain-webhooks> (the v3 one is implemented) and the L<account webhooks|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/account-webhooks>

=item * L<Email Validation|https://documentation.mailgun.com/docs/mailgun/api-reference/send/validate/validations> of many addresses (a single address is C<validate_address>)

=item * L<Templates of the account|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/account-templates> (the v4 API; the templates of the domain are implemented)

=back

=head1 SEE ALSO

=over

=item * L<Mailgun API reference|https://documentation.mailgun.com/docs/mailgun/api-reference/send/mailgun/messages>

=item * L<WWW::Mailgun>, another client for the Mailgun API

=back

=head1 LICENSE

Copyright (C) Kan Fushihara.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kan Fushihara E<lt>kan.fushihara@gmail.comE<gt>

=cut

