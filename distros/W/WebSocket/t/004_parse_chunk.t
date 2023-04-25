#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    # use Test::More tests => 22;
    use Test::More;
    use WebSocket::Common;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

# Test units borrowed from HTTP::Parser; credits to David Robins

BEGIN
{
    use_ok( 'WebSocket::Common', ':all' );
};

is( PARSE_DONE,        0, 'constant PARSE_DONE' );
is( PARSE_INCOMPLETE, -1, 'constant PARSE_INCOMPLETE' );
is( PARSE_WAITING,    -2, 'constant PARSE_WAITING' );
is( PARSE_MAYBE_MORE, -3, 'constant PARSE_MAYBE_MORE' );

my $parser = WebSocket::Common->new( debug => $DEBUG );
my @lines = ( 'GET / HTTP/1.1', 'Host: localhost', 'Upgrade: websocket', 'Connection: upgrade', '' );
my @ok = ( PARSE_WAITING, PARSE_WAITING, PARSE_WAITING, PARSE_WAITING, PARSE_DONE );

my $result;
# blank lines before Request-Line should be ignored
$parser->parse_chunk( "\x0a\x0a" );
for my $line ( @lines )
{
    $result = $parser->parse_chunk( "$line\x0d\x0a" );
    diag( "Error parsing chunk: ", $parser->error ) if( !defined( $result ) && $DEBUG );
    # diag( "Result is '$result'" ) if( $DEBUG );
    is( $result, shift( @ok ), "Passing '$line'" );
}

SKIP:
{
    if( $result )
    {
        skip( "Didn't get request object", 6 );
    }
    else
    {
        my $req = $parser->request;
        isa_ok( $req, 'WebSocket::Request' );

        is( $req->method(), 'GET', 'Method' );

        my $uri = $req->uri;
        isa_ok( $uri, 'URI' );
        is( $uri->path, '/', 'URI path' );

        my @head;
        $req->headers->scan(sub{ push( @head, [@_] ) }); 
        # diag( "Scanned headers are: ", WebSocket::Common->dump( \@head ) ) if( $DEBUG );
        ok( eq_set( \@head, [[Connection => 'upgrade'], [Upgrade => 'websocket'], [Host => 'localhost']] ), 'Headers' );
        is( $req->content, '', 'Content' );
    }
};

$parser = WebSocket::Common->new( debug => $DEBUG );
@lines = (
    'HTTP/1.1 101 Switching Protocols',
    'Server: Test/0.1',
    'Upgrade: websocket',
    'Connection: Upgrade',
    'Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=',
    'Sec-WebSocket-Protocol: chat',
    '',
    'Some content!'
);
@ok = ( PARSE_WAITING, PARSE_WAITING, PARSE_WAITING, PARSE_WAITING, PARSE_WAITING, PARSE_WAITING, PARSE_DONE, PARSE_DONE );

# parse response
$parser = WebSocket::Common->new( debug => $DEBUG );
for my $line ( @lines )
{
    $result = $parser->parse_chunk( "$line\x0d\x0a" );
    is( $result, shift( @ok ), "Passing '$line'" );
}

SKIP:
{
    if( $result )
    {
        skip( "Didn't get response object", 3 );
    }
    else
    {
        my $res = $parser->response;
        isa_ok( $res, 'WebSocket::Response' );
        is( $res->headers->header( 'upgrade' ), 'websocket', 'upgrade is correct' );
        is( $res->content, "Some content!\x0d\x0a", 'content is correct' );
    }
};

$parser = WebSocket::Common->new( debug => $DEBUG );
$parser->parse_chunk( "GET //foo///bar/baz HTTP/1.1\x0d\x0a\x0d\x0a" );
is( $parser->request->uri->path, '//foo///bar/baz' );

done_testing();

__END__

