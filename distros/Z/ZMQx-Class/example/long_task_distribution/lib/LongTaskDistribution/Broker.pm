package LongTaskDistribution::Broker;
use Moose;
use namespace::autoclean;
use ZMQx::Class;
use AnyEvent;
use feature qw/ say /;

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
    return ZMQx::Class->socket( 'ROUTER', bind => $self->address );
}

has 'workers' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub {
        return { 1 => [], 2 => [], 3 => [] };
    },
);

sub add_task {
    my ( $self, $tasks, $task_priority, $sleep ) = @_;
    push( @$tasks, { priority => $task_priority, sleep => $sleep } );
}

sub get_tasks {
    my ($self) = @_;

    my @tasks;

    for my $i ( 1 .. 2 ) {
        my $priority = int( rand(3) ) + 1;
        my $sleep    = int( rand(5) ) + 1;
        say "Got task. Priority  $priority. Sleep $sleep";
        $self->add_task( \@tasks, $priority, $sleep );
    }

    return \@tasks;
}

sub start {
    my ($self) = @_;

    say "Starting Broker (PID $$)";

    my $w = AnyEvent->timer(
        after    => 1,
        interval => 10,
        cb       => sub {
            my $tasks = $self->get_tasks();
            for my $task (@$tasks) {
                my $priority = $task->{priority};
                my $worker   = pop( @{ $self->workers->{$priority} } );
                if ( defined $worker ) {
                    say 'Send task. '
                        . 'Priority ' . $task->{priority} . '. '
                        . 'Sleep ' . $task->{sleep} . '. '
                        . "Worker $worker.";
                    $self->socket->send(
                        [ $worker, '', $task->{sleep} ] );
                }
            }
        },
    );

    my $w1 = $self->socket->anyevent_watcher(
        sub {
            while ( my $msg = $self->socket->receive ) {
                my $worker_id       = shift(@$msg);
                my $null            = shift(@$msg);
                my $worker_priority = shift(@$msg);
                warn "Unknown priority '$worker_priority'."
                  unless $worker_priority eq '1'
                  or $worker_priority eq '2'
                  or $worker_priority eq '3';
                say "worker $worker_id ($worker_priority) is ready.";
                unshift( @{ $self->workers->{$worker_priority} }, $worker_id );
            }
        }
    );

    AnyEvent->condvar->recv;
}

__PACKAGE__->meta->make_immutable;
1;
