package XAS::Collector::Input::Stomp;

our $VERSION = '0.03';

use POE;
use Try::Tiny;
use XAS::Lib::POE::PubSub;
use Params::Validate qw(HASHREF);

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::Stomp::POE::Client',
  mixin     => 'XAS::Lib::Mixins::Handlers',
  utils     => 'dotid',
  codec     => 'JSON',
  constants => 'HASH',
  mutators  => 'connected',
  accessors => 'pubsub',
  vars => {
    PARAMS => {
      '-types'    => { type => HASHREF },
      '-prefetch' => { optional => 1, default => 0 },
    },
  }
;

#use Data::Dumper;
# rabbitmq - optional "prefetch-count" with subscribe frame.

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub session_initialize {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_initialize()");

    # public events

    $poe_kernel->state('pause_processing',  $self);
    $poe_kernel->state('resume_processing', $self);

    # private events

    $poe_kernel->state('stop_queue',  $self, '_stop_queue');
    $poe_kernel->state('start_queue', $self, '_start_queue');

    $self->pubsub->subscribe($alias);

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leaving session_initialize()");

}

sub session_shutdown {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_shutdown");

    $poe_kernel->alarm_remove_all();

    # walk the chain

    $self->SUPER::session_shutdown();

    $self->log->debug("$alias: leaving session_shutdown");

}

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

sub handle_connected {
    my ($self, $frame) = @_[OBJECT, ARG0];

    my $alias = $self->alias;

    if ($self->tcp_keepalive) {

        $self->log->info_msg('tcp_keepalive_enabled', $alias);

        $self->init_keepalive();
        $self->enable_keepalive($self->socket);

    }

    $self->log->info_msg('collector_connected', $alias, $self->host, $self->port);
    $self->connected(1);

}

sub handle_message {
    my ($self, $frame) = @_[OBJECT,ARG0];

    my $data;
    my $type;
    my $nframe;
    my $format;
    my $output;
    my $message;
    my $message_id;
    my $alias = $self->alias;

    try {

        $message    = decode($frame->body);
        $message_id = $frame->header->message_id;
        $nframe     = $self->stomp->ack(-message_id => $message_id);

        if ($type = $message->{'type'}) {

            $self->log->info_msg('collector_received',
                $alias,
                $message_id,
                $message->{'type'},
                $message->{'hostname'}
            );

            if (defined($self->{'types'}->{$type})) {

                $data   = $message->{'data'};
                $format = $self->{'types'}->{$type}->{'format'};
                $output = $self->{'types'}->{$type}->{'output'};

                $poe_kernel->post($format, 'format_data', $data, $nframe, $alias, $output);

            } else {

                $self->throw_msg(
                    dotid($self->class) . '.input.stomp.unknowntype',
                    'collector_unknowntype',
                    $message->{'type'},
                );

            }

        } else {

            $self->throw_msg(
                dotid($self->class) . '.input.stomp.notype',
                'collector_notype',
                $alias,
            );

        }

    } catch {

        my $ex = $_;

        $self->exception_handler($ex);
        $self->log->error(Dumper($frame));

        $poe_kernel->post($alias, 'write_data', $nframe);

    };

}

sub connection_down {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->connected(0);
    $poe_kernel->post($alias, 'pause_processing');

    $self->log->debug("$alias: connection down");

}

sub connection_up {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->connected(1);
    $poe_kernel->post($alias, 'resume_processing');

    $self->log->debug("$alias: connection up");

}

sub pause_processing {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: entering pause_processing()");

    foreach my $type (keys %{$self->{'types'}}) {

        my $ralias = $self->{'types'}->{$type}->{'input'};

        $poe_kernel->post($alias, 'stop_queue', $ralias);

    }

    $self->log->debug("$alias: leaving pause_processing()");

}

sub resume_processing {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: entering resume_processing()");

    foreach my $type (keys %{$self->{'types'}}) {

        my $ralias = $self->{'types'}->{$type}->{'input'};

        $poe_kernel->post($alias, 'start_queue', $ralias);

    }

    $self->log->debug("$alias: leaving resume_processing()");

}

# ----------------------------------------------------------------------
# Private Events
# ----------------------------------------------------------------------

sub _start_queue {
    my ($self, $ralias) = @_[OBJECT,ARG0];

    my $alias = $self->alias;
    my $queue = $self->_find_queue($ralias);

    if ($self->connected) {

        my $frame = $self->stomp->subscribe(
            -destination => $queue,
            -ack         => 'client',
            -prefetch    => $self->prefetch,
        );

        $self->log->info_msg('collector_subscribed', $alias, $queue);
        $poe_kernel->post($alias, 'write_data', $frame);

    } else {

        $poe_kernel->delay_add('start_queue', 5, $ralias);
        $self->log->warn_msg('collector_waiting', $alias, $queue);

    }

}

sub _stop_queue {
    my ($self, $ralias) = @_[OBJECT,ARG0];

    my $alias = $self->alias;
    my $queue = $self->_find_queue($ralias);

    if ($self->connected) {

        my $frame = $self->stomp->unsubscribe(
            -destination => $queue,
        );

        $self->log->warn_msg('collector_unsubscribed', $alias, $queue);
        $poe_kernel->post($alias, 'write_data', $frame);

    }

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{'pubsub'} = XAS::Lib::POE::PubSub->new();
    $self->{'connected'} = 0;

    return $self;

}

sub _find_queue {
    my $self  = shift;
    my $ralias = shift;

    my $queue = '';
    my $alias = $self->alias;

    $self->log->debug(sprintf('%s: find_queue() alias = %s', $alias, $ralias));

    while (my ($key, $value) = each(%{$self->{'types'}})) {

        if (($value->{'input'}  eq $ralias) or
            ($value->{'output'} eq $ralias)) {

            $queue = $value->{'queue'};

        }

    }

    return $queue;

}

1;

__END__

=head1 NAME

XAS::Collector::Input::Stomp - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Collector::Input::Stomp;

 my $types => {
     'xas-alerts' => {
         queue  => '/queue/alerts',
         format => 'format-alerts',
         input  => 'input-stomp',
         output => 'output-logstash',
     },
 };

 my $processor = XAS::Collector::Input::Stomp->new(
     -alias => 'input-stomp',
     -types => $types
 );

=head1 DESCRIPTION

This module will monitor a queue on a STOMP based message queue server.
It will attempt to maintain a connection to the server.

=head1 METHODS

=head2 new

This method will initialize the module and takes these parameters:

=over 4

=item B<-types>

The message types that this input module can handle.

=item B<-prefetch>

The number of messages to prefetch from the queue. Default is unlimitied. This
may have meaning only on a L<RabbitMQ|http://www.rabbitmq.com/stomp.html> server.

=back

=head1 PUBLIC EVENTS

This module declares the following events:

=head2 pause_processing

This event is broadcasted when the connection to the message queue server
is down. It's purpose is to stop processing messages on a queue.

=head2 resume_processing

This event is broadcasted when the connection to the message queue server
is down. It's purpose is to start processing messages on a queue.

=head1 SEE ALSO

=over 4

=item L<XAS::Collector|XAS::Collector>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
