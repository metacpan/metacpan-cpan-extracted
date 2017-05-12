NAME

    Test::Net::RabbitMQ - A mock RabbitMQ implementation for use when
    testing.

VERSION

    version 0.13

SYNOPSIS

        use Test::Net::RabbitMQ;
    
        my $mq = Test::Net::RabbitMQ->new;
    
        $mq->connect;
    
        $mq->channel_open(1);
    
        $mq->exchange_declare(1, 'order');
        $mq->queue_declare(1, 'new-orders');
    
        $mq->queue_bind(1, 'new-orders', 'order', 'order.new');
    
        $mq->publish(1, 'order.new', 'hello!', { exchange => 'order' });
    
        $mq->consume(1, 'new-orders');
    
        my $msg = $mq->recv;
    
        # Or
    
        my $msg = $mq->get(1, 'order.new', {});

DESCRIPTION

    Test::Net::RabbitMQ is a terrible approximation of using the real
    thing, but hopefully will allow you to test systems that use
    Net::AMQP::RabbitMQ or Net::RabbitMQ without having to use an actual
    RabbitMQ instance.

    The general overview is that calls to publish pushes a message into one
    or more queues (or none if there are no bindings) and calls to recv pop
    them.

CAVEATS

    This module has all the features I've needed to successfully test our
    RabbitMQ-using application. Patches are welcome if I'm missing
    something you need! At the moment there are a number of shortcomings:

    recv doesn't block

    exchanges are all topic

    lots of other stuff!

ATTRIBUTES

 connectable

    If false then any calls to connect will die to emulate a failed
    connection.

 debug

    If set to true (which you can do at any time) then a message will be
    emitted to STDERR any time a message is added to a queue.

METHODS

 channel_close($number)

    Closes the specific channel.

 channel_open($number)

    Opens a channel with the specific number.

 connect

    Connects this instance. Does nothing except set connected to true. Will
    throw an exception if you've set connectable to false.

 consume($channel, $queue)

    Sets the queue that will be popped when recv is called.

 cancel($channel, $consumer_tag)

    Cancels the subscription for the given consumer tag. Calls to recv
    after this will throw an error unless you call consume again. This
    method always returns true if there is a subscription to cancel, false
    otherwise.

 disconnect

    Disconnects this instance by setting connected to false.

 exchange_declare($channel, $exchange, $options)

    Creates an exchange of the specified name.

 exchange_delete($channel, $exchange, $options)

    Deletes an exchange of the specified name.

 tx_select($channel)

    Begins a transaction on the specified channel. From this point forward
    all publish() calls on the channel will be buffered until a call to
    "tx_commit" or "tx_rollback" is made.

 tx_commit($channel)

    Commits a transaction on the specified channel, causing all buffered
    publish() calls to this point to be published.

 tx_rollback($channel)

    Rolls the transaction back, causing all buffered publish() calls to be
    wiped.

 get ($channel, $queue, $options)

    Get a message from the queue, if there is one.

    Like Net::RabbitMQ, this will return a hash containing the following
    information:

         {
           body => 'Magic Transient Payload', # the reconstructed body
           routing_key => 'nr_test_q',        # route the message took
           exchange => 'nr_test_x',           # exchange used
           delivery_tag => uint64(1),         # (inc'd every recv or get)
           redelivered => 0,                  # always 0
           message_count => 0,                # always 0
         }

 queue_bind($channel, $queue, $exchange, $routing_key)

    Binds the specified queue to the specified exchange using the provided
    routing key. Note that, at the moment, this doesn't work with AMQP
    wildcards. Only with exact matches of the routing key.

 queue_declare($channel, $queue, $options)

    Creates a queue of the specified name.

 queue_delete($channel, $queue, $options)

    Deletes a queue of the specified name.

 queue_unbind($channel, $queue, $exchange, $routing_key)

    Unbinds the specified routing key from the provided queue and exchange.

 publish($channel, $routing_key, $body, $options)

    Publishes the specified body with the supplied routing key. If there is
    a binding that matches then the message will be added to the
    appropriate queue(s).

 recv

    Provided you've called consume then calls to recv will pop the next
    message of the queue. Note that this method does not block.

    Like Net::RabbitMQ, this will return a hash containing the following
    information:

         {
           body => 'Magic Transient Payload', # the reconstructed body
           routing_key => 'nr_test_q',        # route the message took
           exchange => 'nr_test_x',           # exchange used
           delivery_tag => uint64(1),         # (inc'd every recv or get)
           redelivered => $boolean            # if message is redelivered
           consumer_tag => '',                # Always blank currently
           props => $props,                   # hashref sent in
         }

AUTHOR

    Cory G Watson <gphat@cpan.org>

COPYRIGHT AND LICENSE

    This software is copyright (c) 2015 by Cory G Watson.

    This is free software; you can redistribute it and/or modify it under
    the same terms as the Perl 5 programming language system itself.

