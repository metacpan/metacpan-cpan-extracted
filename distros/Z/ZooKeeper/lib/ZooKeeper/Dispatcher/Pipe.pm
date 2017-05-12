package ZooKeeper::Dispatcher::Pipe;
use ZooKeeper::XS;
use Moo;
use namespace::autoclean;
extends 'ZooKeeper::Dispatcher';

=head1 NAME

ZooKeeper::Dispatcher::Pipe

=head1 DESCRIPTION

A ZooKeeper::Dispatcher implementation which uses a Unix pipe for dispatching.

This class is intended for subclassing, as it requires an event loop(such as AnyEvent) to handle reading from the pipe.

=cut

after recv_event => sub { shift->read_pipe };

sub BUILD {
    my ($self) = @_;
    $self->_xs_init($self->channel);
}


1;
