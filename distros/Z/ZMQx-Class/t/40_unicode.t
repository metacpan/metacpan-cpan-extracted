use strict;
use warnings;

use Test::More;
use utf8;
use Encode qw/decode_utf8 encode/;

use ZMQx::Class;
use ZMQ::Constants qw/:all/;

my $endpoint = "ipc:///tmp/test-zmqx-class-$$";

my $ctx = ZMQx::Class->context();

my $q = ZMQx::Class->socket($ctx, 'REQ', bind => $endpoint );
my $p = ZMQx::Class->socket($ctx, 'REP', connect => $endpoint );

my $pack_template = 'u*';

my $msg_latin = encode('iso-8859-1', decode_utf8( 'Can I use £?' ));
ok( !utf8::is_utf8($msg_latin), "This is a latin-1 message" );

my $msg_utf8  = 'werde ich von Dir hören?';
ok( utf8::is_utf8($msg_utf8), "This is a unicode message" );


my $count = 0;
foreach my $loop_msg ( $msg_latin, $msg_utf8 ) {

    diag("Message: $loop_msg");
    $count++;

    subtest 'send_bytes_' . $count => sub {

        my $msg = $loop_msg;

        $q->send( $msg, ZMQ_DONTWAIT );

        my $delivered    = $p->receive(1);
        my $compare_with = $delivered->[0];

        {
            use bytes;
            is( length($compare_with), length($msg), "Same number of bytes" );
            is( unpack( $pack_template, $compare_with ),
                unpack( $pack_template, $msg ),
                "Byte identical"
            );
        }

        $p->send('thx');
        $q->receive(1);
    };

    subtest 'send_multipart_bytes_' .$count => sub {

        my $msg = $loop_msg;

        my $multipart = [ ($msg) x 3 ];

        $q->send( $multipart );

        my $delivered = $p->receive('block');

        is_deeply(
            [ map { unpack( $pack_template, $_ ) } @$delivered ],
            [ map { unpack( $pack_template, $_ ) } @$multipart ],

            "Oh yes, we're all just bytes"
        );

        $p->send('thx');
        $q->receive(1);
    };

    subtest 'recv_string_' . $count => sub {

        my $msg = $loop_msg;

        my $encoding = utf8::is_utf8( $msg ) ? 'utf-8' : 'latin-1';

        $q->send( $msg );

        my $delivered = $p->receive_string('block', $encoding);
        my $compare_with = $delivered->[0];
        is( $compare_with, $msg, "The strings are unicode and identical" );

        $p->send('thx');
        $q->receive(1);

    };

    subtest 'recv_multipart_string_' . $count => sub {

        my $msg = $loop_msg;

        my $multipart = [ ($msg) x 3 ];
        $q->send( $multipart, ZMQ_DONTWAIT );

        my $delivered = $p->receive_string(1);
        is_deeply( $delivered, $multipart, "Many unicode strings" );

        $p->send('thx');
        $q->receive(1);

    };

}

{
    # cleanup

    foreach ( $q, $p ) {
        $_->close();
    }

    $ctx->destroy();
}

done_testing();
