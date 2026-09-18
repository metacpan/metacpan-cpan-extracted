<!-- shared-readme:banner:start -->
[![Litport free proxies: live lists, API and SDKs](https://raw.githubusercontent.com/litportnet/free-proxy-sdk/main/assets/free-proxy-banner-static.png)](https://litport.net/free-proxy)
<!-- shared-readme:banner:end -->

# Litport Free Proxy SDK for Perl

Perl 5.16+ client for Litport's API snapshot of verified HTTP, SOCKS4, and SOCKS5 proxies. The
client itself is built on core modules; `IO::Socket::SSL` and `Net::SSLeay` are required because the
default snapshot endpoint is https and `HTTP::Tiny` needs them to speak TLS.

## Install

```sh
cpanm WebService::Litportnet::FreeProxy
```

```perl
use WebService::Litportnet::FreeProxy;

my $client = WebService::Litportnet::FreeProxy->new;
my $proxies = $client->pick_best(5, {
    protocol           => 'socks5',
    country             => 'us',
    max_latency_ms      => 500,
    min_uptime_7d       => 90,
    min_checks_7d       => 50,
    checked_within_min  => 30,
});
print "$_->{url}\n" for @$proxies;
```

`get_proxies` and `pick_best` return an array reference of normalized proxy hash
references. Filters accept protocol, country, anonymity, HTTPS, maximum latency,
minimum seven-day uptime, minimum checks, freshness (1-1,440 minutes), and limit.
Results sort by seven-day uptime, latency, then URL. `uptime_7d` is `undef` when a
record has fewer than 50 checks.

The API envelope validates `count`, `truncated`, a two-minute `generatedAt` window,
public IPv4 addresses, and nullable fields. Set `timeout =>` on `new`; provide
`transport => sub { my ($url, $timeout) = @_; return ($status, $headers, $body) }`
for deterministic tests.

## Test

```sh
perl Makefile.PL
make
make test
```

## Resources

- [Free proxy list](https://litport.net/free-proxy)
- [API documentation](https://litport.net/docs/free-proxy-api)
- [SDK source](https://github.com/litportnet/free-proxy-sdk)

Free proxies are for testing only. Never route credentials, cookies, payment data, or private data through them.
