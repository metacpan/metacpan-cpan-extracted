package ZooKeeper::XUnit::Dispatcher::AnyEvent;
use Try::Tiny;
use Test::Class::Moose;
with 'ZooKeeper::XUnit::Role::Dispatcher';
with 'ZooKeeper::XUnit::Role::CheckLeaks';
with 'ZooKeeper::XUnit::Role::CheckWait';

sub test_startup {
    my ($self) = @_;
    try {
        require AnyEvent::Future;
        require ZooKeeper::Dispatcher::AnyEvent;
    } catch {
        $self->test_skip('Could not require ZooKeeper::Dispatcher::AnyEvent');
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
    return ZooKeeper::Dispatcher::AnyEvent->new(@args);
}


1;
