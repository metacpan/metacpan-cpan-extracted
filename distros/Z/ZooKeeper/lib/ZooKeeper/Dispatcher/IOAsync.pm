package ZooKeeper::Dispatcher::IOAsync;
use IO::Async::Handle;
use Scalar::Util qw(weaken);
use Scope::Guard qw(guard);
use Moo;
use namespace::autoclean;
extends 'ZooKeeper::Dispatcher::Pipe';

=head1 NAME

ZooKeeper::Dispatcher::IOAsync

=head1 DESCRIPTION

A ZooKeeper::Dispatcher implementation, and subclass of ZooKeeper::Dispatcher::Pipe.

Creates an IO::Async::Handle to handle reading from the pipe.

=head1 ATTRIBUTES

=head2 loop

The IO::Async::Loop to use for event handling.

=cut

has loop => (
    is       => 'ro',
    required => 1,
);

has notifier => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_notifier',
);
sub _build_notifier {
    my ($self) = @_;
    weaken($self);

    return IO::Async::Handle->new(
        read_fileno    => $self->fd,
        on_read_ready  => sub { $self->dispatch_cb->() },
        want_readready => 1,
    );
}

sub wait {
    my ($self, $time) = @_;
    my $loop   = $self->loop;
    my $future = $loop->new_future;

    my $time_id = $time && do {
        $loop->watch_time(
            after => $time,
            code  => sub { $future->done unless $future->is_done },
        )
    };

    my $dispatch_cb = $self->dispatch_cb;
    my $guard       = guard {
        $future->cancel;
        $loop->unwatch_time($time_id) if defined $time_id;
        $self->dispatch_cb($dispatch_cb);
    };
    $self->dispatch_cb(sub {
        my $event = $dispatch_cb->();
        $future->done($event) unless $future->is_done;
    });
    my $event = $future->get;

    weaken($self);
    return $event;
}

sub BUILD {
    my ($self) = @_;
    $self->loop->add($self->notifier);
}

sub DEMOLISH {
    my ($self, $in_global_destruction) = @_;
    return if $in_global_destruction;

    $self->loop->remove($self->notifier);
}

1;
