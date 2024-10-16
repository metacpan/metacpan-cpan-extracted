#!/usr/bin/env perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use_ok( 'WebSocket::Response' );

my $res;

$res = WebSocket::Response->new( debug => $DEBUG );
my $rv = $res->parse( "foo\x0d\x0a" );
ok( !defined( $rv ), 'bad response lines' );
is( $res->error->message => 'Wrong response line. Got "foo", but expected something starting with "HTTP/1.1 101 "', 'bad response error' );

$res = WebSocket::Response->new( debug => $DEBUG );
$rv = $res->parse( ( "1234567890" x 10 ) . "\x0d\x0a" );
ok( !defined( $rv ), 'bad response line (2)' );
my $err = $res->error;
# is( $res->error->message => 'Wrong response line. Got "12345678901234567890123456789012345678901234567890123456789012345678901234567...", but expected something starting with "HTTP/1.1 101 "', 'bad response error (2)' );
is( $err->message => 'Wrong response line. Got "12345678901234567890123456789012345678901234567890123456789012345678901234567...", but expected something starting with "HTTP/1.1 101 "', 'bad response error (2)' );

local $WebSocket::Common::MAX_MESSAGE_SIZE = 1024;

$res = WebSocket::Response->new( debug => $DEBUG );
$rv = $res->parse( 'x' x ( 1024 * 10 ) );
ok( !defined( $rv ), 'response data too big' );
diag( "Return value is '${rv}'" ) if( defined( $rv ) );
is( $res->error->message => 'Message is too long', 'response lines too big error' );

done_testing();

__END__

