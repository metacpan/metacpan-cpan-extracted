package ZooKeeper::XT::Dispatcher::Interrupt;
use AnyEvent;
use AnyEvent::Future;
use ZooKeeper::Dispatcher::Interrupt;
use Test::Class::Moose;
with 'ZooKeeper::XT::Role::CheckAll';

has ticker => (
    is      => 'ro',
    builder => '_build_ticker'
);
sub _build_ticker {
    my $tick = 0.1;
    return AnyEvent->timer(
        after    => $tick,
        interval => $tick,
        cb       => sub { },
    );
}

sub new_future { AnyEvent::Future->new }

sub new_delay {
    my ($self, $after, $cb) = @_;
    return AnyEvent->timer(
        after => $after,
        cb    => $cb,
    );
}

sub new_dispatcher {
    my ($self, @args) = @_;
    return ZooKeeper::Dispatcher::Interrupt->new(@args);
}

1;
