#!/usr/bin/env perl

# a ZeroMQ publisher

use 5.014;
use ZMQx::Class;

my $publisher = ZMQx::Class->socket( 'PUB', bind => 'tcp://*:10000' );

while ( 1 ) {
    my $random = int( rand ( 10_000 ) );
    say "sending $random hello";
    $publisher->send( [ $random, 'hello' ] );
    select( undef, undef, undef, 0.1);
}

