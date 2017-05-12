
WebService::Amazon::Route53::Caching
------------------------------------

This repository contains the Perl module `WebService::Amazon::Route53::Caching`,
which is a class built around the existing [WebService::Amazon::Route53](http://search.cpan.org/perldoc?WebService%3A%3AAmazon%3A%3ARoute53) module.

This class exists solely to implement caching, such that discovering individual zone details is fast and efficient.

Users who work with the Amazon Route53 API will prefer to work with _zone_
names, but the Amazon API uses internal Amazon-IDs.

For example you might upload the zone `example.com` and this will be given
an identifier such as `/hostedzone/Z2DZSBZWYPDL87`.  The API use will
rely upon the latter Amazon-ID.

If your user-interface, or other usage, has only the zone name then you
must lookup the Amazon-ID by invoking the `find_hosted_zone` method, which
will internally:

* Fetch 100 hosted-zones from your account.
* Look for a match, if found return the details.
* Continue until all records are exhausted.

This is woefully inefficient if you have a large number of hosted domains,
and given that the mapping between zone-name and Amazon-ID doesn't ever
change there is a great speedup to be achieved via transparent caching.



Minor Optimizations
-------------------

* When a zone is created the ID is returned, so we pre-emptively add it to the cache.
* When a zone is deleted we purge the cache of the appropriate records.
* We reconfigure the internal HTTP-client to use HTTP Keep-Alive
    * Which in testing can speedup fetchs by almost 50%.



Testing
-------

The distribution contains some minor test-cases, which can be
executed as you'd expect:

    perl Makefile.PL
    make test

The functional tests require that you provide your Amazon Route53
credentials - so they are skipped by default.  To run this:

    export AWS_ID=xxx
    export AWS_KEY=xxxx
    make test

The functional tests will create, and later delete, the zones:

* `aws-test-zone-$$.com`
* `aws-test-zone-$$.org`

It is assumed this will never collide with legitimate domains, and
even if they did then nobody would be impacted because the legitimate
domains would have their nameservers set in `whois` somewhere else.



Steve
--
