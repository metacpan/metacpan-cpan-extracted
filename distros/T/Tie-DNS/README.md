# NAME

Tie::DNS - Tie interface to Net::DNS

# SYNOPSIS
        use Tie::DNS;

        tie my %dns, 'Tie::DNS';

        print "$dns{'foo.bar.com'}\n";

        print "$dns{'208.180.41.1'}\n";

# DESCRIPTION
Net::DNS is a very complete, extensive and well-written module. It's completeness, however, makes many comman cases uses a bit wordy, code-wise. Tie::DNS is meant to make common DNS operations trivial, and more complex DNS operations easier.

# EXAMPLES
## Forward lookup
See Above.

## Zone transfer
Get all of the A records from 'foo.com'. (Sorry foo.com if everyone hits your name server testing this module. :-)

        tie my %dns, 'Tie::DNS', {Domain => 'foo.com'};

        while (my ($name, $ip) = each %dns) {
            print "$name = $ip\n";
        }

This obviously requires that your host has zone transfer privileges with a name server hosting that zone. The zone transfer is initiated with the first each, keys or values operation. The tie operation does a SOA query to find the name server for the cited zone.

## Fetching multiple records
Pass the configuration parameter of 'multiple' to any Perl true value, and all FETCH values from Tie::DNS will be an array reference of records.

        tie my %dns, 'Tie::DNS', {multiple => 'true'};

        my $ip_ref = $dns{'cnn.com'};
        foreach (@{$ip_ref}) {
            print "Address: $_\n";
        }

## Fetching records of type besides 'A'
Pass the configuration parameter of 'type' to one of the Net::DNS supported record types causes all FETCHes to get records of that type.

        tie my %dns, 'Tie::DNS', {
            multiple => 'true',
            type => 'SOA'
        };

        my $ip_ref = $dns{'cnn.com'};
        foreach (@{$ip_ref}) {
            print "primary nameserver: $_\n";
        }

Here are the most popular types supported:

        CNAME - Returns the records canonical name.
        A - Returns the records address field.
        TXT - Returns the descriptive text.
        MX - Returns name of this mail exchange.
        NS - Returns the domain name of the nameserver.
        PTR - Returns the domain name associated with this record.
        SOA - Returns the domain name of the original or
            nameserver for this zone.

        (The descriptions are right out of the Net::DNS POD.)

See Net::DNS documentation for further information about these types and a comprehensive list of all available types.

## Fetching all of the fields associated with a given record type.
        tie my %dns, 'Tie::DNS', {type => 'SOA', all_fields => 'true'};

        my $dns_ref = $dns{'cnn.com'};
        foreach my $field (keys %{$dns_ref}) {
            print "$field = " . ${$dns_ref}{$field} . "\n";
        }

This code fragment will print all of the SOA fields associated with cnn.com.

## Caching
The argument 'cache' will cause the DNS results to be cached. The default is no caching. The 'cache' argument is passed through to Tie::Cache. If Tie::Cache cannot be loaded, caching will be disabled.  Entries whose DNS TTL has expired will be re-queried automatically.

        tie my %dns, 'Tie::DNS', {cache => 100};
        print "$dns{'cnn.com'}\n";
        print "$dns{'cnn.com'}\n";  ## cached!

## Getting all/different fields associated with a record
        tie my %dns, 'Tie::DNS', {all_fields => 'true'};
        my $dns_ref = $dns{'cnn.com'};
        print $dns_ref->{'ttl'}, "\n";

## Passing arguments to Net::DNS::Resolver->new()
        tie my %from_localhost, 'Tie::DNS', {
            resolver_args => {
                nameservers => ['127.0.0.1']
            }
        };
        print "$from_localhost{'test.local'}\n";

You can pass arbitrary arguments to the Net::DNS::Resolver constructor by setting the "resolver_args" argument. In the example above, an alternative nameserver is used instead of the default one.

## Changing various arguments to the tie on the fly
        tie my %dns, 'Tie::DNS', {type => 'SOA'};
        print "$dns{'cnn.com'}\n";

        tied(%dns)->args({type => 'A'});
        print "$dns{'cnn.com'}\n";

This code fragment first does an SOA query for cnn.com, and then changes the default mode to A queries, and displays that.

## Simple Dynamic Updates
Assign into the hash, key DNS name, value IP address, to add a record to the zone in the domain argument. For instance:

        tie my %dns, 'Tie::DNS', {
            domain => 'realms.lan',
            multiple => 'true'
        };

        $dns{'food.realms.lan.'} = '131.22.40.1';

        foreach (@{$dns{'food'}}) {
            print " $_\n";
        }

# Methods
## error
Returns the last error, either from Tie::DNS or Net::DNS

## get_root_server
Returns the root name server.

## do_forward_lookup
Returns the results of a forward lookup.

## do_reverse_lookup
Returns the results of a reverse lookup.

## args
Change various arguments to the tie on the fly.

# TODO
This release supports the basic functionality of Net::DNS. The 1.0 release will support the following:

Different access methods for forward and reverse lookups.

The 2.0 release will strive to support DNS security options.

# AUTHOR
Dana M. Diederich <dana@realms.org>

# ACKNOWLEDGMENTS
kevin Brintnall <kbrint@rufus.net> for Caching patch Alvar Freude <alvar@a-blast.org> for arguments to resolver patch Greg Myran <gmyran@drchico.net> for fixes for Net::DNS >= 0.69

# BUGS
in-addr.arpa zone transfers aren't yet supported.

Patches, flames, opinions, enhancement ideas are all welcome.

# COPYRIGHT 
Copyright (c) 2009,2013,2015 Dana M. Diederich. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
  (see http://www.perl.com/perl/misc/Artistic.html)
