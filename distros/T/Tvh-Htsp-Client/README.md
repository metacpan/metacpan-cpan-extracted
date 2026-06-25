# Name

Tvh::Htsp::Client - a Tvheadend HTSP client library written in perl

Refer to [HTSP](https://docs.tvheadend.org/documentation/development/htsp)

# Version

Version 0.06

# Synopsis

    use feature 'say';
    use JSON::XS;
    use Tvh::Htsp::Client;

    # Establish client connection to HTSP server
    my $htsp = Tvh::Htsp::Client->new( { host => $host, port => $port, debug_info => $debug_info } );
    #   Be sure to use HTSP 'port', defaults to '9982'
    #   'host' defaults to 'localhost'
    #   'debug_info' defaults to 0
    #    setting it to 1 will output all details of client to server communication, which is normally not required
    # Setup
    my $msg = { method => 'hello', htspversion => 43, clientname => 'Tvh::Htsp::Client', clientversion => "v$Tvh::Htsp::Client::VERSION" };
    my $reply = $htsp->htsp_send_recv($msg);
    # Tvheadend HTSP API or JSON API via HTTP Proxy using HTSP 'api' method
    $msg = { method => 'api', path => 'channel/grid', args => { start => 0, limit => 99999, sort => 'number', dir => 'desc' } };
    $reply = $htsp->htsp_send_recv($msg);
    say JSON::XS->new->encode($reply);
    #
    # -- or --
    #
    # Dump epgdb.v3 TVH Electronic Program Guide (EPG) database in json format
    #   we do not need the client connection to the HTSP server and set parameter 'no_client' to 1
    #   database version 3 sligthly deviates from the HTSP protocol, we  set parameter 'epgdb_v3' to 1
    #   database version 2 uses HTSP protocol, no need to set 'epgdb_v3' in this case
    my $htsp = Tvh::Htsp::Client->new( { no_client => 1, epgdb_v3 => 1 } );
    my $epgdb = qx(7zz e -so /var/lib/tvheadend/epgdb.v3 2>/dev/null);    # unzip epgdb.v3 to string
    my $db=[];
    my $i=0;
    while (length $epgdb) {
      my $bd = $htsp->htsmsg_deserialise(\$epgdb);
      push ($db->@*, $bd);
      $i++ if $bd->{id};
    }
    # Save Tvheadend events database to 'epg-dmp.json'
    open my $file_handle, '>', "epg-dmp.json" or die "'epg-dmp.json' Error opening: $!\n";
    say $file_handle JSON::XS->new->encode($db);
    close $file_handle;
    say "Dumped '$i' TVH Events into 'epg-dmp.json'";

# Description

This module implements a Tvheadend HTSP client library written in perl

[https://docs.tvheadend.org/documentation/development/htsp](https://docs.tvheadend.org/documentation/development/htsp)

# Methods

## new

`$htsp = Tvh::Htsp::Client->new( $args );`

Constructor; returns a new Tvh::Htsp::Client object

Valid parameters, all optional: see Synopsis

## getChanUuidId

`$channelids = $htsp->getChanUuidId();`

Get all channel uuid and ID in a hash reference

Valid parameters: none

## getChanNamId

`($chan_name, $chan_id) = $htsp->getChanNamId($channel);`

Get channel name and ID

Valid parameter: channel Name or channel ID or channel Number

## htsp\_send\_recv

`$reply = $htsp->htsp_send_recv($msg);`

send and receive a HTSP message; returns the deserialised server reply in a hash reference

Valid parameter: hash reference with message to send

## htsp\_send

`$size = $htsp->htsp_send($msg);`

send a HTSP message; returns the size in bytes of the serialised message sent

Valid parameter: hash reference with message to send

## htsp\_recv

`$reply = $htsp->htsp_recv();`

receive a HTSP message; returns the deserialised server reply in a hash reference

Valid parameter: none

## htsmsg\_deserialise

`$reply = $htsp->htsmsg_deserialise($htsmsg);`

deserialise a HTSP message; returns the deserialised message in a hash reference

Valid parameter: scalar reference with HTSP message to deserialise

## DESTROY

`$htsp->DESTROY;`

close IO::Socket

# Author

Ulrich Buck, `<ulibuck at cpan.org>`

# License and Copyright

This software is Copyright (c) 2026 by Ulrich Buck.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

This program is distributed in the hope that it will be useful, but without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose.
