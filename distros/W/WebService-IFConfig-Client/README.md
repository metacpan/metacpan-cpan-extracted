# Perl5 Module WebService::IFConfig::Client
Client for [Martin Polden](https://github.com/mpolden)'s [IP address lookup service](https://ifconfig.co).

## Note:

* this has only been tested lightly
* there's no test cases
* there's no Build.PL, etc., etc.
* obvs., it's not on CPAN
* PRs welcome

## Rate Limiting

Unless you are hosting your own copy of the service, the canonical instance at https://ifconfig.co requests you limit your requests to 1 per minute. Don't abuse his service, host your own if you need more frequent lookups.

## Usage

```
use feature qw/say/;
use WebService::IFConfig::Client;
my $ipconfig = WebService::IFConfig::Client->new();

say $ifconfig->city();
say $ifconfig->country();
say $ifconfig->hostname();
say $ifconfig->ip();
say $ifconfig->ip_decimal();
```

### Author, Copyright

Copyright &#x24B8; 2017 [Nicolas Doye](https://worldofnic.org)

### License

[Apache License, Version 2.0](https://opensource.org/licenses/Apache-2.0)
