package ZooKeeper::Dispatcher::POE;
use POE;
use Scalar::Util qw(weaken);
use Scope::Guard qw(guard);
use Moo;
use namespace::autoclean;
extends 'ZooKeeper::Dispatcher::Pipe';

=head1 NAME

ZooKeeper::Dispatcher::POE

=head1 DESCRIPTION

A ZooKeeper::Dispatcher implementation, and subclass of ZooKeeper::Dispatcher::Pipe.

Creates a POE::Session to handle reading from the pipe.

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

has session => (
    is      => 'ro',
    writer  => 'set_session',
    clearer => 'clear_session',
);

sub wait {
    my ($self, $time) = @_;
    require POE::Future;

    my $future  = POE::Future->new;
    my $timeout = $time && do {
        POE::Future->new_delay($time)
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

    my %states = (
        _start => sub {
            $_[KERNEL]->select_read($self->fh, 'dispatch');
        },
        dispatch => sub {
            $self->dispatch_cb->();
        },
        shutdown => sub {
            $_[KERNEL]->select_read($self->fh);
        }
    );

    my $session = POE::Session->create(inline_states => \%states);
    $self->set_session($session);
}

sub DEMOLISH {
    my ($self, $in_global_destruction) = @_;
    return if $in_global_destruction;

    POE::Kernel->call($self->session, 'shutdown');
    $self->clear_session;
};

1;
