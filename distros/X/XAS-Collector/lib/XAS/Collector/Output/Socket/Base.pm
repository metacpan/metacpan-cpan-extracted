package XAS::Collector::Output::Socket::Base;

our $VERSION = '0.01';

use POE;
use Try::Tiny;
use XAS::Lib::POE::PubSub;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::Stomp::POE::Client',
  mixin     => 'XAS::Lib::Mixins::Handlers',
  accessors => 'event',
  vars => {
    PARAMS => {
      -eol => { optional => 1, default => "\n" }, # really? silly ruby programmers
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Events
# ----------------------------------------------------------------------

sub handle_connection {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: handle_connection()");

    if ($self->tcp_keepalive) {

        $self->log->info_msg('tcp_keepalive_enabled', $alias);

        $self->init_keepalive(
            -tcp_keepidle => 100,
        );

        $self->enable_keepalive($self->socket);

    }

    $self->log->info_msg('collector_connected', $alias, $self->host, $self->port);

}

sub read_data {
    my ($self, $data) = @_[OBJECT, ARG0];

    my $alias = $self->alias;

    $self->log->warn("$alias: $data");

}

sub connection_down {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->warn_msg('collector_down', $alias);

    $self->event->publish(
        -event => 'stop_queue',
        -args  => $alias
    );

}

sub connection_up {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->warn_msg('collector_up', $alias);

    $self->event->publish(
        -event => 'start_queue',
        -args  => $alias
    );

}

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub session_initialize {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_initialize()");

    $poe_kernel->state('store_data', $self);

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leasing session_initialize()");

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
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{'event'} = XAS::Lib::POE::PubSub->new();

    return $self;

}

1;

__END__

=head1 NAME

XAS::Collector::Output::Socket::Base - Base method to interact with socket servers

=head1 SYNOPSIS

  use XAS::Collector::Output::Socket::Logstash;

  my $output = XAS::Collector::Output::Socket::Logstash->new(
      -alias => 'socket-logstash',
      -eol   => "\n",
  );

=head1 DESCRIPTION

This module will open and maintain a connection to a socker server. 

=head1 METHODS

=head2 new

This module inherits from L<XAS::Lib::Net::POE::Client|XAS::Lib::Net::POE::Client> and
takes these additional parameters:

=over 4

=item B<-eol>

The end-of-line terminator to use. Defaults to "\n". 

=back

=head1 PUBLIC EVENTS

This module declares the following events.

=head2 store_data

This event is called when a packet is ready for processing.

=head1 SEE ALSO

=over 4

=item L<XAS::Collector::Output::Socket::Logstash|XAS::Collector::Output::Socket::Logstash>

=item L<XAS::Collector::Output::Socket::OpenTSDB|XAS::Collector::Output::Socket::OpenTSDB>

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
