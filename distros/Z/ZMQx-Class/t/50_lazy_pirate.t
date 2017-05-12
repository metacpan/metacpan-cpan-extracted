use strict;
use warnings;
use 5.010;

use Test::Most;
use File::Temp qw(tempfile);
use ZMQx::Class;

my $context = ZMQx::Class->context;

my ( $fh, $name ) = tempfile();
my $server =
    ZMQx::Class->socket( $context, 'ROUTER', bind => 'ipc://' . $name );
my $client1 =
    ZMQx::Class->socket( $context, 'REQ', connect => 'ipc://' . $name );

subtest 'basic' => sub {
    is( $client1->_can_send,          1, 'socket can send' );
    is( $client1->_message_available, 0, 'socket cannot receive' );

    $client1->send('aaa');

    is( $client1->_can_send,          0, 'socket cannot send' );
    is( $client1->_message_available, 0, 'socket cannot receive. huh?' );

    my $got = $server->receive(1);
    is( $got->[2], 'aaa', 'server got aaa' );
    $server->send( [ $got->[0], '', 'zzz' ] );

    is( $client1->_can_send,          0, 'socket cannot send' );
    is( $client1->_message_available, 1, 'socket can receive' );

    my $rep = $client1->receive(1);

    is( $client1->_can_send,          1, 'socket can send' );
    is( $client1->_message_available, 0, 'socket cannot receive' );

    is( $rep->[0], 'zzz', 'client got res' );
};

subtest 'use the pirate' => sub {

    $client1->send( [ 'aaa', 'multi' ] );

    $client1->send( [ 'bbb', 'multi' ] );

    my $got = $server->receive(1);
    is( $got->[2], 'aaa', 'server got aaa' );
    $server->send( [ $got->[0], '', 'zzz' ] );

    my $got2 = $server->receive(1);
    is( $got2->[2], 'bbb', 'server got aaa' );
    $server->send( [ $got2->[0], '', 'zzz' ] );

    my $rep = $client1->receive(1);

    is( $rep->[0], 'zzz', 'client got res' );
};

subtest 'pirate multi after single' => sub {

    $client1->send('aaa');

    $client1->send( [ 'bbb', 'multi' ] );

    my $got = $server->receive(1);
    is( $got->[2], 'aaa', 'server got aaa' );
    $server->send( [ $got->[0], '', 'zzz' ] );

    my $got2 = $server->receive(1);
    is( $got2->[2], 'bbb', 'server got aaa' );
    $server->send( [ $got2->[0], '', 'zzz' ] );

    my $rep = $client1->receive(1);

    is( $rep->[0], 'zzz', 'client got res' );
};

subtest 'pirate single after multi' => sub {

    $client1->send( [ 'aaa', 'multi' ] );

    $client1->send('bbb');

    my $got = $server->receive(1);
    is( $got->[2], 'aaa', 'server got aaa' );
    $server->send( [ $got->[0], '', 'zzz' ] );

    my $got2 = $server->receive(1);
    is( $got2->[2], 'bbb', 'server got aaa' );
    $server->send( [ $got2->[0], '', 'zzz' ] );

    my $rep = $client1->receive(1);

    is( $rep->[0], 'zzz', 'client got res' );
};

subtest 'use the pirate with bytes' => sub {

    $client1->send_bytes( [ 'aaa', 'multi' ] );

    $client1->send_bytes( [ 'bbb', 'multi' ] );

    my $got = $server->receive(1);
    is( $got->[2], 'aaa', 'server got aaa' );
    $server->send( [ $got->[0], '', 'zzz' ] );

    my $got2 = $server->receive(1);
    is( $got2->[2], 'bbb', 'server got aaa' );
    $server->send( [ $got2->[0], '', 'zzz' ] );

    my $rep = $client1->receive(1);

    is( $rep->[0], 'zzz', 'client got res' );
};

done_testing();

