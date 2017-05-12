package ZooKeeper::Watcher;
use ZooKeeper::XS;
use ZooKeeper::Constants;
use Moo;
use namespace::autoclean;

=head1 NAME

ZooKeeper::Watcher

=head1 DESCRIPTION

A perl class for constructing the watcher contexts passed to the ZooKeeper C library.

=head1 ATTRIBUTES

=head2 dispatcher

A weak reference to the dispatcher the watcher belongs to.
Needed in order for the watcher to notify the dispatcher when it has been triggered.

=cut

has dispatcher => (
    is       => 'ro',
    weak_ref => 1,
    required => 1,
);

=head2 cb

A perl subroutine reference. Invoked with an event hashref, when the watch is triggered by the ZooKeeper C library.

    sub {
        my ($event) = @_;
        my $path  = $event->{path};
        my $type  = $event->{type};
        my $state = $event->{state};
    }

=cut

has cb => (
    is       => 'ro',
    required => 1,
);

has done => (
    is      => 'rw',
    default => 0,
);

has ignore_session_events => (
    is      => 'ro',
    default => 1,
);

has path => (
    is => 'ro',
);

has type => (
    is => 'ro',
);

sub BUILD {
    my ($self) = @_;
    $self->_xs_init($self->dispatcher);
}

sub process {
    my ($self, $event) = @_;
    unless ($self->_should_ignore($event)) {
        $self->cb->($event);
    }
    if ($self->_should_mark_done($event)) {
        $self->done(1);
    }
}

sub _should_ignore {
    my ($self, $event) = @_;
    return if $self->type eq 'default';
    return if $self->type eq 'add_auth';
    return $self->ignore_session_events && $event->{type} == ZOO_SESSION_EVENT;
}

sub _should_mark_done {
    my ($self, $event) = @_;
    return if $self->type eq 'default';
    return if $event->{type} == ZOO_SESSION_EVENT;
    return 1;
}

1;
