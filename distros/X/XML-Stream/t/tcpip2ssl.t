use strict;
use warnings;

use Test::More tests=>3;

SKIP:
{
    eval("use IO::Socket::SSL 0.81;");
    skip "IO::Socket::SSL not installed", 2 if $@;
    skip "No network communication allowed", 2 if ($ENV{NO_NETWORK});

    BEGIN{ use_ok( "XML::Stream","Tree", "Node" ); }

    my $stream = XML::Stream->new(
        style=>'node',
        debug=>'stdout',
        debuglevel=>0,
    );
    ok( defined($stream), "new()" );

    SKIP:
    {

        my $status = $stream->Connect(hostname=>"jabber.org",
                                      port=>5223,
                                      namespace=>"jabber:client",
                                      connectiontype=>"tcpip",
                                      ssl=>1,
                                      ssl_verify=>0x00,
                                      timeout=>10);

        skip "Cannot create initial socket", 1 unless $stream;
        
        ok( $stream, "converted" );
    }
}
