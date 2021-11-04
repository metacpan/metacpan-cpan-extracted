#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use WebSocket::Server;
    use JSON;
    our $DEBUG = 3;
};

{
    my $origin = 'http://localhost';
    my $j = JSON->new->relaxed->convert_blessed;
    my $ws = WebSocket::Server->new(
        debug => $DEBUG,
        port => 8082,
        on_connect => sub
        {
            my( $serv, $conn ) = @_;
            $conn->on(
                handshake => sub
                {
                    my( $conn, $handshake ) = @_;
                    print( "Connection from ip '", $conn->ip, "' on port '", $conn->port, "'\n" );
                    print( "Request uri: '", $conn->request_uri, "'\n" );
                    print( "Query string: '", $conn->request_uri->query, "'\n" );
                    print( "Origin is: '", $conn->origin, "', ", ( $conn->origin eq $origin ? '' : 'not ' ), "ok\n" );
                    # $conn->disconnect() unless( $handshake->req->origin eq $origin );
                },
                ready => sub
                {
                    my $conn = shift( @_ );
                    my $hash = { code => 200, type => 'user', message => "Hello" };
                    my $json = $j->encode( $hash );
                    $conn->send_utf8( $json );
                },
                utf8 => sub
                {
                    my( $conn, $msg ) = @_;
                    # $conn->send_utf8( $msg );
                    print( "Received message: '$msg'\n" );
                },
                disconnect => sub
                {
                    my( $conn, $code, $reason ) = @_;
                    print( "Client diconnected from ip '", $conn->ip, "'\n" );
                },
            );
        },
    ) || die( WebSocket::Server->error );
    $ws->start || die( $ws->error );
}

__END__

