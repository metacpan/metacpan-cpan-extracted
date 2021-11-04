#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use_ok( 'WebSocket::Frame' );

is( WebSocket::Frame->new->max_payload_size, 65536, 'default max_payload_size' );
is( WebSocket::Frame->new( max_payload_size => 22 )->max_payload_size, 22, 'override max_payload_size' );
is( WebSocket::Frame->new( max_payload_size => 0 )->max_payload_size, 0, 'turn off max_payload_size' );

subtest 'payload too large (to_bytes)' => sub
{
    my $frame = WebSocket::Frame->new( debug => $DEBUG, buffer => 'x' x 65537 );
    my $rv = $frame->to_bytes;
    ok( !defined( $rv ), 'to_bytes failed' );
    like( $frame->error, qr/Payload is too big\. Send shorter messages or increase max_payload_size/, 'to_bytes returned an error' );
};

subtest 'payload larger than 65536, but under max (to_bytes)' => sub
{
    my $frame = WebSocket::Frame->new(
        buffer           => 'x' x 65537,
        max_payload_size => 65537
    );
    $frame->to_bytes;
    is( $frame->error, undef, 'Payload is below threshold. No error' );
};

subtest 'turn off payload size checking (to_bytes)' => sub
{
    my $frame = WebSocket::Frame->new(
        buffer           => 'x' x 65537,
        max_payload_size => 0
    );
    $frame->to_bytes;
    is( $frame->error, undef, 'Payload threshold if turned off. No error' );
};

my $large_frame = WebSocket::Frame->new( buffer => 'x' x 65537, max_payload_size => 0 );

subtest 'payload too large (next_bytes)' => sub
{
    my $frame = WebSocket::Frame->new( debug => $DEBUG );
    $frame->append( $large_frame->to_bytes );
    my $rv = $frame->next_bytes;
    ok( !defined( $rv ), 'next_bytes returned an error' );
    like( $frame->error, qr/Payload is too big\. Deny big message/, 'next_bytes returned an error' );
};

subtest 'payload larger than 65536, but under max (next_bytes)' => sub
{
    my $frame = WebSocket::Frame->new( max_payload_size => 65537 );
    $frame->append( $large_frame->to_bytes );
    eval{ $frame->next_bytes };
    is( $@, '' );
};

subtest 'turn off payload size checking (next_bytes)' => sub
{
    my $frame = WebSocket::Frame->new( max_payload_size => 0 );
    $frame->append( $large_frame->to_bytes );
    $frame->next_bytes;
    is( $frame->next_bytes, undef, 'Payload threshold if turned off. No error' );
};

my $first_fragment = WebSocket::Frame->new( buffer => 'x', type => 'text', fin => 0 );
my $a_fragment = WebSocket::Frame->new( buffer => 'x', type => 'continuation', fin => 0 );

subtest 'maximum number or fragments exceeded' => sub
{
    local $WebSocket::Frame::MAX_FRAGMENTS_AMOUNT = 42;
    my $frame = WebSocket::Frame->new();
    is( $frame->{max_fragments_amount}, 42, 'maximum number of fragments set to 42' );

    $frame->append( $first_fragment->to_bytes );
    $frame->append( $a_fragment->to_bytes ) for( 1 .. $frame->max_fragments_amount );

    $frame->next_bytes;
    like( $frame->error, qr/Too many fragments/, 'next_bytes return error with too many fragments' );
};

subtest 'frame opcode' => sub
{
    for( qw( continuation text binary ping pong close ) )
    {
        diag( "Checking opcode in and out value for $_" ) if( $DEBUG );
        my $frame_out = WebSocket::Frame->new( masked => 1, version => 13, type => $_, debug => $DEBUG );
        if( !defined( $frame_out ) )
        {
            diag( "Error instantiating WebSocket::Frame object: ", WebSocket::Frame->error ) if( $DEBUG );
            fail( $_ );
            next;
        }
        my $bytes_out = $frame_out->to_bytes;
        is( $frame_out->opcode, $WebSocket::Frame::TYPES->{ $_ }, "opcode value out for $_" );
        if( !defined( $bytes_out ) )
        {
            diag( "Error getting bytes: ", $frame_out->error ) if( $DEBUG );
            fail( $_ );
            next;
        }
        my $frame_in = WebSocket::Frame->new( buffer => $bytes_out, debug => $DEBUG );
        my $bytes_in = $frame_in->next_bytes;
        is( $frame_in->opcode, $frame_out->opcode, "opcode value in for $_" );
    }
    my $hello_out = WebSocket::Frame->new( masked => 1, version => 13, type => 'text', buffer => 'Hello', debug => $DEBUG )->to_bytes;
    my $hello_in  = WebSocket::Frame->new( buffer => $hello_out, debug => $DEBUG )->next_bytes;
    is( 'Hello', $hello_in, 'text frame value' );
};

done_testing();

__END__

