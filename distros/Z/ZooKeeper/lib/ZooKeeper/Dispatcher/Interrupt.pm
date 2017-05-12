package ZooKeeper::Dispatcher::Interrupt;
use ZooKeeper::XS;
use AnyEvent;
use Async::Interrupt;
use Scalar::Util qw(weaken);
use Moo;
use namespace::autoclean;
extends 'ZooKeeper::Dispatcher';

=head1 NAME

ZooKeeper::Dispatcher::Interrupt

=head1 DESCRIPTION

A ZooKeeper::Dispatcher implementation that uses Async::Interrupt for dispatching.

In order to interrupt AnyEvent, during ZooKeeper::Dispatcher's wait call, the Interrupt implementation creates an AnyEvent timer to trigger every 100ms. This is needed because AnyEvent's recv blocks on a select call, which Async::Interrupt cannot interrupt by itself.

=cut

has interrupt => (
    is      => 'ro',
    builder => '_build_interrupt',
);

sub _build_interrupt {
    my ($self) = @_;
    my $interrupt = Async::Interrupt->new(cb => sub { $self->dispatch_cb->() });

    weaken($self);
    return $interrupt;
}

sub ticker {
    my ($self, $tick) = @_;
    $tick ||= 0.1;
    return AnyEvent->timer(
        after    => $tick,
        interval => $tick,
        cb       => sub { },
    );
}

around wait => sub {
    my ($orig, $self, @args) = @_;
    my $ticker = $self->ticker;
    return $self->dispatch_cb->() if $self->channel->size;
    $self->$orig(@args);
};

sub BUILD {
    my ($self) = @_;
    my ($func, $arg) = $self->interrupt->signal_func;
    $self->_xs_init($self->channel, $func, $arg);
}


1;
