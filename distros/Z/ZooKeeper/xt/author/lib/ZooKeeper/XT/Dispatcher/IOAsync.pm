package ZooKeeper::XT::Dispatcher::IOAsync;
use IO::Async::Loop;
use ZooKeeper::Dispatcher::IOAsync;
use Test::Class::Moose;
with 'ZooKeeper::XT::Role::CheckAll';

has loop => (
    is      => 'ro',
    lazy    => 1,
    default => sub { IO::Async::Loop->new },
);

sub new_future { shift->loop->new_future }

sub new_delay {
    my ($self, $after, $cb) = @_;
    my $loop = $self->loop;
    return $loop->delay_future(after => $after)
                ->on_done($cb);
}

sub new_dispatcher {
    my ($self, @args) = @_;
    return ZooKeeper::Dispatcher::IOAsync->new(loop => $self->loop, @args);
}

1;
