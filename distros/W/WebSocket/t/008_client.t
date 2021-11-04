#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use IO::Socket::INET;
    use POSIX qw( WNOHANG WIFEXITED WEXITSTATUS WIFSIGNALED );
    use Test::More;
    use Module::Generic::File qw( tempfile );
    use URI;
    use WebSocket::Server;
    use WebSocket::Client;
    use warnings qw( WebSocket::Server WebSocket::Client );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

my $origin = URI->new( 'http://localhost' );
my $proto = 'test protocol';
my( $ws, $socket, $pid ) = &init_server;
sleep(1); # Give some time for the server to start
$SIG{__DIE__} = $SIG{INT} = sub
{
    kill( 'TERM', $pid );
};
# We let perl handle itself the reaping of the child process
$SIG{CHLD} = 'IGNORE';
my $port = $socket->sockport;
my $uri = "ws://localhost:${port}";
diag( "Using connection uri '$uri'" ) if( $DEBUG );

subtest 'new' => sub
{
    my $client = WebSocket::Client->new( uri => $uri, origin => $origin, subprotocol => $proto, debug => $DEBUG );
    if( !defined( $client ) )
    {
        diag( "Error instantiating a WebSocket client: ", WebSocket::Client->error ) if( $DEBUG );
    }
    isa_ok( $client, 'WebSocket::Client' );
};

subtest 'write handshake on connect' => sub
{
    my $client = WebSocket::Client->new( uri => $uri, origin => $origin, subprotocol => $proto, debug => $DEBUG );
    SKIP:
    {
        my $written = '';
        if( !defined( $client ) )
        {
            diag( "CLIENT: Error instantiating a WebSocket client: ", WebSocket::Client->error ) if( $DEBUG );
            fail( 'Cannot instantiate client' );
            skip( 'Failed to instantiate client', 1 );
        }
        else
        {
            $client->on( send => sub
            {
                diag( "CLIENT: Sending data: '", join( "', '", @_ ), "'" ) if( $DEBUG );
                $written .= $_[1]
            }) || do
            {
                diag( "Error trying to set the \"send\" callback: ", $client->error ) if( $DEBUG );
            };
            
            my $rv = $client->connect;
            diag( "CLIENT: Connect error: ", $client->error ) if( !defined( $rv ) && $DEBUG );
        }
        like( $written, qr/Upgrade: WebSocket/ );
        $client->disconnect if( $client );
    };
};

subtest 'callback on handshake' => sub
{
    my $client = WebSocket::Client->new( uri => $uri, origin => $origin, subprotocol => $proto, debug => $DEBUG );
    SKIP:
    {
        my $connected;
        if( !defined( $client ) )
        {
            diag( "CLIENT: Error instantiating a WebSocket client: ", WebSocket::Client->error ) if( $DEBUG );
            fail( 'Cannot instantiate client' );
            skip( 'Failed to instantiate client', 1 );
        }
        else
        {
            $client->on( send => sub { });

            $client->on( handshake => sub
            {
                diag( "on_handshake called." ) if( $DEBUG );
                $connected++;
                # Must return true
                return(1);
            }) || do
            {
                diag( "Error trying to set the \"handshake\" callback: ", $client->error ) if( $DEBUG );
            };
            my $rv = $client->connect;
            diag( "CLIENT: Connect error: ", $client->error ) if( !defined( $rv ) && $DEBUG );
        }
        ok( $connected );
        $client->disconnect if( $client );
    };
};

subtest 'callback on new data received' => sub
{
    SKIP:
    {
        # if( !Module::Generic::File::HAS_PERLIO_MMAP && !eval( 'require File::Map' ) )
        if( !eval( 'require File::Map' ) )
        {
            skip( 'mmap not available on this machine', 1 );
        }
        
        # XXX
        my $file = tempfile({ unlink => 0, debug => $DEBUG + 2, use_file_map => 1 });
        $file->mmap( my $read, 2048, '+<' ) || do
        {
            diag( "Error trying to create a mmap: ", $file->error );
        };
        $read = '';
    
        my $client = WebSocket::Client->new( uri => $uri, origin => $origin, subprotocol => $proto, debug => $DEBUG );
        if( !defined( $client ) )
        {
            diag( "CLIENT: Error instantiating a WebSocket client: ", WebSocket::Client->error ) if( $DEBUG );
            fail( 'Cannot instantiate client' );
            skip( 'Failed to instantiate client', 1 );
        }
        else
        {
            $client->on( send => sub{ }) || do
            {
                diag( "Error trying to set the \"send\" callback: ", $client->error ) if( $DEBUG );
            };
            $client->on( recv => sub
            {
                diag( "Got here with data received: '$_[1]'" ) if( $DEBUG );
                $read = $_[1];
                diag( "\$read is now '$read'" ) if( $DEBUG );
            }) || do
            {
                diag( "Error trying to set the \"recv\" callback: ", $client->error ) if( $DEBUG );
            };

            my $rv = $client->connect;
            diag( "CLIENT: Connect error: ", $client->error ) if( !defined( $rv ) && $DEBUG );
            my $len = $client->send( 'hello' );
            diag( "CLIENT: send error: ", $client->error ) if( !defined( $len ) && $DEBUG );
        }
        # wait for the server response
        sleep(2);
        # Server is instructed to send back what he received
        # $read = unpack( 'a*', $read );
        $read =~ s/\0*$//g;
        diag( "\$read is -> ", $client->dump_hex( $read ) ) if( $DEBUG );
        is( $read, 'hello' );
        $client->disconnect if( $client );
    };
};

subtest 'call on_close on disconnect' => sub
{
    my $client = WebSocket::Client->new( uri => $uri, origin => $origin, subprotocol => $proto, debug => $DEBUG );
    SKIP:
    {
        my $written = '';
        if( !defined( $client ) )
        {
            diag( "CLIENT: Error instantiating a WebSocket client: ", WebSocket::Client->error ) if( $DEBUG );
            fail( 'Cannot instantiate client' );
            skip( 'Failed to instantiate client', 1 );
        }
        else
        {
            $client->on( disconnect => sub{ $written .= 'disconnected' }) || do
            {
                diag( "Error trying to set the \"disconnect\" callback: ", $client->error ) if( $DEBUG );
            };
            $client->disconnect;
        }
        is( $written, "disconnected" );
    };
};

subtest 'max_payload_size passed to frame buffer' => sub
{
    is( WebSocket::Client->new( uri => $uri )->frame_buffer->max_payload_size, 65536, 'default' );
    is( WebSocket::Client->new( uri => $uri, max_payload_size => 22 )->frame_buffer->max_payload_size, 22, 'set to 22' );
    is( WebSocket::Client->new( uri => $uri, max_payload_size => 0 )->frame_buffer->max_payload_size, 0, 'set to 0' );
    is( WebSocket::Client->new( uri => $uri, max_payload_size => undef )->frame_buffer->max_payload_size, 65536, 'set to undef' );
};

$ws->shutdown;
# diag( "Sending kill TERM to child process $pid" ) if( $DEBUG );
# kill( 'QUIT' => $pid ) if( $pid );

sub init_server
{
    diag( "Starting server..." ) if( $DEBUG );
    # Block signal for fork
    my $sigset = POSIX::SigSet->new( POSIX::SIGINT );
    POSIX::sigprocmask( POSIX::SIG_BLOCK, $sigset ) || die( "Cannot block SIGINT for fork: $!" );
    my $listen = IO::Socket::INET->new(
        Listen => 2,
        Proto => 'tcp',
        Timeout => 5,
        Reuse => 1,
    ) or die( "$!" );

    my $ws = WebSocket::Server->new(
        debug  => $DEBUG,
        subprotocol => $proto,
        listen => $listen,
        on_connect => sub
        {
            my( $serv, $conn ) = @_;
            $conn->on(
                handshake => sub
                {
                    my( $conn, $hs ) = @_;
                    my $orig = URI->new( $hs->request->origin );
                    diag( "SERVER: Handshake received from origin $orig" ) if( $DEBUG );
                    diag( "Bad handshake origin: $orig vs expected '$origin'" ) unless( $orig->host eq $origin->host );
                    diag( "Bad subprotocol: " . $hs->request->subprotocol->join( ' ' ) ) unless( $hs->request->subprotocol->join( ' ' ) eq 'test protocol' );
                },
                ready => sub
                {
                    my( $conn ) = @_;
                    # $conn->send_binary( "ready" );
                },
                utf8 => sub
                {
                    my( $conn, $msg ) = @_;
                    diag( "SERVER: Text message received -> $msg" ) if( $DEBUG );
                    $conn->send_utf8( $msg );
                },
                binary => sub
                {
                    my( $conn, $msg ) = @_;
                    diag( "SERVER: Binary message received -> $msg" ) if( $DEBUG );
                    $conn->send_binary( $msg );
                },
                pong => sub
                {
                    my( $conn, $msg ) = @_;
                    diag( "Ping received -> $msg" ) if( $DEBUG );
                    $conn->send_binary( 'pong' );
                },
                disconnect => sub
                {
                    my( $conn, $code, $reason ) = @_;
                    diag( "SERVER: Closing connection with code '$code' and reason '$reason'" ) if( $DEBUG );
                    $conn->shutdown();
                },
            );
        },
    ) || die( WebSocket::Server->error );
    diag( "Web socket object is: $ws" ) if( $DEBUG );
    
    my $child = fork();
    if( $child )
    {
        diag( "Listening on ip '", $listen->sockhost, "' on port '", $listen->sockport, "' with pid '$child'." ) if( $DEBUG );
        POSIX::sigprocmask( POSIX::SIG_UNBLOCK, $sigset ) || die( "Cannot unblock SIGINT for fork: $!" );
        local $SIG{CHLD} = sub
        {
            while( ( my $child = waitpid( -1, POSIX::WNOHANG ) ) > 0 )
            {
                diag( 3, "Listner child process ($child) has terminated." ) if( $DEBUG );
                diag( 3, "Exit value: ", ( $? >> 8 ) ) if( $DEBUG );
                diag( 3, "Signal: ", ( $? & 127 ) ) if( $DEBUG );
                diag( 3, "Has core dump? ", ( $? & 128 ) ) if( $DEBUG );
            }
        };
        
        # Is the child still there?
#         if( kill( 0 => $child ) || $!{EPERM} )
#         {
#             diag( "Child process with pid '$child' is still running, waiting for it to complete." ) if( $DEBUG );
#             # Blocking wait
#             my $pid = waitpid( $child, POSIX::WNOHANG );
#             my $exit_val = ( $? >> 8 );
#             my $exit_sig = ( $? & 127 );
#             if( WIFEXITED($?) )
#             {
#                 diag( "Child with pid '$child' exited with bit value '$?', exit value '$exit_val' and possibly with signal '$exit_sig'" ) if( $DEBUG );
#             }
#             elsif( $pid == -1 )
#             {
#                 diag( "No child process with pid $child." ) if( $DEBUG );
#             }
#             else
#             {
#                 diag( "Child with pid '$child' exited with bit value '$?', exit value '$exit_val' and possibly with signal '$exit_sig' -> $!" ) if( $DEBUG );
#             }
#         }
#         else
#         {
#             diag( "Child process with pid '$child' is already completed." ) if( $DEBUG );
#         }
    }
    elsif( $child == 0 )
    {
        delete( $SIG{ALRM} );
        diag( "Starting Web Socket server." ) if( $DEBUG );
        $ws->start;
        diag( "Exiting child $$" ) if( $DEBUG );
        exit(0);
    }
    else
    {
        my $err;
        if( $! == POSIX::EAGAIN() )
        {
            $err = "fork cannot allocate sufficient memory to copy the parent's page tables and allocate a task structure for the child.";
        }
        elsif( $! == POSIX::ENOMEM() )
        {
            $err = "fork failed to allocate the necessary kernel structures because memory is tight.";
        }
        else
        {
            $err = "Unable to fork a new process to execute promised code: $!";
        }
        diag( "Error occurred: $err" ) if( $DEBUG );
        die( $err );
    }
    return( $ws, $listen, $child );
}

done_testing();

__END__

