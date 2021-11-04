#!/usr/local/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use open ':std' => ':utf8';
    use WebSocket::Client;
    our $DEBUG = 3;
};

{
    # ws://localhost:8080?csrf=token
    my $uri = shift( @ARGV ) || die( "$0 uri\n" );
    my $ws  = WebSocket::Client->new( $uri,
    {
        on_binary       => \&on_binary,
        on_disconnect   => \&on_disconnect,
        on_connect      => \&on_connect,
        on_error        => \&on_error,
        on_utf8         => \&on_message,
        on_send         => \&on_send,
        origin          => 'http://localhost',
        debug       =   > $DEBUG,
    }) || die( WebSocket::Client->error );
    print( "Client object initiated. Now trying to start connecting.\n" );
    $ws->connect() || die( $ws->error );

    my $stdin = AnyEvent::Handle->new(
        fh      => \*STDIN,
        on_read => sub
        {
            my $handle = shift( @_ );
            my $buf = delete( $handle->{rbuf} );
            $ws->send_utf8( $buf );
        },
        on_eof => sub
        {
            $ws->disconnect;
            # $ws_handle->destroy;
            # $cv->send;
        }
    );
}

sub on_binary
{
    my( $client, $message ) = @_;
}

sub on_disconnect
{
    my $client = shift( @_ );
    print( "Connection got closed\n" );
}

sub on_connect
{
    my $client = shift( @_ );
    print( "Connection established\n" );
}

sub on_error
{
    my( $client, $error ) = @_;
    print( "Error detected: $error\n" );
}

sub on_message
{
    my( $client, $message ) = @_;
    print( "Message received:\n$message\n" );
}

sub on_send
{
    my( $client, $message ) = @_;
    print( "Sending message '$message'\n" );
}

__END__

