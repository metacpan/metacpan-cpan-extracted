package LongTaskDistribution::Worker;
use Moose;
use namespace::autoclean;
use ZMQx::Class;
use AnyEvent;
use feature qw/ say /;

has 'priority' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'address' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'socket' => (
    is       => 'ro',
    isa      => 'ZMQx::Class::Socket',
    lazy     => 1,
    builder  => '_build_socket',
    init_arg => undef,
);

sub _build_socket {
    my ($self) = @_;
    return ZMQx::Class->socket( 'REQ', connect => $self->address );
}

sub start {
    my ($self) = @_;

    say "Starting Worker (PID $$) with priority " . $self->priority;

    my $w = $self->socket->anyevent_watcher(
        sub {
            while ( my $msg = $self->socket->receive ) {
                say "got task: " . join( '/', @$msg );
                $self->process_task($msg);
                $self->ready();
            }
        }
    );
    $self->ready();

    AnyEvent->condvar->recv;
}

sub ready {
    my ($self) = @_;
    say "worker sends ready msg. (PID $$)";
    $self->socket->send( $self->priority );
}

sub process_task {
    my ( $self, $task ) = @_;

    my $sleep = shift(@$task);
    say "Sleeping $sleep seconds.";
    sleep($sleep);
}

__PACKAGE__->meta->make_immutable;
1;
