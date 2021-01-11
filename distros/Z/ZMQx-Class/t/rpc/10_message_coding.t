use strict;
use warnings;
use 5.014;

use Test::Most;
use ZMQx::RPC::Message;
use ZMQx::RPC::Header;
use JSON::XS;
use Devel::Peek;

subtest 'String' => sub {

    my $header = ZMQx::RPC::Header->new( type => 'string' );
    my $msg = ZMQx::RPC::Message->new( header => $header );

    my $test = [ 'abc', chr(0x05d0) ];
    # explain($test);

    my $encoded = $msg->_encode_payload($test);
    # explain($encoded);

    my $decoded = $msg->_decode_payload($encoded);
    # explain($decoded);

    cmp_deeply( $test, $decoded, "Payload matches initial / enjoying perl unicode" );
    utf8::upgrade($_) foreach ( @$test );
    cmp_deeply( $test, $decoded, "Payload matches initial / real match" );

};
subtest 'Raw' => sub {

    my $header = ZMQx::RPC::Header->new( type => 'raw' );
    my $msg = ZMQx::RPC::Message->new( header => $header );

    my $test = [ 'abc', chr(0x05d0) ];
    my $raw = encode_json($test);

    my $encoded = $msg->_encode_payload( [$raw] );
    # explain($encoded);

    my $decoded = $msg->_decode_payload($encoded);
    # explain($decoded);

    my $returned = decode_json( $decoded->[0] );
    cmp_deeply( $test, $returned, "Payload matches initial" );

};

subtest 'JSON' => sub {

    my $header = ZMQx::RPC::Header->new( type => 'JSON' );
    my $msg = ZMQx::RPC::Message->new( header => $header );

    my $test = [ [ 'abc', chr(0x05d0) ] ];
    # explain($test);

    my $encoded = $msg->_encode_payload($test);
    # explain($encoded);

    my $decoded = $msg->_decode_payload($encoded);
    # explain($decoded);

    cmp_deeply( $test, $decoded, "Payload matches initial" );

};

done_testing();

1;

