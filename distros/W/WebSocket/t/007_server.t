#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test2::IPC;
    use Test2::V0;
    # use Test::More;
    use ok( 'WebSocket::Handshake::Client' ) || bail_out( "Unable to load WebSocket::Handshake::Client" );
    use ok( 'WebSocket::Frame' ) || bail_out( "Unable to load WebSocket::Frame" );
    use ok( 'IO::Socket::INET' ) || bail_out( "Unable to load IO::Socket::INET" );
    use ok( 'WebSocket::Server' ) || bail_out( "Unable to load WebSocket::Server" );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

my $child;
sub cleanup
{
    kill( 9 => $child ) if( $child && $child > 0 );
}

$SIG{ALRM} = sub
{
    cleanup();
    die( "test timed out\n" );
};
alarm(10);
# Supported WebSocket protocols
my $proto = 'test protocol';

my $listen = IO::Socket::INET->new(
    Listen => 2,
    Proto => 'tcp',
    Timeout => 5,
) or bail_out( "Unable to create tcp socket: $!" );

sub accursed_win32_pipe_simulation
{
    my $listen = IO::Socket::INET->new(
        Listen => 2,
        Proto => 'tcp',
        Timeout => 5,
        Blocking => 0,
    ) or die( "$!" );
    my $port = $listen->sockport;
    my $a = IO::Socket::INET->new(
        PeerPort => $port,
        Proto => 'tcp',
        PeerAddr => '127.0.0.1',
        Blocking => 0,
    ) or die( "failed to connect to 127.0.0.1: $!" );
    my $b = $listen->accept;
    $a->blocking(1);
    $b->blocking(1);
    return( $a, $b );
}

my( $read_test_out, $read_test_in, $write_test_out, $write_test_in );
if( $^O eq 'MSWin32' || $^O eq 'cygwin' )
{
    ( $read_test_out, $read_test_in ) = accursed_win32_pipe_simulation();
    ( $write_test_out, $write_test_in ) = accursed_win32_pipe_simulation();
}
else
{
    pipe( $read_test_out, $read_test_in );
    pipe( $write_test_out, $write_test_in );
}

$read_test_in->autoflush(1);
$write_test_in->autoflush(1);
$write_test_in->blocking(0);
#fill write pipe so it's not ready for writing yet
my $write_pipe_size = 0;
while(1)
{
    my $w = syswrite( $write_test_in, "a" x 1024 );
    $write_pipe_size += $w if( defined( $w ) );
    last if( !defined( $w ) || $w < 1024 );
}
$write_test_in->blocking(1);

my( $port, $sock );
$port = $listen->sockport;
my $origin = "http://localhost:${port}";

unless( $child = fork )
{
    delete( $SIG{ALRM} );

    my $ws = WebSocket::Server->new(
        debug  => $DEBUG,
        listen => $listen,
        subprotocol => $proto,
        watch_readable => [
            $read_test_out => sub
            {
                my( $serv, $fh ) = @_;
                my $data;
                sysread( $fh, $data, 1 );
                $_->send_binary( "read_test_out(" . length( $data ) . ") = $data" ) for( $serv->connections );
                $serv->unwatch_readable( $fh );
            },
        ],
        watch_writable => [
            $write_test_in => sub
            {
                my( $serv, $fh ) = @_;
                syswrite( $fh, "W" );
                $serv->unwatch_writable( $fh );
            },
        ],
        on_connect => sub
        {
            my( $serv, $conn ) = @_;
            diag( "SERVER: Received connection from client on ip '", $conn->ip, "' and port '", $conn->port, "'." ) if( $DEBUG );
            $conn->on(
                handshake => sub
                {
                    my( $conn, $hs ) = @_;
                    diag( "SERVER: Received handshake from client on ip '", $conn->ip, "' and port '", $conn->port, "': ", $hs->as_string ) if( $DEBUG );
                    die( "Bad handshake origin: " . $hs->request->origin ) unless( $hs->request->origin eq $origin );
                    die( "Bad subprotocol: " . $hs->request->subprotocol->join( ',' )->scalar ) unless( $hs->request->subprotocol->join( ' ' )->scalar eq 'test subprotocol' );
                },
                ready => sub
                {
                    my( $conn ) = @_;
                    diag( "SERVER: Connection established with client on ip '", $conn->ip, "' and port '", $conn->port, "'." ) if( $DEBUG );
                    my $rv = $conn->send_binary( "ready" );
                    diag( "Error trying to send a binary message on ready: ", $conn->error ) if( !defined( $rv ) && $DEBUG );
                },
                utf8 => sub
                {
                    my( $conn, $msg ) = @_;
                    diag( "SERVER: Received from client message -> '", ( length( $msg ) > 1024 ? substr( $msg, 0, 1024 ) . '...' : $msg ), "'" ) if( $DEBUG );
                    my $rv = $conn->send_utf8( "utf8(" . length( $msg ) . ") = $msg" );
                    diag( "Error trying to send a binary message: ", $conn->error ) if( !defined( $rv ) && $DEBUG );
                },
                binary => sub
                {
                    my( $conn, $msg ) = @_;
                    diag( "SERVER: Received from client binary -> '", ( length( $msg ) > 1024 ? substr( $msg, 0, 1024 ) . '...' : $msg ), "'" ) if( $DEBUG );
                    my $rv = $conn->send_binary( "binary(" . length( $msg ) . ") = $msg" );
                    diag( "Error trying to send a binary message: ", $conn->error ) if( !defined( $rv ) && $DEBUG );
                },
                pong => sub
                {
                    my( $conn, $msg ) = @_;
                    diag( "SERVER: Received from client ping -> '", ( length( $msg ) > 1024 ? substr( $msg, 0, 1024 ) . '...' : $msg ), "'" ) if( $DEBUG );
                    my $rv = $conn->send_binary( "pong(" . length( $msg ) .") = $msg" );
                    diag( "Error trying to send a binary message on pong: ", $conn->error ) if( !defined( $rv ) && $DEBUG );
                },
                disconnect => sub
                {
                    my( $conn, $code, $reason ) = @_;
                    diag( "SERVER: Client disconnecting with code '$code' and reason '$reason'" ) if( $DEBUG );
                    die( "bad disconnect code \"$code\" with reason \"$reason\"" ) unless( defined( $code ) && $code == 4242 );
                    die( "bad disconnect reason" ) unless( defined( $reason ) && $reason eq 'test server shutdown cleanly' );
                    $serv->shutdown();
                },
            );
        },
    ) || die( WebSocket::Server->error );
    diag( "Web socket object is: $ws" ) if( $DEBUG );
    $ws->start;

    exit;
}

subtest "initialize client socket" => sub
{
    $sock = IO::Socket::INET->new(
        PeerPort => $port,
        Proto    => 'tcp',
        PeerAddr => '127.0.0.1'
    ) or die "failed to connect to 127.0.0.1: $!";
    ok( $sock );
};

my $buf = '';
my $hs;

subtest "handshake send" => sub
{
    SKIP:
    {
        skip( "No client socket could be created.", 1 ) if( !$sock );
        $hs = WebSocket::Handshake::Client->new( debug => $DEBUG, uri => "ws://localhost:${port}/testserver" );
        $hs->request->subprotocol( "test subprotocol" );
        my $handshake = $hs->as_string;
        diag( "Error getting the handshake data: ", $hs->error ) if( !defined( $handshake ) && $DEBUG );
        diag( "Sending handshake to server:\n", $hs->as_string ) if( $DEBUG );
        # ok( print( $sock $hs->as_string ), 'sending handshake on socket' );
        ok( $sock->syswrite( $hs->as_string ), 'sending handshake on socket' );
    };
};

subtest "handshake recv" => sub
{
    SKIP:
    {
        skip( "No client socket could be created.", 1 ) if( !$sock );
        diag( "Reading 8192 bytes from socket." ) if( $DEBUG );
        while( $sock->sysread( $buf, 8192, length( $buf ) ) )
        {
            diag( "Parsing data received from server -> '$buf'" ) if( $DEBUG );
            $hs->parse( $buf );
            last if( $hs->is_done );
        }
        diag( "Handshake error occurred: ", $hs->error ) if( $hs->error && $DEBUG );
        ok( !$hs->error, "completed handshake with server without error" );
    };
};

my $frame;
# Need to empty the buffer
$buf = '';

subtest "initialize frame" => sub
{
    $frame = WebSocket::Frame->new( debug => $DEBUG );
    ok( $frame->append( $buf ), 'appending data to frame' );
};

subtest "ready message" => sub
{
    SKIP:
    {
        skip( "No client socket could be created.", 1 ) if( !$sock );
        my $bytes = _recv( $sock => $frame );
        
        ok( defined( $bytes ), 'socket read' );
        skip( 'failed to read from socket', 2 ) if( !defined( $bytes ) );
        ok( $frame->is_binary, "expected binary message" );
        is( $bytes, "ready", "expected welcome 'ready' message" );
    };
};

subtest "echo utf8" => sub
{
    SKIP:
    {
        skip( "No client socket could be created.", 15 ) if( !$sock );
        foreach my $msg ( "simple", "", ( "a" x 32768 ), "unicode \u2603 snowman", "hiragana \u3072\u3089\u304c\u306a null \x00 ctrls \cA \cF \n \e del \x7f end" )
        {
            $sock->syswrite( WebSocket::Frame->new( debug => $DEBUG, type => 'text', buffer => $msg )->to_bytes );
            my $bytes = _recv( $sock => $frame );
            ok( defined( $bytes ), 'socket read' );
            SKIP:
            {
                skip( 'failed to read from socket', 2 ) if( !defined( $bytes ) );
                ok( $frame->is_text, "expected text message" );
                is( $bytes, "utf8(" . length( $msg ) . ") = $msg" );
            };
        }
    };
};

subtest "echo binary" => sub
{
    SKIP:
    {
        skip( "No client socket could be created.", 15 ) if( !$sock );
        foreach my $msg ( "simple", "", ( "a" x 32768 ), "unicode \u2603 snowman", "hiragana \u3072\u3089\u304c\u306a null \x00 ctrls \cA \cF \n \e del \x7f end", join( "", map{ chr( $_ ) } 0..255 ) )
        {
            $sock->syswrite( WebSocket::Frame->new( debug => $DEBUG, type => 'binary', buffer => $msg )->to_bytes );
            my $bytes = _recv( $sock => $frame );
            ok( defined( $bytes ), 'socket read' );
            SKIP:
            {
                skip( 'failed to read from socket', 2 ) if( !defined( $bytes ) );
                ok( $frame->is_binary, "expected binary message" );
                is( $bytes, "binary(" . length( $msg ) . ") = $msg" );
            };
        }
    };
};

subtest "echo pong" => sub
{
    SKIP:
    {
        skip( "No client socket could be created.", 15 ) if( !$sock );
        foreach my $msg ( "simple", "", ( "a" x 32768 ), "unicode \u2603 snowman", "hiragana \u3072\u3089\u304c\u306a null \x00 ctrls \cA \cF \n \e del \x7f end", join( "", map{ chr( $_ ) } 0..255 ) )
        {
            $sock->syswrite( WebSocket::Frame->new( debug => $DEBUG, type => 'pong', buffer => $msg )->to_bytes );
            my $bytes = _recv( $sock => $frame );
            ok( defined( $bytes ), 'socket read' );
            SKIP:
            {
                skip( 'failed to read from socket', 2 ) if( !defined( $bytes ) );
                ok( $frame->is_binary, "expected binary message" );
                is( $bytes, "pong(" . length( $msg ) . ") = $msg" );
            };
        }
    };
};

subtest "watch_readable" => sub
{
    SKIP:
    {
        skip( "No client socket could be created.", 3 ) if( !$sock || !$read_test_in );
        $read_test_in->syswrite( "R" );
        my $bytes = _recv( $sock => $frame );
        ok( defined( $bytes ), 'socket read' );
        skip( 'failed to read from socket', 2 ) if( !defined( $bytes ) );
        ok( $frame->is_binary, "expected binary message" );
        is( $bytes, "read_test_out(1) = R" );
    };
};

subtest "watch_writable" => sub
{
    SKIP:
    {
        skip( "No client socket could be created.", 1 ) if( !$sock || !$write_test_out );
        my( $bytes_read, $scratch, $value );
        my $timeout = 0;
        local $SIG{ALRM} = sub{ $timeout++ };
        alarm(1);
        while( !$timeout && $write_pipe_size )
        {
            $bytes_read = $write_test_out->sysread( $scratch, $write_pipe_size > 8192 ? 8192 : $write_pipe_size );
            bail_out( "watch_writable sysread: $!" ) unless( defined( $bytes_read ) );
            $write_pipe_size -= $bytes_read;
        }
        if( $timeout )
        {
            warn( "Timeout trying to read from socket!\n" );
            fail( 'Timeout trying to read from socket' );
        }
        else
        {
            alarm(0);
            $write_test_out->sysread( $value, 1 );
            is( $value, "W" );
        }
    };
};

subtest "server shutdown" => sub
{
    SKIP:
    {
        skip( "No client socket could be created.", 1 ) if( !$sock );
        ok( kill( 0 => $child ), "child should still be alive" );
        $sock->syswrite( WebSocket::Frame->new( debug => $DEBUG, type => 'close', buffer => pack( "n", 4242 ) . "test server shutdown cleanly" )->to_bytes );
        waitpid( $child, 0 );
        ok( !kill( 0 => $child ), "child should have shut down cleanly" );
    };
};

done_testing();

cleanup();

sub _recv
{
    my( $sock, $frame ) = @_;
    diag( "CLIENT: Trying to get next bytes." ) if( $DEBUG );
    diag( "CLIENT: is connected? ", $sock->connected ? 'yes' : 'no' ) if( $DEBUG );
    my $timeout = 0;
    local $SIG{ALRM} = sub{ $timeout++ };
    alarm(2);
    my $message;
    while( !$timeout && !defined( $message = $frame->next_bytes ) )
    {
        my $data;
        die( $frame->error ) if( $frame->error );
        unless( defined( $sock->sysread( $data, 8192 ) ) )
        {
            die( "CLIENT: expected read but socket seems to be disconnected" );
        }
        # diag( "Appending data to frame: '$data'" ) if( $DEBUG );
        $frame->append( $data );
    }
    alarm(0);
    if( $timeout && !$message )
    {
        warn( "CLIENT: timeout trying to read from socket!\n" );
        return;
    }
    # diag( "next_bytes returned message '$message'" ) if( $DEBUG );
    return( $message );
}

