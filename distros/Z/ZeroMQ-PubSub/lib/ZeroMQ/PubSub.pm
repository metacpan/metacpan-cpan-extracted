package ZeroMQ::PubSub;

use Moose;
use ZMQ::LibZMQ2;
use JSON;
use namespace::autoclean;

with 'MooseX::Callbacks';

has 'context' => (
    is => 'rw',
    isa => 'ZMQ::LibZMQ2::Context',
    lazy_build => 1,
);

has 'publish_sock' => (
    is => 'rw',
    isa => 'ZMQ::LibZMQ2::Socket',
    lazy_build => 1,
    predicate => 'publish_socket_exists',
);

has 'subscribe_sock' => (
    is => 'rw',
    isa => 'ZMQ::LibZMQ2::Socket',
    lazy_build => 1,
    predicate => 'subscription_socket_exists',
);

sub _build_context { zmq_init() }

sub print_debug {
    my ($self, $msg) = @_;

    return unless $self->debug;
    print "DEBUG: $msg\n";
}

sub print_info {
    my ($self, $msg) = @_;

    print "INFO: $msg\n";
}

sub DEMOLISH {
    my ($self, $igd) = @_;

    zmq_close($self->publish_sock) if $self->publish_socket_exists && $self->publish_sock;
    zmq_close($self->subscribe_sock) if $self->subscription_socket_exists && $self->subscribe_sock;
}

=head1 NAME

ZeroMQ::PubSub - ZeroMQ-based event messaging system.

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

See L<ZeroMQ::PubSub::Client>, L<ZeroMQ::PubSub::Server>

=head1 ATTRIBUTES

=head2 debug

=cut

has 'debug' => ( is => 'rw', isa => 'Bool' );


=head1 METHODS

=head2 subscribe($event, $callback)

Calls $callback when a message of type $event is received. Can be used
on the server or the client.

$callback is called with two arguments: $self (client or server instance) and event parameters.

=cut

sub subscribe {
    my ($self, $evt, $cb) = @_;

    # create callback wrapper
    my $cb_wrapped = sub {
        $cb->($self, @_);
    };
    
    # set up callback
    $self->register_callback($evt => $cb_wrapped);
}


=head2 dispatch_event($msg)

Runs event callbacks for the message based on event type. You probably
don't need to call this.

=cut

sub dispatch_event {
    my ($self, $msg) = @_;

    # message type lives in type
    my $type = $msg->{type};
    unless ($type) {
        warn "Got ZeroMQ::PubSub message with no type defined\n";
        return;
    }

    $self->print_debug("Got $type event");

    my $params = $msg->{params} || {};

    # calls callbacks
    $self->dispatch($type => $params);
}

=head1 SEE ALSO

L<ZeroMQ::PubSub::Server>, L<ZeroMQ::PubSub::Client>

=head1 TODO

* Tests

* Support non-blocking (w/ L<AnyEvent>)

=head1 AUTHOR

Mischa Spiegelmock, C<< <revmischa at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zeromq-pubsub at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZeroMQ-PubSub>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZeroMQ::PubSub

=head1 ACKNOWLEDGEMENTS

L<ZeroMQ>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Mischa Spiegelmock.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of ZeroMQ::PubSub
