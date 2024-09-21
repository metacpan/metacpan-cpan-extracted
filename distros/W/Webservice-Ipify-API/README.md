# NAME

Webservice::Ipify::API - Lookup your IP address using Ipify.org

# SYNOPSIS
```perl
    use v5.40;
    use Webservice::Ipify::API;

    my $api = Webservice::Ipify::API->new();

    # Universal: IPv4/IPv6
    say $api->get();

    # used for IPv4.
    say $api->get_ipv4();

    # used for IPv6 request only. If you don't have an IPv6 address, the request will fail.
    say $api->get_ipv6();
```
# DESCRIPTION

Look up your external IP address through the ipify public API via the feature "class" keyword.

# SEE ALSO

- Call for API implementations on PerlMonks: [https://perlmonks.org/?node\_id=11161472](https://perlmonks.org/?node_id=11161472)
- Listed at  freepublicapis.com: [https://www.freepublicapis.com/ipify-api](https://www.freepublicapis.com/ipify-api)
- Official api webpage: [https://www.ipify.org/](https://www.ipify.org/)

# AUTHOR

Joshua Day, <hax@cpan.org>

# SOURCE CODE

Source code is available on Github.com : [https://github.com/haxmeister/perl-ipify](https://github.com/haxmeister/perl-ipify)

# COPYRIGHT AND LICENSE

Copyright (C) 2024 by Joshua Day

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
