#!/usr/bin/perl
# vim: filetype=perl

use warnings;
use strict;
use Tie::Handle::HTTP;
use HTTP::Daemon;
use HTTP::Status;
use HTTP::Response;

use Test::More 'no_plan'; # tests => 10;

$SIG{CHLD} = 'IGNORE';

BEGIN {
    my $flag = $ENV{VERBOSE} || 0;
    eval "sub VERBOSE () { $flag }";
}

my $lorem = do {
    local $/;
    open FILE, "t/test.txt" or die( "Couldn't open test file: $!\n" );
    <FILE>;
};

my @std_headers = (
    'Accept-Ranges' => 'bytes',
    'Content-Type' => 'text/plain',
);

my $d = HTTP::Daemon->new();

my $pid = fork();

die( "Fork Failed!\n" ) unless defined( $pid );

if( $pid ) {
    ok( tie( *FOO, 'Tie::Handle::HTTP', $d->url . 'test.txt' ), "Tie succeeded" );
    ok( !eof( FOO ), "not at end of file yet" );
    ok( do "t/Common.perl", "Do EXPR: ($!) ($@)" );
    kill 'INT', $pid;
}
else {
    $0 = "Forking HTTP Daemon";
    while (my $c = $d->accept) {
        my $hpid = fork();
        
        next if (defined( $hpid ) and $hpid);
        warn "Fork Failed!\n" unless defined( $hpid );

        $0 = "Forking HTTP Server";
        while (my $r = $c->get_request) {
            next unless ($r->url->path eq '/test.txt');
            
            if ($r->method eq 'HEAD') {
                $c->send_response( HTTP::Response->new(
                    RC_OK, "Yessir", [
                        @std_headers,
                        'Content-Length' => length( $lorem ),
                        'Connection' => 'close',
                    ],
                ) );

                # If we don't close the connection after this HEAD request, the
                # client may reuse it and then we race for an unknown reason.
                exit;
            }
            elsif ($r->method eq 'GET') {
                if (my $range = $r->header( 'Range' )) {
                    if (my ($start, $end) = $range =~ m/^bytes=(\d+)-(\d+)?$/) {
                        $end = $end - $start + 1 if $end;
                        my $part = substr( $lorem, $start, $end );
                        $c->send_response( HTTP::Response->new(
                            RC_PARTIAL_CONTENT, "Right Away Sir", [
                                @std_headers,
                                'Content-Length' => length( $part ),
                                'Content-Range' => "$start-$end/" . length( $lorem ),
                            ], $part
                        ) );
                    }
                    else {
                        $c->send_response( HTTP::Response->new(
                            RC_REQUEST_RANGE_NOT_SATISFIABLE, "Nope",
                        ) );
                    }
                }
                else {
                    $c->send_response( HTTP::Response->new(
                        RC_OK, "Here we go", [
                            @std_headers,
                            'Content-Length' => length( $lorem ),
                        ], $lorem
                    ) );
                }
            }
        }
        exit;
    }
}
