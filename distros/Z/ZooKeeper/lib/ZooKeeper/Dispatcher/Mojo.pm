package ZooKeeper::Dispatcher::Mojo;
use Future::Mojo;
use Mojo::IOLoop;
use Scalar::Util qw(weaken);
use Scope::Guard qw(guard);
use Moo;
use namespace::autoclean;
extends 'ZooKeeper::Dispatcher::Pipe';

=head1 NAME

ZooKeeper::Dispatcher::Mojo

=head1 DESCRIPTION

A ZooKeeper::Dispatcher implementation, and subclass of ZooKeeper::Dispatcher::Pipe.
Creates a Mojo::Reactor I/O watcher to handle reading from the pipe.

=cut

has fh => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_fh',
);
sub _build_fh {
    my ($self) = @_;
    open my($fh), '<&=', $self->fd;
    return $fh;
}

=head1 ATTRIBUTES

=head2 loop

The Mojo::IOLoop to use for event handling.
Defaults to Mojo::IOLoop->singleton.

=cut

has loop => (
    is       => 'ro',
    lazy     => 1,
    default  => sub { Mojo::IOLoop->singleton },
);

sub wait {
    my ($self, $time) = @_;
    my $loop   = $self->loop;
    my $future = Future::Mojo->new($loop);

    my $timeout = $time && do {
        Future::Mojo->new_timer($loop, $time)
                    ->then(sub { $future->done })
    };

    my $dispatch_cb = $self->dispatch_cb;
    my $guard       = guard {
        $future->cancel;
        $timeout->cancel if $timeout;
        $self->dispatch_cb($dispatch_cb);
    };
    $self->dispatch_cb(sub {
        my $event = $dispatch_cb->();
        $future->done($event);
    });
    my $event = $future->get;

    weaken($self);
    return $event;
}

sub BUILD {
    my ($self) = @_;
    weaken($self);

    my $handle  = $self->fh;
    my $reactor = $self->loop->reactor;
    $reactor->io($handle, sub { $self->dispatch_cb->() });
    $reactor->watch($handle, 1, 0);
}

sub DEMOLISH {
    my ($self, $in_global_destruction) = @_;
    return if $in_global_destruction;

    my $handle  = $self->fh;
    my $reactor = $self->loop->reactor;
    $reactor->remove($handle);
}

1;
