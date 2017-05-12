TinyDNS::Reader
===============

This repository contains the source for the perl module `TinyDNS::Reader`, `TinyDNS::Reader::Merged`, and `TinyDNS::Record`

Together the three modules allow the reading and parsing of tinydns data-files, like so:

    my $reader  = TinyDNS::Reader->new( file => "zones/steve.co" );
    my $records = $reader->parse();

    foreach my $record ( @$records )
    {
        print $record;
    }

Further details are available in the test-cases, or the POD.


Compatibility Notes
-------------------

This module was put together for the [Git-based DNS hosting service](https://dns-api.com/), and it wasn't initially planned to be added to CPAN, because the name implies it can parse real/genuine/complete TinyDNS records, however that is not the case:

* We ignore SOA records.
* Our TXT record (which should have a `:`-prefix) is non-standard/weird.
       * We use `Tname:"value goes here"[:ttl]` instead.  Which is cleaner.

That said there is actually no module available on CPAN for _reading_ TinyDNS files, just for generating them, so despite the compatibility niggles I've uploaded it regardless.


Utility Script
--------------

Contained within the distribution is a simple `dump-zones` script, which will allow you to see how a file would be parsed by the [DNS-hosting service](https://dns-api.com/).

Usage is as simple as:

    ./dump-records file1 file2 .. fileN

The companion script uses the merged-version of the `TinyDNS::Reader` which collapses multiple records with the same name into array-versions of the results.  It is probably the module you should prefer.


Steve
--
