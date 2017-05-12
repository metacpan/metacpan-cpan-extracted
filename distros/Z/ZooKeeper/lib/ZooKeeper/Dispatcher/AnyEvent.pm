package ZooKeeper::Dispatcher::AnyEvent;
use AnyEvent;
use Scalar::Util qw(weaken);
use Moo;
use namespace::autoclean;
extends 'ZooKeeper::Dispatcher::Pipe';

=head1 NAME

ZooKeeper::Dispatcher::AnyEvent

=head1 DESCRIPTION

A ZooKeeper::Dispatcher implementation, and subclass of ZooKeeper::Dispatcher::Pipe.

Creates an AnyEvent I/O watcher to handle reading from the pipe.

=cut

has ae_watcher => (
    is        => 'rw',
);

sub setup_ae_watcher {
    my ($self) = @_;

    my $w = AnyEvent->io(
        fh   => $self->fd,
        poll => 'r',
        cb   => sub { $self->dispatch_cb->() },
    );
    $self->ae_watcher($w);
    weaken($self);
}

sub BUILD {
    my ($self) = @_;
    $self->setup_ae_watcher;
}


1;
