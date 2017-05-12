package ZooKeeper::XUnit::Dispatcher::Interrupt;
use AnyEvent;
use Try::Tiny;
use Test::Class::Moose;
with 'ZooKeeper::XUnit::Role::Dispatcher';
with 'ZooKeeper::XUnit::Role::CheckLeaks';
with 'ZooKeeper::XUnit::Role::CheckWait';

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

sub test_startup {
    my ($self) = @_;
    try {
        require AnyEvent::Future;
        require ZooKeeper::Dispatcher::Interrupt;
    } catch {
        $self->test_skip('Could not require ZooKeeper::Dispatcher::Interrupt');
    };
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
