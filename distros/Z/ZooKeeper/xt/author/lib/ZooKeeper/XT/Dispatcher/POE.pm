package ZooKeeper::XT::Dispatcher::POE;
use POE qw(Loop::Select);
use POE::Future;
use ZooKeeper::Dispatcher::POE;
use Test::Class::Moose;
with 'ZooKeeper::XT::Role::CheckAll';
POE::Kernel->run;

sub new_future { POE::Future->new }

sub new_delay {
    my ($self, $after, $cb) = @_;
    require POE::Future;
    return POE::Future->new_delay($after)
                      ->on_done($cb);
}

sub new_dispatcher {
    my ($self, @args) = @_;
    return ZooKeeper::Dispatcher::POE->new(@args);
}

1;
