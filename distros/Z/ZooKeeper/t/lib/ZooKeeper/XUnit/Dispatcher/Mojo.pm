package ZooKeeper::XUnit::Dispatcher::Mojo;
use Try::Tiny;
use Test::Class::Moose;
with 'ZooKeeper::XUnit::Role::Dispatcher';
with 'ZooKeeper::XUnit::Role::CheckLeaks';
with 'ZooKeeper::XUnit::Role::CheckWait';

sub test_startup {
    my ($self) = @_;
    try {
        require Future::Mojo;
        require Mojolicious;
        require ZooKeeper::Dispatcher::Mojo;
    } catch {
        $self->test_skip('Could not require ZooKeeper::Dispatcher::Mojo');
    };
}

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
