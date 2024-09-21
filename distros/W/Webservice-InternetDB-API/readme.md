# NAME

Webservice::InternetDB::API - Fast IP Lookups for Open Ports and Vulnerabilities using InternetDB API

# SYNOPSIS
```perl
    use v5.40;
    use Webservice::InternetDB::API;

    # get information about this current machine:
    my $response = Webservice::InternetDB::API->new()->get();

    # get information about another machine:
    $response = Webservice::InternetDB::API->new()->get('1.1.1.1');

    # re-use the same object:
    my $api = Webservice::InternetDB::API->new();
    $api->get('1.1.1.1');
```
# DESCRIPTION

This module provides an object oriented interface via the keyword "class" feature to the InternetDB free API endpoint provided by [https://internetdb.shodan.io/](https://internetdb.shodan.io/). Shodan also provides much more robust paid services with subscription that this module does not provide access to.

# METHODS

- `get()`

Accepts a string that is the IP address to be scanned.
Returns a hash reference with the results of the scan.

example response:

    {
        cpes        [],
        hostnames   [
            "one.one.one.one"
        ],
        ip          "1.1.1.1",
        ports       [
            53,
            80,
            443,
            2082,
            2083,
            2087,
            8080,
            8443,
            8880
        ],
        tags        [],
        vulns       []
    }

# SEE ALSO

- Call for API implementations on PerlMonks: [https://perlmonks.org/?node\_id=11161472](https://perlmonks.org/?node_id=11161472)
- Listed at  freepublicapis.com: [https://www.freepublicapis.com/ipify-api](https://www.freepublicapis.com/ipify-api)
- Official api webpage: [https://www.ipify.org/](https://www.ipify.org/)

# AUTHOR

Joshua Day, <hax@cpan.org>

# SOURCECODE

Source code is available on Github.com : [https://github.com/haxmeister/perl-InternetDB](https://github.com/haxmeister/perl-InternetDB)

# COPYRIGHT AND LICENSE

Copyright (C) 2024 by Joshua Day

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
