package Test::Net::RabbitMQ;
use Moose;
use warnings;
use strict;

use Math::Int64 0.34 qw( uint64 );

our $VERSION = '0.13';

# ABSTRACT: A mock RabbitMQ implementation for use when testing.


# Bindings are stored in the following form:
# {
#   exchange_name => {
#      regex => queue_name
#   },
#   ...
# }
has bindings => (
    traits => [ qw(Hash) ],
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
);


has connectable => (
    is => 'rw',
    isa => 'Bool',
    default => 1
);

has connected => (
    is => 'rw',
    isa => 'Bool',
    default => 0
);

has channels => (
    traits => [ qw(Hash) ],
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
    handles => {
        _channel_exists => 'exists',
        _get_channel    => 'get',
        _remove_channel => 'delete',
        _set_channel    => 'set',
    }
);


has debug => (
    is => 'rw',
    isa => 'Bool',
    default => 0
);

has exchanges => (
    traits => [ qw(Hash) ],
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
    handles => {
        _exchange_exists => 'exists',
        _get_exchange    => 'get',
        _remove_exchange => 'delete',
        _set_exchange    => 'set',
    }
);

has queue => (
    is => 'rw',
    isa => 'Str',
    predicate => '_has_queue',
    clearer => '_clear_queue',
);

has queues => (
    traits => [ qw(Hash) ],
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
    handles => {
        _queue_exists => 'exists',
        _get_queue    => 'get',
        _remove_queue => 'delete',
        _set_queue    => 'set',
    }
);

has delivery_tag => (
    is      => 'rw',
    isa     => 'Math::UInt64',
    default => sub { uint64(0) },
    clearer => '_reset_delivery_tag',
    writer  => '_set_delivery_tag',
);

sub _inc_delivery_tag {
    my $self = shift;
    $self->_set_delivery_tag( $self->delivery_tag + 1 );
}

sub _dec_delivery_tag {
    my $self = shift;
    $self->_set_delivery_tag( $self->delivery_tag - 1 );
}

has _tx_messages => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub{ {} },
);


sub channel_close {
    my ($self, $channel) = @_;

    die "Not connected" unless $self->connected;

    die "Unknown channel: $channel" unless $self->_channel_exists($channel);

    $self->_remove_channel($channel);
}


sub channel_open {
    my ($self, $channel) = @_;

    die "Not connected" unless $self->connected;

    $self->_set_channel($channel, 1);
}


sub connect {
    my ($self) = @_;

    die('Unable to connect!') unless $self->connectable;

    $self->connected(1);
}


my $ctag = 0;
sub consume {
    my ($self, $channel, $queue, $options) = @_;

    die "Not connected" unless $self->connected;

    die "Unknown channel" unless $self->_channel_exists($channel);

    die "Unknown queue" unless $self->_queue_exists($queue);

    $options = $self->_apply_defaults( $options, {
        no_local  => 0,
        no_ack    => 1,
        exclusive => 0,
    });

    die "no_ack=>0 is not supported at this time" if !$options->{no_ack};

    $self->queue($queue);

    return exists $options->{consumer_tag}
        ? $options->{consumer_tag}
        : 'consumer-tag-' . $ctag++;
}


sub cancel {
    my ($self, $channel, $consumer_tag) = @_;

    die "Not connected" unless $self->connected;

    die "You must provide a consumer tag"
        unless defined $consumer_tag && length $consumer_tag;

    return 0 unless $self->_has_queue;

    $self->_clear_queue;

    return 1;
}


sub disconnect {
    my ($self) = @_;

    die "Not connected" unless $self->connected;

    $self->connected(0);
}


sub exchange_declare {
    my ($self, $channel, $exchange, $options) = @_;

    die "Not connected" unless $self->connected;

    die "Unknown channel" unless $self->_channel_exists($channel);

    $self->_set_exchange($exchange, 1);
}


sub exchange_delete {
    my ($self, $channel, $exchange, $options) = @_;

    die "Not connected" unless $self->connected;

    die "Unknown channel" unless $self->_channel_exists($channel);

    $self->_remove_exchange($exchange);
}


sub tx_select {
    my ($self, $channel) = @_;

    die "Not connected" unless $self->connected;

    die "Unknown channel: $channel" unless $self->_channel_exists($channel);

    my $messages = $self->_tx_messages->{ $channel };
    die "Transaction already started" if $messages;

    $self->_tx_messages->{ $channel } = [];
}


sub tx_commit {
    my ($self, $channel) = @_;

    die "Not connected" unless $self->connected;

    die "Unknown channel: $channel" unless $self->_channel_exists($channel);

    my $messages = $self->_tx_messages->{ $channel };
    die "Transaction not yet started" unless $messages;

    foreach my $message (@$messages) {
        $self->_publish( $channel, @$message );
    }

    delete $self->_tx_messages->{ $channel };
}


sub tx_rollback {
    my ($self, $channel) = @_;

    die "Not connected" unless $self->connected;

    die "Unknown channel: $channel" unless $self->_channel_exists($channel);

    my $messages = $self->_tx_messages->{ $channel };
    die "Transaction not yet started" unless $messages;

    delete $self->_tx_messages->{ $channel };
}


sub get {
    my ($self, $channel, $queue, $options) = @_;

    die "Not connected" unless $self->connected;

    die "Unknown channel" unless $self->_channel_exists($channel);

    die "Unknown queue: $queue" unless $self->_queue_exists($queue);

    my $message = shift(@{ $self->_get_queue($queue) });

    return undef unless defined($message);

    $message->{delivery_tag}  = $self->_inc_delivery_tag;
    $message->{content_type}  = '';
    $message->{redelivered}   = 0;
    $message->{message_count} = 0;

    return $message;
}


sub queue_bind {
    my ($self, $channel, $queue, $exchange, $pattern) = @_;

    die "Not connected" unless $self->connected;

    die "Unknown channel: $channel" unless $self->_channel_exists($channel);

    die "Unknown queue: $queue" unless $self->_queue_exists($queue);

    die "Unknown exchange: $exchange" unless $self->_exchange_exists($exchange);

    my $binds = $self->bindings->{$exchange} || {};

    # Turn the pattern we're given into an actual regex
    my $regex = $pattern;
    if(($pattern =~ /\#/) || ($pattern =~ /\*/)) {
        if($pattern =~ /\#/) {
            $regex =~ s/\#/\.\*/g;
        } elsif($pattern =~ /\*/) {
            $regex =~ s/\*/\[^\.]\*/g;
        }
        $regex = '^'.$regex.'$';
        $regex = qr($regex);
    } else {
        $regex = qr/^$pattern$/;
    }

    # $self->_set_binding($routing_key, { queue => $queue, exchange => $exchange });
    $binds->{$regex} = $queue;

    # In case these are new bindings
    $self->bindings->{$exchange} = $binds;
}


my $queue = 0;
sub queue_declare {
    my ($self, $channel, $queue, $options) = @_;

    die "Not connected" unless $self->connected;

    die "Unknown channel: $channel" unless $self->_channel_exists($channel);

    if ($options->{passive}) {
        # Would rabbitmq die if $queue was undef or q{}?
        return
               unless defined $queue
            && length $queue
            && $self->_queue_exists($queue);
    }
    else {
        $queue = 'queue-' . $queue++
            unless defined $queue && length $queue;
        $self->_set_queue($queue, []) unless $self->_queue_exists($queue);
    }

    return $queue unless wantarray;
    return (
        $queue,
        scalar @{ $self->_get_queue($queue) },
        $self->queue && $self->queue eq $queue ? 1 : 0,
    );
}


sub queue_delete {
    my ($self, $channel, $queue, $options) = @_;

    die "Not connected" unless $self->connected;

    die "Unknown channel" unless $self->_channel_exists($channel);

    $self->_remove_queue($queue);
}


sub queue_unbind {
    my ($self, $channel, $queue, $exchange, $routing_key) = @_;

    die "Not connected" unless $self->connected;

    die "Unknown channel: $channel" unless $self->_channel_exists($channel);

    die "Unknown queue: $queue" unless $self->_queue_exists($queue);

    die "Unknown exchange: $queue" unless $self->_exchange_exists($exchange);

    die "Unknown routing: $routing_key" unless $self->_binding_exists($routing_key);

    $self->_remove_binding($routing_key);
}


sub publish {
    my $self = shift;
    my $channel = shift;

    die "Not connected" unless $self->connected;

    die "Unknown channel: $channel" unless $self->_channel_exists($channel);

    my $messages = $self->_tx_messages->{ $channel };
    if ($messages) {
        push @$messages, [ @_ ];
        return;
    }

    $self->_publish( $channel, @_ );
}

sub _publish {
    my ($self, $channel, $routing_key, $body, $options, $props) = @_;

    my $exchange = $options->{exchange};
    unless($exchange) {
        $exchange = 'amq.direct';
    }

    die "Unknown exchange: $exchange" unless $self->_exchange_exists($exchange);

    # Get the bindings for the specified exchange and test each key to see
    # if our routing key matches.  If it does, push it into the queue
    my $binds = $self->bindings->{$exchange};
    foreach my $pattern (keys %{ $binds }) {
        if($routing_key =~ $pattern) {
            print STDERR "Publishing '$routing_key' to ".$binds->{$pattern}."\n" if $self->debug;
            my $message = {
                body         => $body,
                routing_key  => $routing_key,
                exchange     => $exchange,
                props        => $props || {},
            };
            push(@{ $self->_get_queue($binds->{$pattern}) }, $message);
        }
    }
}


sub recv {
    my ($self) = @_;

    die "Not connected" unless $self->connected;

    my $queue = $self->queue;
    die "No queue, did you consume() first?" unless defined($queue);

    my $message = shift(@{ $self->_get_queue($self->queue) });

    return undef unless defined $message;

    $message->{delivery_tag} = $self->_inc_delivery_tag;
    $message->{consumer_tag} = '';
    $message->{redelivered}  = 0;

    return $message;
}

sub _apply_defaults {
    my ($self, $args, $defaults) = @_;

    $args ||= {};
    my $new_args = {};

    foreach my $key (keys %$args) {
        $new_args->{$key} = $args->{$key};
    }

    foreach my $key (keys %$defaults) {
        next if exists $new_args->{$key};
        $new_args->{$key} = $defaults->{$key};
    }

    return $new_args;
}

1;

__END__

=pod

=head1 NAME

Test::Net::RabbitMQ - A mock RabbitMQ implementation for use when testing.

=head1 VERSION

version 0.13

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Test::Net::RabbitMQ is a terrible approximation of using the real thing, but
hopefully will allow you to test systems that use L<Net::AMQP::RabbitMQ> or
L<Net::RabbitMQ> without having to use an actual RabbitMQ instance.

The general overview is that calls to C<publish> pushes a message into one
or more queues (or none if there are no bindings) and calls to C<recv>
pop them.

=head1 CAVEATS

This module has all the features I've needed to successfully test our
RabbitMQ-using application. Patches are welcome if I'm missing something you
need! At the moment there are a number of shortcomings:

=over 4

=item C<recv> doesn't block

=item exchanges are all topic

=item lots of other stuff!

=back

=head1 ATTRIBUTES

=head2 connectable

If false then any calls to connect will die to emulate a failed connection.

=head2 debug

If set to true (which you can do at any time) then a message will be emitted
to STDERR any time a message is added to a queue.

=head1 METHODS

=head2 channel_close($number)

Closes the specific channel.

=head2 channel_open($number)

Opens a channel with the specific number.

=head2 connect

Connects this instance.  Does nothing except set C<connected> to true.  Will
throw an exception if you've set C<connectable> to false.

=head2 consume($channel, $queue)

Sets the queue that will be popped when C<recv> is called.

=head2 cancel($channel, $consumer_tag)

Cancels the subscription for the given consumer tag. Calls to C<recv> after
this will throw an error unless you call C<consume> again. This method always
returns true if there is a subscription to cancel, false otherwise.

=head2 disconnect

Disconnects this instance by setting C<connected> to false.

=head2 exchange_declare($channel, $exchange, $options)

Creates an exchange of the specified name.

=head2 exchange_delete($channel, $exchange, $options)

Deletes an exchange of the specified name.

=head2 tx_select($channel)

Begins a transaction on the specified channel.  From this point forward all
publish() calls on the channel will be buffered until a call to L</tx_commit>
or L</tx_rollback> is made.

=head2 tx_commit($channel)

Commits a transaction on the specified channel, causing all buffered publish()
calls to this point to be published.

=head2 tx_rollback($channel)

Rolls the transaction back, causing all buffered publish() calls to be wiped.

=head2 get ($channel, $queue, $options)

Get a message from the queue, if there is one.

Like C<Net::RabbitMQ>, this will return a hash containing the following
information:

     {
       body => 'Magic Transient Payload', # the reconstructed body
       routing_key => 'nr_test_q',        # route the message took
       exchange => 'nr_test_x',           # exchange used
       delivery_tag => uint64(1),         # (inc'd every recv or get)
       redelivered => 0,                  # always 0
       message_count => 0,                # always 0
     }

=head2 queue_bind($channel, $queue, $exchange, $routing_key)

Binds the specified queue to the specified exchange using the provided
routing key.  B<Note that, at the moment, this doesn't work with AMQP wildcards.
Only with exact matches of the routing key.>

=head2 queue_declare($channel, $queue, $options)

Creates a queue of the specified name.

=head2 queue_delete($channel, $queue, $options)

Deletes a queue of the specified name.

=head2 queue_unbind($channel, $queue, $exchange, $routing_key)

Unbinds the specified routing key from the provided queue and exchange.

=head2 publish($channel, $routing_key, $body, $options)

Publishes the specified body with the supplied routing key.  If there is a
binding that matches then the message will be added to the appropriate queue(s).

=head2 recv

Provided you've called C<consume> then calls to recv will C<pop> the next
message of the queue.  B<Note that this method does not block.>

Like C<Net::RabbitMQ>, this will return a hash containing the following
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

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Cory G Watson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
