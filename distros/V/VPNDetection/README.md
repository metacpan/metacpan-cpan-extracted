# [<img src="https://s3.vpndetection.io/vpndetection-public/brand/mark.svg" alt="VPNDetection" width="24"/>](https://vpndetection.io/) VPNDetection Perl Client Library

[![CPAN](https://img.shields.io/cpan/v/VPNDetection.svg)](https://metacpan.org/dist/VPNDetection)
[![license](https://img.shields.io/cpan/l/VPNDetection.svg)](LICENSE)

The official Perl client library for the [VPNDetection](https://vpndetection.io) API.

The library helps you query VPNDetection's APIs for anonymity detection including VPNs, residential proxies, Tor nodes, hosting servers, CDNs, relays and more.

## Getting Started

```bash
cpanm VPNDetection
```

Requires Perl 5.22 or newer. [Mojolicious](https://metacpan.org/dist/Mojolicious) is the only runtime dependency, plus `IO::Socket::SSL` for TLS.

## Usage

**No API key needed to start.** The free tier answers `ip` and `is_vpn`, and allows 1000 requests per day per source address.

```perl
use VPNDetection;

my $client = VPNDetection->new;

my $result = $client->lookup('45.83.91.1');
print $result->is_vpn;   # 1
```

### With an API key

An API key raises your quota, and raises your features on a paid plan. Create one in the [console](https://app.vpndetection.io), then pass it in:

```perl
my $client = VPNDetection->new(api_key => $ENV{VPNDETECTION_API_KEY});

my $result = $client->lookup('45.83.91.1');
print $result->is_vpn;               # 1
print $result->vpn->{provider};      # mullvad
print $result->is_hosting;           # 1
print $result->hosting->{provider};
```

### Your own address

```perl
my $result = $client->my_ip;
print $result->ip;   # the address we saw this call come from
```

Same answer `lookup` would give for that address, and the same cost against your allowance. It is deliberately not cached: which address you are is the whole question, and a machine that moves between networks would otherwise be told where it used to be.

### Your plan and usage

```perl
my $acct = $client->my_entitlement;
print $acct->{plan}{key};          # max
print $acct->{usage}{requests};    # 580
print $acct->{usage}{window_end};  # when the allowance resets
```

Usage counts against the anniversary of your subscription, not the calendar month and not the billing period, and it is the same number a lookup is gated on. `hard_limit` is `undef` on an uncapped plan, which is not the same as zero.

`my_ip` returns a `VPNDetection::Result` like `lookup` does; `my_entitlement` returns the decoded hashref. `my_ip_p` and `my_entitlement_p` are the non-blocking forms.

### Batch lookup

Look up many addresses at once. Bogons and cached answers are handled locally, and everything else goes to the batch endpoint in chunks of up to 1000 addresses, in parallel:

```perl
my $answers = $client->lookup_batch(['45.83.91.1', '8.8.8.8', '1.1.1.1']);

for my $ip (keys %$answers) {
    my $answer = $answers->{$ip};
    if ($answer->isa('VPNDetection::Error')) {
        warn "$ip: $answer";
        next;
    }
    print "$ip: ", $answer->is_vpn, "\n";
}
```

Results are keyed by address, so duplicates in your list collapse into a single entry and one address failing never loses the rest: it carries its error as its value, with the status the API would have given that address on its own. Perl hashes carry no insertion order, so iterate your own list when order matters.

How many chunks are in flight at once, and how many times a failed chunk is retried, are configurable per call:

```perl
my $answers = $client->lookup_batch(\@many_ips, concurrency => 4, retries => 4);
```

### Caching

Answers are cached by default, so repeat lookups of the same address are free:

```perl
my $client = VPNDetection->new;

my $result = $client->lookup('45.83.91.1');
print $result->is_vpn;    # 1, API request

my $again = $client->lookup('45.83.91.1');
print $again->is_vpn;     # 1, no API request, result was cached
```

You can change the default cache variables (max size, TTL in seconds) on initialization, or even disable it:

```perl
my $client = VPNDetection->new(cache_size => 50_000, cache_ttl => 6 * 60 * 60);
my $uncached = VPNDetection->new(cache_size => 0);
```

The cache belongs to the client, never to the process. Two clients holding different keys are on different plans and entitled to different fields, so a shared cache would serve one of them the other's shape.

### Private and reserved addresses

Private, loopback, link-local, documentation and multicast addresses (and their IPv6 equivalents, including the 6to4 and Teredo ranges) can never be VPN or proxy infrastructure. The library answers them locally, so they cost no request and no quota:

```perl
my $result = $client->lookup('192.168.1.1');
$result->is_bogon;    # 1, this answer was computed rather than served
$result->is_vpn;      # 0
```

The check is available on the client, which is handy when your inputs are addresses anyway:

```perl
$client->is_bogon('10.0.0.1');    # 1
$client->is_bogon('8.8.8.8');     # 0
```

It is also importable on its own, if you want it without a client:

```perl
use VPNDetection 'is_bogon';

is_bogon('10.0.0.1');    # 1
```

### Errors

Failures die with a `VPNDetection::Error` carrying a `kind` and a `retryable` flag. It stringifies to its message, so it reads like an ordinary string exception where you do not care which it is:

```perl
my $result = eval { $client->lookup('1.1.1.1') };
if (my $err = $@) {
    die $err unless ref $err && $err->isa('VPNDetection::Error');
    warn $err->kind, ' ', $err->retryable;
}
```

`kind` is one of `bad_request`, `unauthorized`, `forbidden`, `rate_limited`, `quota_exceeded`, `server_error` or `network`.

Note that `rate_limited` and `quota_exceeded` both arrive as HTTP 429 and are not the same thing. A rate limit is when the API faces extreme traffic bursts and so retrying later works; but a spent quota needs your allowance raised or the window to roll over. The library retries rate limits for you, but not if your quota is exceeded.

### Non-blocking use

Every call has a `_p` twin returning a [Mojo::Promise](https://metacpan.org/pod/Mojo::Promise), so the library drops into a Mojolicious application without a worker or a thread:

```perl
$client->lookup_p('45.83.91.1')
    ->then(sub { print shift->is_vpn })
    ->catch(sub { warn shift })
    ->wait;
```

The blocking calls are those same promises plus a `wait`, so both paths retry, cache and short-circuit identically. Inside an already running event loop the blocking calls cannot block, and say so rather than returning nothing.

### Database downloads

If your key carries the `db.download` scope, the licensed databases are available through `$client->database`. A license covers a database *family*, and the id you download is the one hanging off its `versions`:

```perl
my $databases = $client->database->list;
my $id = $databases->[0]{versions}[0]{id};    # e.g. vpn_ip_v1
```

There are three ways to fetch one: as a link you transfer yourself, as bytes, or straight to a file.

```perl
my $db = $client->database;

my $url = $db->download_url($id, 'mmdb');                  # a time-limited link
my $bytes = $db->download_bytes('cdn_ip_v1', 'csvgz');     # in memory
my $written = $db->download($id, 'mmdb', "./$id.mmdb");    # streamed to disk
```

`download` holds nothing beyond one chunk however large the database is, writes through a neighboring `.part` file so a transfer that dies half way leaves nothing that reads as a whole database, and raises rather than accepts a body that stops early. `download_bytes` holds the **whole file in memory**, and the catalog runs from `cdn_ip_v1` at 10 KB to `resproxy_ip_90d_v1` at 1.79 GB, so use `download` for anything you have not measured.

### Absent is not false

A field your plan does not include is absent, which never means "we checked and found nothing". Perl makes that easy to miss, since `undef` and `0` are both false.

```perl
if ($result->is_hosting // 0) { ... }     # absent counts as false
if ($result->has('is_hosting')) { ... }   # is this field in my plan?
```

## Other Libraries

There are official VPNDetection client libraries available for many languages including PHP, Python, Go, Java, Ruby, and many popular frameworks such as Django, Rails, and Laravel. See our GitHub at https://github.com/vpndetection-io for more.

## About VPNDetection

VPN Detection API: Accurate anonymity detection identifying VPNs, residential proxies, hosting servers, Tor nodes, CDNs, relays and more.

[<img src="https://s3.vpndetection.io/vpndetection-public/brand/mark.svg" alt="VPNDetection" width="96"/>](https://vpndetection.io/)

## License

This project is licensed under the [MIT License](LICENSE).
