package ZooKeeper::XT::Dispatcher::AnyEvent;
use AnyEvent::Future;
use ZooKeeper::Dispatcher::AnyEvent;
use Test::Class::Moose;
with 'ZooKeeper::XT::Role::CheckAll';

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
