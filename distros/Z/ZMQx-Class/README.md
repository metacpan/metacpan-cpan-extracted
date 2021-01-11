# NAME

ZMQx::Class - DEPRECATED - OO Interface to ZMQ

# VERSION

version 0.008

# SYNOPSIS

DEPRECATED - This was only a prototype and never used in production. I doubt it still works with current zmq.

    # a ZeroMQ publisher
    # see example/publisher.pl
    use ZMQx::Class;
    my $publisher = ZMQx::Class->socket( 'PUB', bind => 'tcp://*:10000' );

    while ( 1 ) {
        my $random = int( rand ( 10_000 ) );
        say "sending $random hello";
        $publisher->send( [ $random, 'hello' ] );
        select( undef, undef, undef, 0.1);
    }


    # a ZeroMQ subscriber
    # see example/subscriber.pl
    use ZMQx::Class;
    use Anyevent;

    my $subscriber = ZMQx::Class->socket( 'SUB', connect => 'tcp://localhost:10000' );
    $subscriber->subscribe( '1' );

    my $watcher = $subscriber->anyevent_watcher( sub {
        while ( my $msg = $subscriber->receive ) {
            say "got $msg->[0] saying $msg->[1]";
        }
    });
    AnyEvent->condvar->recv;

# DESCRIPTION

DEPRECATED - This was only a prototype and never used in production. I doubt it still works with current zmq. But here are the old docs:

`ZMQx::Class` provides an object oriented & Perlish interface to [ZeroMQ](http://www.zeromq.org/) 3.2. It builds on [ZMQ::FFI](https://metacpan.org/module/ZMQ::FFI).

Before you use `ZMQx::Class`, please read the excellent <ZeroMQ Guide|http://zguide.zeromq.org>. It's a fun and interesting read, containing everything you need to get started with ZeroMQ, including lots of example code.

# METHODS

## context

    my $ctx = ZMQx::Class->context;

Return the current context for this process.

ZMQx::Class pools one context per process (pid). It will always use the currents process socket, and set up a new context after a fork. This should be very helpful for most use cases (e.g. when you need a 0mq socket inside a preforked webapp).

If you want to get a new context, use `ZMQx::Class->_new_context`. But you will have to manage this context yourself!

## socket

    my $socket = ZMQx::Class->socket( $type );
    my $socket = ZMQx::Class->socket( $type, bind => $endpoint );
    my $socket = ZMQx::Class->socket( $type, connect => $endpoint, \%opts );
    my $socket = ZMQx::Class->socket( $context, $type );

`socket` is a factory method that returns a new `ZMQx::Class::Socket` object. The new socket will use the default process-wide context.

    my $socket = ZMQx::Class->socket( $type );

Returns a new socket of the given type. Types are valid 0mq sockets:

    REQ REP DEALER ROUTER PULL PUSH PUB SUB XPUB XSUB PAIR

This socket will be neither bound nor connected, and have no sockopts set.

**connect / bind**

    my $socket = ZMQx::Class->socket( $type, [bind | connect] => $endpoint );

If you call socket like this, you will get back a socket that's already bound or connected to the given endpoint.

**options**

    my $socket = ZMQx::Class->socket( $type, connect => $endpoint, {
        sndhwm  => 500
    });

You can pass in a hashref containing valid sockopts to set them before connect/bind. A lot of sockopts can only be set before connect/bind, so if you want to set them, either pass them to `socket`, or do not use the autoconnect/bind feater.

See Sockopts in ZMQx::Class::Socket for a list of valid options.

**context**

If you really need to, you can pass a context object as the first agrument to `socket`.

    my $socket = ZMQx::Class->socket( $context, $type );

# SEE ALSO

[ZMQ](https://metacpan.org/module/ZMQ::Socket) is another perlish interface to libzmq. We found it to still be a bit too low-level (eg, you still need to import the sockopt-constants). ZMQ support libzmq 2 and 3, and promises a single interface to both. We are only interested in libzmq 3. ZMQx::Class includes some smartness to handle setup of context objects, even across forks. Lastly, we found this note from the docs not very promising: "Personally, I'd recommend only using this module for your one-shot scripts, and use ZMQ::LibZMQ\* for all other uses."

# THANKS

Thanks to [Validad](http://www.validad.com/) for sponsoring the development of this module.

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 - 2015 by Validad AG.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
