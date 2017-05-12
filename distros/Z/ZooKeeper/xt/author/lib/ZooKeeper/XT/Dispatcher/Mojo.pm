package ZooKeeper::XT::Scheduler::Mojo;
use ZooKeeper::Dispatcher::Mojo;
use Future::Mojo;
use Mojo::IOLoop;
use Test::Class::Moose;
with 'ZooKeeper::XT::Role::CheckAll';

has loop => (
    is      => 'ro',
    lazy    => 1,
    default => sub { Mojo::IOLoop->singleton },
);

sub new_future { Future::Mojo->new(shift->loop) }

sub new_delay {
    my ($self, $after, $cb) = @_;
    my $loop = $self->loop;

    return Future::Mojo->new_timer($loop, $after)
                       ->on_done($cb);
}

sub new_dispatcher {
    my ($self, @args) = @_;
    return ZooKeeper::Dispatcher::Mojo->new(loop => $self->loop, @args);
}

1;
